const express = require('express');
const router = express.Router();
const { check, validationResult } = require('express-validator');
const Expense = require('../models/Expense');
const auth = require('../middleware/auth');

// @route   GET api/expenses
// @desc    Get all expenses for a user
// @access  Private
router.get('/', auth, async (req, res) => {
    try {
        const expenses = await Expense.find({ user: req.user.id })
            .sort({ date: -1 });
        res.json(expenses);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/expenses
// @desc    Add new expense
// @access  Private
router.post('/', [
    auth,
    [
        check('title', 'Title is required').not().isEmpty(),
        check('amount', 'Amount is required').isNumeric(),
        check('category', 'Category is required').not().isEmpty()
    ]
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    try {
        const newExpense = new Expense({
            title: req.body.title,
            amount: req.body.amount,
            description: req.body.description,
            category: req.body.category,
            user: req.user.id,
            team: req.body.team,
            tags: req.body.tags,
            receipt: req.body.receipt
        });

        const expense = await newExpense.save();
        res.json(expense);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/expenses/:id
// @desc    Update expense
// @access  Private
router.put('/:id', auth, async (req, res) => {
    try {
        let expense = await Expense.findById(req.params.id);
        if (!expense) {
            return res.status(404).json({ msg: 'Expense not found' });
        }

        // Make sure user owns expense
        if (expense.user.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        expense = await Expense.findByIdAndUpdate(
            req.params.id,
            { $set: req.body },
            { new: true }
        );

        res.json(expense);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/expenses/:id
// @desc    Delete expense
// @access  Private
router.delete('/:id', auth, async (req, res) => {
    try {
        const expense = await Expense.findById(req.params.id);
        if (!expense) {
            return res.status(404).json({ msg: 'Expense not found' });
        }

        // Make sure user owns expense
        if (expense.user.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        await expense.remove();
        res.json({ msg: 'Expense removed' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router; 