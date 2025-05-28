import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../data/models/expense.dart';
import 'package:intl/intl.dart';
import 'expense_form_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  final bool isTeamExpenses;

  const ExpenseListScreen({
    Key? key,
    required this.isTeamExpenses,
  }) : super(key: key);

  @override
  _ExpenseListScreenState createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedSortBy = 'Date';
  bool _sortAscending = false;
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  
  // --- Quarter Picker ---
  String? _selectedQuarter; // e.g., 'Q2 2024'
  List<String> get _quarterOptions {
    final now = DateTime.now();
    final List<String> quarters = [];
    for (int year = now.year - 2; year <= now.year + 1; year++) {
      for (int q = 1; q <= 4; q++) {
        quarters.add('Q$q $year');
      }
    }
    return quarters.reversed.toList();
  }
  
  void _setQuarterDates(String? quarter) {
    if (quarter == null) return;
    final match = RegExp(r'Q(\d) (\d{4})').firstMatch(quarter);
    if (match != null) {
      final q = int.parse(match.group(1)!);
      final year = int.parse(match.group(2)!);
      final startMonth = (q - 1) * 3 + 1;
      final start = DateTime(year, startMonth, 1);
      final end = DateTime(year, startMonth + 3, 0); // last day of quarter
      setState(() {
        _selectedQuarter = quarter;
        _startDate = start;
        _endDate = end;
      });
    }
  }

  final List<String> _categories = [
    'All',
    'Food & Dining',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Housing',
    'Utilities',
    'Healthcare',
    'Travel',
    'Education',
    'Other'
  ];

  final List<String> _sortOptions = [
    'Date',
    'Amount',
    'Category',
    'Description'
  ];

  List<Expense> _filterExpenses(List<Expense> expenses) {
    return expenses.where((expense) {
      if (_searchQuery.isNotEmpty &&
          !expense.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedCategory != 'All' && expense.category != _selectedCategory) {
        return false;
      }
      if (_startDate != null && expense.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && expense.date.isAfter(_endDate!)) {
        return false;
      }
      if (_minAmount != null && expense.amount < _minAmount!) {
        return false;
      }
      if (_maxAmount != null && expense.amount > _maxAmount!) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Expense> _sortExpenses(List<Expense> expenses) {
    expenses.sort((a, b) {
      int comparison;
      switch (_selectedSortBy) {
        case 'Date':
          comparison = a.date.compareTo(b.date);
          break;
        case 'Amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'Category':
          comparison = a.category.compareTo(b.category);
          break;
        case 'Description':
          comparison = a.description.compareTo(b.description);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });
    return expenses;
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: [
        if (_selectedCategory != 'All')
          FilterChip(
            label: Text('Category: $_selectedCategory'),
            selected: true,
            onSelected: (bool selected) {
              setState(() {
                _selectedCategory = 'All';
              });
            },
            onDeleted: () {
              setState(() {
                _selectedCategory = 'All';
              });
            },
          ),
        if (_startDate != null)
          FilterChip(
            label: Text('From: ${DateFormat('MMM dd').format(_startDate!)}'),
            selected: true,
            onSelected: (bool selected) {
              setState(() {
                _startDate = null;
              });
            },
            onDeleted: () {
              setState(() {
                _startDate = null;
              });
            },
          ),
        if (_endDate != null)
          FilterChip(
            label: Text('To: ${DateFormat('MMM dd').format(_endDate!)}'),
            selected: true,
            onSelected: (bool selected) {
              setState(() {
                _endDate = null;
              });
            },
            onDeleted: () {
              setState(() {
                _endDate = null;
              });
            },
          ),
        if (_minAmount != null)
          FilterChip(
            label: Text('Min: \$${_minAmount!.toStringAsFixed(2)}'),
            selected: true,
            onSelected: (bool selected) {
              setState(() {
                _minAmount = null;
              });
            },
            onDeleted: () {
              setState(() {
                _minAmount = null;
              });
            },
          ),
        if (_maxAmount != null)
          FilterChip(
            label: Text('Max: \$${_maxAmount!.toStringAsFixed(2)}'),
            selected: true,
            onSelected: (bool selected) {
              setState(() {
                _maxAmount = null;
              });
            },
            onDeleted: () {
              setState(() {
                _maxAmount = null;
              });
            },
          ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Expenses'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Quarter Picker ---
              DropdownButtonFormField<String>(
                value: _selectedQuarter,
                decoration: const InputDecoration(labelText: 'Date Range (Quarter)'),
                items: _quarterOptions.map((String q) {
                  return DropdownMenuItem<String>(
                    value: q,
                    child: Text(q),
                  );
                }).toList(),
                onChanged: (String? value) {
                  _setQuarterDates(value);
                },
                isExpanded: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                            _selectedQuarter = null;
                          });
                        }
                      },
                      child: Text(_startDate == null
                          ? 'Start Date'
                          : DateFormat('MMM dd').format(_startDate!)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _endDate = date;
                            _selectedQuarter = null;
                          });
                        }
                      },
                      child: Text(_endDate == null
                          ? 'End Date'
                          : DateFormat('MMM dd').format(_endDate!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Min Amount',
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _minAmount = double.tryParse(value);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Max Amount',
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _maxAmount = double.tryParse(value);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedQuarter = null;
                _selectedCategory = 'All';
                _startDate = null;
                _endDate = null;
                _minAmount = null;
                _maxAmount = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTeamExpenses ? 'Team Expenses' : 'Personal Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedSortBy,
                    isExpanded: true,
                    items: _sortOptions.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text('Sort by: $option'),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedSortBy = value;
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_selectedCategory != 'All' ||
              _startDate != null ||
              _endDate != null ||
              _minAmount != null ||
              _maxAmount != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildFilterChips(),
            ),
          Expanded(
            child: Consumer<ExpenseProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final expenses = widget.isTeamExpenses
                    ? provider.teamExpenses
                    : provider.personalExpenses;

                final filteredExpenses = _filterExpenses(expenses);
                final sortedExpenses = _sortExpenses(filteredExpenses);

                if (sortedExpenses.isEmpty) {
                  return const Center(
                    child: Text('No expenses found'),
                  );
                }

                return ListView.builder(
                  itemCount: sortedExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = sortedExpenses[index];
                    return Dismissible(
                      key: Key(expense.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        provider.deleteExpense(
                          expense.id,
                          isTeam: widget.isTeamExpenses,
                        );
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryColor(expense.category),
                          child: Text(
                            expense.category[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(expense.description),
                        subtitle: Text(
                          '${expense.category} • ${DateFormat('MMM dd, yyyy').format(expense.date)}',
                        ),
                        trailing: Text(
                          NumberFormat.currency(symbol: '\$').format(expense.amount),
                          style: TextStyle(
                            color: expense.amount < 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExpenseFormScreen(
                                isTeamExpense: widget.isTeamExpenses,
                                expense: expense,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseFormScreen(
                isTeamExpense: widget.isTeamExpenses,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
        return Colors.orange;
      case 'transportation':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'housing':
        return Colors.brown;
      case 'utilities':
        return Colors.teal;
      case 'healthcare':
        return Colors.red;
      case 'travel':
        return Colors.green;
      case 'education':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
} 