import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/navigation_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../utils/expense_utils.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navigation = Provider.of<NavigationProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Text(
                'Hello Josh! 👋',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Search bar
              Container(
                width: 250,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.shade100,
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Dashboard content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Only show Personal Expenses card at the top
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person, color: Colors.green, size: 32),
                              const SizedBox(height: 8),
                              Text('Personal Expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Consumer<ExpenseProvider>(
                                builder: (context, provider, child) {
                                  final total = provider.personalExpenses.fold<double>(0, (sum, e) => sum + e.amount.abs());
                                  return Text(
                                    _formatPeso(total),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Pending Tasks section
                const Text(
                  'Pending Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Task cards
                
                const SizedBox(height: 24),
                // Recent Expenses section
                Row(
                  children: [
                    const Text(
                      'Recent Expenses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '01 - 25 March, 2024',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    // Search bar
                    Container(
                      width: 200,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.grey.shade100,
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.search, color: Colors.grey, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Sort dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: const [
                          Text('Sort by: Newest'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_drop_down, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Expenses table
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Consumer<ExpenseProvider>(
                    builder: (context, provider, child) {
                      final expenses = provider.personalExpenses;
                      print('DEBUG: personalExpenses = ' + expenses.toString());
                      if (provider.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final recent = List.of(expenses)
                        ..sort((a, b) => b.date.compareTo(a.date));
                      final latest = recent.take(5).toList();
                      if (latest.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Text('No recent expenses', style: TextStyle(color: Colors.grey.shade600)),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          // Table header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Description',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Employee',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Category',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Amount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ...latest.map((e) => _ExpenseItem(
                                subject: (e.description.isNotEmpty) ? e.description : '(No Description)',
                                employee: (e.userId != null && e.userId!.isNotEmpty) ? e.userId! : '-',
                                category: (e.category.isNotEmpty) ? e.category : '(No Category)',
                                amount: _formatPeso(e.amount),
                                categoryColor: Colors.blue,
                                isPositive: e.amount > 0,
                              )),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Financial Overview section
                const Text(
                  'Financial Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: _buildExpenseChart(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
                  _formatPeso(value.toInt() * 1000),
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
                  _formatPeso(spot.y.toInt() * 1000),
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Color color;
  final Color iconColor;
  final IconData icon;
  final String title;
  final int count;
  final bool isLast;

  const _TaskCard({
    Key? key,
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.count,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: isLast ? 0 : 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: count > 0 ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatPeso(num amount, {int decimalDigits = 2}) {
  return '₱${amount.toStringAsFixed(decimalDigits).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
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
    // Try to parse the amount to a number for formatting
    String displayAmount = amount;
    final num? parsed = num.tryParse(amount.replaceAll(',', '').replaceAll('₱', '').replaceAll('+', '').replaceAll('-', ''));
    if (parsed != null) {
      displayAmount = (amount.startsWith('-') ? '-' : amount.startsWith('+') ? '+' : '') + _formatPeso(parsed);
    }
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
                  displayAmount,
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

class _PaginationItem extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final bool isActive;
  final double? iconSize;

  const _PaginationItem({
    Key? key,
    this.text,
    this.icon,
    this.isActive = false,
    this.iconSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: icon != null
            ? Icon(
                icon,
                size: iconSize ?? 16,
                color: Colors.grey.shade600,
              )
            : Text(
                text!,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
      ),
    );
  }
} 