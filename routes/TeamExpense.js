const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// Define the TeamExpense schema with improved validation
const teamExpenseSchema = new mongoose.Schema({
  expenseName: { 
    type: String, 
    required: [true, 'Expense name is required'],
    trim: true
  },
  amount: { 
    type: Number, 
    required: [true, 'Amount is required'],
    min: [0, 'Amount cannot be negative']
  },
  date: { 
    type: Date, 
    required: [true, 'Date is required'],
    default: Date.now
  },
  category: { 
    type: String, 
    required: [true, 'Category is required'],
    trim: true
  },
  description: { 
    type: String,
    trim: true,
    default: ''
  },
  status: { 
    type: String, 
    enum: {
      values: ['pending', 'approved', 'rejected'],
      message: '{VALUE} is not a valid status'
    },
    default: 'pending'
  },
  teamId: { 
    type: String, 
    required: [true, 'Team ID is required'],
    trim: true
  },
  userId: { 
    type: String, 
    required: [true, 'User ID is required'],
    trim: true
  }
}, { 
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Add index for better query performance
teamExpenseSchema.index({ teamId: 1, date: -1 });
teamExpenseSchema.index({ userId: 1, date: -1 });

// Check if model exists before creating it
const TeamExpense = mongoose.models.TeamExpense || mongoose.model(
  'TeamExpense',
  new mongoose.Schema({}, { strict: false, collection: 'TeamExpense' })
);

// Helper function to format expense data
const formatExpense = (expense) => ({
  id: expense._id ? expense._id.toString() : '',
  description: expense.Subject || expense.description || '',
  amount: expense.Amount != null ? Number(expense.Amount) : (expense.amount != null ? Number(expense.amount) : 0),
  date: expense.Date ? new Date(expense.Date).toISOString() : (expense.date ? expense.date.toISOString() : null),
  category: expense.Category || expense.category || '',
  userId: expense.User || expense.userId || '',
  teamId: expense.Team || expense.teamId || '',
  status: expense.Status || expense.status || '',
  notes: expense.Notes || expense.notes || '',
  receipt: expense.Receipt || expense.receipt || '',
});

// GET all team expenses with pagination and filtering
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 10, status, category, startDate, endDate } = req.query;
    const query = {};

    // Add filters if provided
    if (status) query.status = status;
    if (category) query.category = category;
    if (startDate || endDate) {
      query.date = {};
      if (startDate) query.date.$gte = new Date(startDate);
      if (endDate) query.date.$lte = new Date(endDate);
    }

    const expenses = await TeamExpense.find(query)
      .sort({ date: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await TeamExpense.countDocuments(query);

    const formattedExpenses = expenses.map(formatExpense);

    res.json({
      expenses: formattedExpenses,
      totalPages: Math.ceil(count / limit),
      currentPage: page,
      totalExpenses: count
    });
  } catch (err) {
    res.status(500).json({ 
      error: 'Failed to fetch expenses',
      details: err.message 
    });
  }
});

// GET team expenses by team ID with pagination
router.get('/team/:teamId', async (req, res) => {
  try {
    const { page = 1, limit = 10, status, category } = req.query;
    const query = { teamId: req.params.teamId };

    if (status) query.status = status;
    if (category) query.category = category;

    const expenses = await TeamExpense.find(query)
      .sort({ date: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await TeamExpense.countDocuments(query);

    const formattedExpenses = expenses.map(formatExpense);

    res.json({
      expenses: formattedExpenses,
      totalPages: Math.ceil(count / limit),
      currentPage: page,
      totalExpenses: count
    });
  } catch (err) {
    res.status(500).json({ 
      error: 'Failed to fetch team expenses',
      details: err.message 
    });
  }
});

// POST new team expense
router.post('/', async (req, res) => {
  try {
    const newExpense = new TeamExpense(req.body);
    const savedExpense = await newExpense.save();
    res.status(201).json(formatExpense(savedExpense));
  } catch (err) {
    if (err.name === 'ValidationError') {
      return res.status(400).json({
        error: 'Validation Error',
        details: Object.values(err.errors).map(e => e.message)
      });
    }
    res.status(400).json({ 
      error: 'Failed to create expense',
      details: err.message 
    });
  }
});

// PUT update team expense
router.put('/:id', async (req, res) => {
  try {
    const updatedExpense = await TeamExpense.findByIdAndUpdate(
      req.params.id,
      req.body,
      { 
        new: true,
        runValidators: true
      }
    );
    
    if (!updatedExpense) {
      return res.status(404).json({ error: 'Expense not found' });
    }
    
    res.json(formatExpense(updatedExpense));
  } catch (err) {
    if (err.name === 'ValidationError') {
      return res.status(400).json({
        error: 'Validation Error',
        details: Object.values(err.errors).map(e => e.message)
      });
    }
    res.status(400).json({ 
      error: 'Failed to update expense',
      details: err.message 
    });
  }
});

// DELETE team expense
router.delete('/:id', async (req, res) => {
  try {
    const deletedExpense = await TeamExpense.findByIdAndDelete(req.params.id);
    if (!deletedExpense) {
      return res.status(404).json({ error: 'Expense not found' });
    }
    res.json({ 
      message: 'Expense deleted successfully',
      deletedExpense: formatExpense(deletedExpense)
    });
  } catch (err) {
    res.status(400).json({ 
      error: 'Failed to delete expense',
      details: err.message 
    });
  }
});

module.exports = router;