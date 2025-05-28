const express = require('express');
const router = express.Router();
const { check, validationResult } = require('express-validator');
const Team = require('../models/Team');
const User = require('../models/User');
const auth = require('../middleware/auth');
const TeamExpense = require('../models/TeamExpense');

// @route   GET api/teams
// @desc    Get all teams for a user
// @access  Private
router.get('/', auth, async (req, res) => {
    try {
        const teams = await Team.find({
            'members.user': req.user.id
        }).populate('members.user', 'name email');
        res.json(teams);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/teams
// @desc    Create a team
// @access  Private
router.post('/', [
    auth,
    [
        check('name', 'Name is required').not().isEmpty()
    ]
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    try {
        const newTeam = new Team({
            name: req.body.name,
            description: req.body.description,
            createdBy: req.user.id,
            members: [{ user: req.user.id, role: 'admin' }],
            budget: req.body.budget || 0
        });

        const team = await newTeam.save();

        // Add team to user's teams array
        await User.findByIdAndUpdate(
            req.user.id,
            { $push: { teams: team._id } }
        );

        res.json(team);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/teams/:id
// @desc    Update team
// @access  Private
router.put('/:id', auth, async (req, res) => {
    try {
        let team = await Team.findById(req.params.id);
        if (!team) {
            return res.status(404).json({ msg: 'Team not found' });
        }

        // Check if user is team admin
        const isAdmin = team.members.some(
            member => member.user.toString() === req.user.id && member.role === 'admin'
        );

        if (!isAdmin) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        team = await Team.findByIdAndUpdate(
            req.params.id,
            { $set: req.body },
            { new: true }
        );

        res.json(team);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/teams/:id/members
// @desc    Add member to team
// @access  Private
router.post('/:id/members', [
    auth,
    [
        check('email', 'Please include a valid email').isEmail()
    ]
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    try {
        const team = await Team.findById(req.params.id);
        if (!team) {
            return res.status(404).json({ msg: 'Team not found' });
        }

        // Check if user is team admin
        const isAdmin = team.members.some(
            member => member.user.toString() === req.user.id && member.role === 'admin'
        );

        if (!isAdmin) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        const user = await User.findOne({ email: req.body.email });
        if (!user) {
            return res.status(404).json({ msg: 'User not found' });
        }

        // Check if user is already a member
        if (team.members.some(member => member.user.toString() === user._id.toString())) {
            return res.status(400).json({ msg: 'User is already a member' });
        }

        team.members.push({ user: user._id, role: 'member' });
        await team.save();

        // Add team to user's teams array
        await User.findByIdAndUpdate(
            user._id,
            { $push: { teams: team._id } }
        );

        res.json(team);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/teams/:id/members/:userId
// @desc    Remove member from team
// @access  Private
router.delete('/:id/members/:userId', auth, async (req, res) => {
    try {
        const team = await Team.findById(req.params.id);
        if (!team) {
            return res.status(404).json({ msg: 'Team not found' });
        }

        // Check if user is team admin
        const isAdmin = team.members.some(
            member => member.user.toString() === req.user.id && member.role === 'admin'
        );

        if (!isAdmin) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        // Remove member from team
        team.members = team.members.filter(
            member => member.user.toString() !== req.params.userId
        );

        await team.save();

        // Remove team from user's teams array
        await User.findByIdAndUpdate(
            req.params.userId,
            { $pull: { teams: team._id } }
        );

        res.json(team);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

router.get('/team-expenses', async (req, res) => {
    const teamExpenses = await TeamExpense.find();
    const mapped = teamExpenses.map(e => ({
        id: e._id ? String(e._id) : "",
        description: e.description || "",
        amount: e.amount || 0,
        date: e.date || new Date(),
        category: e.category || "",
        notes: e.notes || "",
        teamId: e.teamId || "",
        userId: e.userId || ""
    }));
    res.json({ expenses: mapped }); // <-- THIS IS CORRECT!// <-- THIS IS THE FIX!
});

module.exports = router; 