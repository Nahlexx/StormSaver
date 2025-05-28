const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const mongoose = require('mongoose');

// Load environment variables
dotenv.config();

// Connect to MongoDB
connectDB();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Test endpoint to verify MongoDB connection
app.get('/api/test', async (req, res) => {
  try {
    const db = mongoose.connection;
    if (db.readyState === 1) {
      res.json({ 
        status: 'success', 
        message: 'MongoDB is connected',
        details: {
          host: db.host,
          name: db.name,
          port: db.port
        }
      });
    } else {
      res.status(500).json({ 
        status: 'error', 
        message: 'MongoDB is not connected',
        state: db.readyState
      });
    }
  } catch (error) {
    res.status(500).json({ 
      status: 'error', 
      message: error.message 
    });
  }
});

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/expenses', require('./routes/expenses'));
app.use('/api/teams', require('./routes/teams'));
app.use('/api/personal-expenses', require('./routes/personalExpense'));
app.use('/api/team-expenses', require('./routes/TeamExpense'));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`)); 