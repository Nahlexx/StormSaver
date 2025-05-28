const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const cors = require('cors');

const PersonalExpense = mongoose.model('PersonalExpense', new mongoose.Schema({}, { strict: false, collection: 'PersonalExpense' }));

// Helper function to format personal expense data
const formatPersonalExpense = (expense) => ({
  id: expense._id ? expense._id.toString() : '',
  description: expense.Subject || expense.description || '',
  amount: expense.Amount != null ? Number(expense.Amount) : (expense.amount != null ? Number(expense.amount) : 0),
  date: expense.Date ? new Date(expense.Date).toISOString() : (expense.date ? expense.date.toISOString() : null),
  category: expense.Category || expense.category || '',
  notes: expense.Notes || expense.notes || '',
  teamId: expense.Team || expense.teamId || '',
  userId: expense.User || expense.userId || '',
  status: expense.Status || expense.status || '',
  receipt: expense.Receipt || expense.receipt || '',
});

// GET all personal expenses
router.get('/', async (req, res) => {
  try {
    const expenses = await PersonalExpense.find();
    const formattedExpenses = expenses.map(formatPersonalExpense);
    res.json({ expenses: formattedExpenses });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST new personal expense
router.post('/', async (req, res) => {
  console.log('Received POST /api/personal-expenses body:', req.body);
  try {
    const newExpense = new PersonalExpense(req.body);
    const savedExpense = await newExpense.save();
    res.status(201).json({
      success: true,
      message: 'Expense successfully added',
      expense: formatPersonalExpense(savedExpense)
    });
  } catch (err) {
    res.status(400).json({
      success: false,
      error: 'Failed to create expense',
      details: err.message
    });
  }
});

// PATCH approve expense
router.patch('/:id/approve', async (req, res) => {
  try {
    const updated = await PersonalExpense.findByIdAndUpdate(
      req.params.id,
      { $set: { Status: 'approved', status: 'approved' } },
      { new: true }
    );
    res.json({ success: true, expense: formatPersonalExpense(updated) });
  } catch (err) {
    res.status(400).json({ success: false, error: err.message });
  }
});

// PATCH reject expense
router.patch('/:id/reject', async (req, res) => {
  try {
    const updated = await PersonalExpense.findByIdAndUpdate(
      req.params.id,
      { $set: { Status: 'rejected', status: 'rejected' } },
      { new: true }
    );
    res.json({ success: true, expense: formatPersonalExpense(updated) });
  } catch (err) {
    res.status(400).json({ success: false, error: err.message });
  }
});

module.exports = router;