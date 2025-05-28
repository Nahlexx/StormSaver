import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../data/models/expense.dart';
import '../data/services/expense_service.dart';
import '../components/backend_status_indicator.dart';
import '../components/recent_expenses_table.dart';
import '../utils/expense_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _formatCurrency(num amount, {int decimalDigits = 2}) {
  return '₱${amount.toStringAsFixed(decimalDigits).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ExpenseService _expenseService = ExpenseService();
  String? _connectionStatus;
  bool _isTestingConnection = false;
  String _selectedTimeRange = 'This Month';

  // Add a list of accent colors for category bars
  final List<Color> _categoryColors = [
    Color(0xFF1A73E8), // blue
    Color(0xFFFF9800), // orange
    Color(0xFF4CAF50), // green
    Color(0xFF9C27B0), // purple
    Color(0xFF00B8D4), // teal
    Color(0xFFEF5350), // red
    Color(0xFF607D8B), // blue-grey
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    // Load budget on dashboard init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadBudget();
    });
  }

  Future<void> _loadData() async {
    await _testConnection();
    if (mounted) {
      context.read<ExpenseProvider>().loadPersonalExpenses();
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    try {
      final result = await _expenseService.testConnection();
      setState(() {
        _connectionStatus = 'Connected to MongoDB\nHost: ${result['details']['host']}\nDatabase: ${result['details']['name']}';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error connecting to MongoDB: $e';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<Expense> expenses, {bool compact = false}) {
    final categoryTotals = <String, double>{};
    for (var expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.10),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: compact ? const EdgeInsets.all(12) : const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: Color(0xFF1A73E8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Category Breakdown',
                style: TextStyle(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 16),
          ...List.from(sortedCategories.take(6)).asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final percent = total > 0 ? (cat.value / total * 100) : 0;
            final color = _categoryColors[i % _categoryColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cat.key, style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(_formatCurrency(cat.value), style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: color)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percent / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress(List<Expense> expenses, {bool compact = false}) {
    final provider = context.watch<ExpenseProvider>();
    final monthlyBudget = provider.monthlyBudget;
    final monthlyTotal = expenses
        .where((e) => e.date.month == DateTime.now().month)
        .fold(0.0, (sum, e) => sum + e.amount);
    final progress = monthlyTotal / monthlyBudget;
    final overBudget = progress > 1.0;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.10),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: compact ? const EdgeInsets.all(12) : const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: Color(0xFFEF5350),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Monthly Budget',
                style: TextStyle(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              Spacer(),
              InkWell(
                onTap: () => _showEditBudgetDialog(provider),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.edit, color: Color(0xFF1A73E8), size: 20),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                overBudget ? Colors.red : Colors.green,
              ),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spent: ${_formatCurrency(monthlyTotal)}', style: TextStyle(fontWeight: FontWeight.w500)),
              Text('Budget: ${_formatCurrency(monthlyBudget)}', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          if (overBudget)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Over budget by ${_formatCurrency(monthlyTotal - monthlyBudget)}',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentExpenses(List<Expense> expenses, {bool compact = false}) {
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.10),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: compact ? const EdgeInsets.all(12) : const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Recent Expenses',
                style: TextStyle(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 16),
          ...sortedExpenses.take(6).map((expense) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.transparent,
                ),
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    expense.description.isNotEmpty ? expense.description : '(No Description)',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: compact ? 14 : 15),
                  ),
                  subtitle: Text(
                    expense.category.isNotEmpty ? expense.category : '(No Category)',
                    style: TextStyle(fontSize: compact ? 12 : 13, color: Colors.grey[600]),
                  ),
                  trailing: Text(
                    _formatCurrency(expense.amount.abs()),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: compact ? 14 : 15),
                  ),
                  hoverColor: Colors.grey.withOpacity(0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExpenseTrendsChart(List<Expense> expenses) {
    final now = DateTime.now();
    final startDate = _selectedTimeRange == 'This Month' 
        ? DateTime(now.year, now.month, 1)
        : DateTime(now.year, now.month - 1, 1);
    
    final filteredExpenses = expenses.where((e) => e.date.isAfter(startDate)).toList();
    final dailyTotals = <DateTime, double>{};
    
    for (var expense in filteredExpenses) {
      final date = DateTime(expense.date.year, expense.date.month, expense.date.day);
      dailyTotals[date] = (dailyTotals[date] ?? 0) + expense.amount;
    }

    final spots = dailyTotals.entries.map((e) => 
      FlSpot(e.key.millisecondsSinceEpoch.toDouble(), e.value)
    ).toList()..sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatCurrency(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Text(
                  DateFormat('MM/dd').format(date),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          const BackendStatusIndicator(),
          if (_isTestingConnection)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          if (expenseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final personalExpenses = expenseProvider.personalExpenses;
          final totalExpenses = personalExpenses.fold(0.0, (sum, e) => sum + e.amount);
          final pendingCount = personalExpenses.where((e) => (e.status ?? '').toLowerCase() == 'pending').length;
          final approvedCount = personalExpenses.where((e) => (e.status ?? '').toLowerCase() == 'approved').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            physics: ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact summary cards row
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total Expenses',
                        value: _formatCurrency(totalExpenses),
                        icon: Icons.account_balance_wallet,
                        iconBg: const Color(0xFFE3F0FF),
                        iconColor: const Color(0xFF1A73E8),
                        valueColor: const Color(0xFF1A73E8),
                        onTap: null,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Pending Approvals',
                        value: pendingCount.toString(),
                        icon: Icons.event_note,
                        iconBg: const Color(0xFFFFF4E3),
                        iconColor: const Color(0xFFFF9800),
                        valueColor: const Color(0xFFFF9800),
                        onTap: null,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Approved Expenses',
                        value: approvedCount.toString(),
                        icon: Icons.check_circle_outline,
                        iconBg: const Color(0xFFE3FCE7),
                        iconColor: const Color(0xFF4CAF50),
                        valueColor: const Color(0xFF4CAF50),
                        onTap: null,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // --- NEW: Info cards row ---
                _InfoCardsRow(expenses: personalExpenses, allExpenses: personalExpenses),
                const SizedBox(height: 8),
                // 3-column grid: Category Breakdown, Monthly Budget, Recent Expenses
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: _buildCategoryBreakdown(personalExpenses, compact: true),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildBudgetProgress(personalExpenses, compact: true),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: _buildRecentExpenses(personalExpenses, compact: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditBudgetDialog(ExpenseProvider provider) {
    final budgetController = TextEditingController(text: provider.monthlyBudget.toStringAsFixed(2));
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Monthly Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'New Budget Amount'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (passwordController.text == 'admin123') {
                  final newBudget = double.tryParse(budgetController.text);
                  if (newBudget != null && newBudget > 0) {
                    await provider.setMonthlyBudget(newBudget);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Budget updated!'), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid budget amount.'), backgroundColor: Colors.red),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect password.'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class TeamExpenseBreakdownPage extends StatelessWidget {
  final List<Expense> teamExpenses;
  final String title;

  const TeamExpenseBreakdownPage({Key? key, required this.teamExpenses, this.title = 'Team Expense Breakdown'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        itemCount: teamExpenses.length,
        itemBuilder: (context, index) {
          final expense = teamExpenses[index];
          return ListTile(
            title: Text(expense.description.isNotEmpty ? expense.description : '(No Description)'),
            subtitle: Text(
              '${expense.category.isNotEmpty ? expense.category : '(No Category)'} • ${expense.date.toLocal()}'),
            trailing: Text(
              '\$${expense.amount.abs().toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  final String subject;
  final String employee;
  final String category;
  final String amount;
  final Color categoryColor;
  final bool isPositive;

  const _ExpenseItem({
    Key? key,
    required this.subject,
    required this.employee,
    required this.category,
    required this.amount,
    this.categoryColor = Colors.blue,
    this.isPositive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  employee,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  amount,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.black,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

Widget _buildExpenseChart() {
  return LineChart(
    LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatCurrency(value.toInt() * 1000),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
              if (value.toInt() < months.length) {
                return Text(
                  months[value.toInt()],
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 200),
            FlSpot(1, 150),
            FlSpot(2, 300),
            FlSpot(3, 250),
            FlSpot(4, 400),
            FlSpot(5, 350),
          ],
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blue,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                _formatCurrency(spot.y.toInt() * 1000),
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
      ),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color valueColor;
  final VoidCallback? onTap;
  final bool compact;

  const _SummaryCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.valueColor,
    this.onTap,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: compact ? const EdgeInsets.all(7) : const EdgeInsets.all(10),
            child: Icon(icon, color: iconColor, size: compact ? 22 : 28),
          ),
          SizedBox(width: compact ? 10 : 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: compact ? 13 : 15, color: Colors.grey[700])),
                SizedBox(height: compact ? 4 : 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 17 : 22,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- NEW: InfoCardsRow widget ---
class _InfoCardsRow extends StatelessWidget {
  final List<Expense> expenses;
  final List<Expense> allExpenses;
  const _InfoCardsRow({required this.expenses, required this.allExpenses});

  @override
  Widget build(BuildContext context) {
    // Top Spending Category (this month)
    final now = DateTime.now();
    final thisMonth = expenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    final Map<String, double> catTotals = {};
    for (var e in thisMonth) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }
    final topCat = catTotals.entries.isNotEmpty
        ? catTotals.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    // Expense Trend (this month vs last month)
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastMonthExpenses = expenses.where((e) => e.date.year == lastMonth.year && e.date.month == lastMonth.month).toList();
    final thisMonthTotal = thisMonth.fold(0.0, (sum, e) => sum + e.amount);
    final lastMonthTotal = lastMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    double trend = 0;
    if (lastMonthTotal > 0) {
      trend = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
    }

    // Quick Stats
    final uniqueCategories = thisMonth.map((e) => e.category).toSet().length;
    final avgExpense = thisMonth.isNotEmpty ? thisMonth.fold(0.0, (sum, e) => sum + e.amount) / thisMonth.length : 0;
    final largestExpense = thisMonth.isNotEmpty ? thisMonth.reduce((a, b) => a.amount > b.amount ? a : b) : null;

    return Row(
      children: [
        // Top Category
        Expanded(
          child: _InfoCard(
            icon: Icons.star,
            iconColor: Colors.amber.shade700,
            title: 'Top Category',
            value: topCat != null ? topCat.key : 'N/A',
            subtitle: topCat != null ? '₱${topCat.value.toStringAsFixed(2)}' : '',
            bgColor: Colors.amber.shade50,
          ),
        ),
        const SizedBox(width: 12),
        // Expense Trend
        Expanded(
          child: _InfoCard(
            icon: trend >= 0 ? Icons.trending_up : Icons.trending_down,
            iconColor: trend >= 0 ? Colors.green : Colors.red,
            title: 'Expense Trend',
            value: lastMonthTotal == 0 ? 'N/A' : '${trend.abs().toStringAsFixed(1)}%',
            subtitle: lastMonthTotal == 0
                ? 'No data for last month'
                : (trend >= 0 ? 'Up from last month' : 'Down from last month'),
            bgColor: trend >= 0 ? Colors.green.shade50 : Colors.red.shade50,
          ),
        ),
        const SizedBox(width: 12),
        // Quick Stats
        Expanded(
          child: _InfoCard(
            icon: Icons.insights,
            iconColor: Colors.blue,
            title: 'Quick Stats',
            value: 'Avg: ₱${avgExpense.toStringAsFixed(0)}',
            subtitle: 'Largest: ${largestExpense != null ? '₱${largestExpense.amount.toStringAsFixed(0)}' : 'N/A'}\n${uniqueCategories} categories',
            bgColor: Colors.blue.shade50,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final Color bgColor;
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.bgColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(7),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 