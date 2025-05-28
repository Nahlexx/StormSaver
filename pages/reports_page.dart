import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/navigation_provider.dart';
import '../providers/expense_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String selectedDateRange = 'This Month';
  String selectedCategory = 'All Categories';
  String selectedStatus = 'All Status';
  String groupBy = 'Daily';
  String? selectedQuarter; // e.g., 'Q1 (Jan–Mar) 2024'
  String? selectedMonth; // e.g., 'Jan 2024'
  DateTime? customStartDate;
  DateTime? customEndDate;

  final List<String> dateRanges = [
    'This Month',
    'Last Month',
    'This Year',
    'Last Year',
    'Overall',
    'Custom',
  ];
  final List<String> statuses = ['All Status', 'Approved', 'Pending', 'Rejected'];
  final List<String> groupByOptions = ['Daily', 'Weekly', 'Monthly'];

  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // If the default or current value is not in dateRanges, reset it
    if (!dateRanges.contains(selectedDateRange)) {
      selectedDateRange = dateRanges.first;
    }
  }

  List<String> get quarterOptions {
    final now = DateTime.now();
    final List<String> quarters = [];
    const quarterLabels = [
      'Q1 (Jan–Mar)',
      'Q2 (Apr–Jun)',
      'Q3 (Jul–Sep)',
      'Q4 (Oct–Dec)',
    ];
    for (int year = now.year - 2; year <= now.year + 1; year++) {
      for (int q = 1; q <= 4; q++) {
        quarters.add('${quarterLabels[q - 1]} $year');
      }
    }
    return quarters.reversed.toList();
  }

  List<String> get monthOptions {
    final now = DateTime.now();
    final List<String> months = [];
    const monthLabels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    for (int year = now.year - 2; year <= now.year + 1; year++) {
      for (int m = 1; m <= 12; m++) {
        months.add('${monthLabels[m - 1]} $year');
      }
    }
    return months.reversed.toList();
  }

  void _setQuarterDates(String? quarter) {
    if (quarter == null) return;
    final match = RegExp(r'Q(\d) \((.*?)\) (\d{4})').firstMatch(quarter);
    if (match != null) {
      final q = int.parse(match.group(1)!);
      final year = int.parse(match.group(3)!);
      final startMonth = (q - 1) * 3 + 1;
      final start = DateTime(year, startMonth, 1);
      final end = DateTime(year, startMonth + 3, 0); // last day of quarter
      setState(() {
        selectedQuarter = quarter;
        customStartDate = start;
        customEndDate = end;
      });
    }
  }

  void _setMonthDates(String? month) {
    if (month == null) return;
    final match = RegExp(r'([A-Za-z]+) (\d{4})').firstMatch(month);
    if (match != null) {
      final m = DateTime.parse('2020-${{
        'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04', 'May': '05', 'Jun': '06',
        'Jul': '07', 'Aug': '08', 'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12',
      }}[match.group(1)]}-01').month;
      final year = int.parse(match.group(2)!);
      final start = DateTime(year, m, 1);
      final end = DateTime(year, m + 1, 0);
      setState(() {
        selectedMonth = month;
        customStartDate = start;
        customEndDate = end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigation = Provider.of<NavigationProvider>(context);
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final personalExpenses = provider.personalExpenses;
        final categories = _getCategories(personalExpenses);
        final filteredExpenses = _applyFilters(personalExpenses);
        final summary = _getSummary(filteredExpenses);
        final chartData = _getChartData(filteredExpenses);
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(navigation, personalExpenses, filteredExpenses, chartData, summary),
                const SizedBox(height: 24),
                _buildDateFilter(categories),
                const SizedBox(height: 24),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildExpenseChart(filteredExpenses),
                            const SizedBox(height: 24),
                            _buildCategoryBreakdown(filteredExpenses),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            _buildSummaryCard(filteredExpenses),
                            const SizedBox(height: 24),
                            _buildTopExpenses(filteredExpenses),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _getCategories(List expenses) {
    final set = <String>{};
    for (var e in expenses) {
      if (e.category.isNotEmpty) set.add(e.category);
    }
    final cats = set.toList()..sort();
    return ['All Categories', ...cats];
  }

  Map<String, dynamic> _getSummary(List expenses) {
    double total = 0, pending = 0, approved = 0, rejected = 0;
    for (var e in expenses) {
      total += e.amount.abs();
      if ((e.status ?? '').toLowerCase() == 'pending') pending += e.amount.abs();
      if ((e.status ?? '').toLowerCase() == 'approved') approved += e.amount.abs();
      if ((e.status ?? '').toLowerCase() == 'rejected') rejected += e.amount.abs();
    }
    return {
      'Total Expenses': total,
      'Pending Approvals': pending,
      'Approved': approved,
      'Rejected': rejected,
    };
  }

  List<List<dynamic>> _getChartData(List expenses) {
    if (selectedDateRange == 'This Year') {
      final int year = 2025;
      final Map<int, double> monthTotals = {for (var i = 1; i <= 12; i++) i: 0};
      for (var e in expenses) {
        if (e.date.year == year) {
          final month = e.date.month;
          monthTotals[month] = (monthTotals[month] ?? 0) + e.amount.abs();
        }
      }
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return [
        ['Month', 'Total Amount'],
        ...List.generate(12, (i) => [months[i], monthTotals[i + 1] ?? 0])
      ];
    } else {
      final Map<int, double> weekdayTotals = {for (var i = 1; i <= 7; i++) i: 0};
      for (var e in expenses) {
        final weekday = e.date.weekday;
        weekdayTotals[weekday] = (weekdayTotals[weekday] ?? 0) + e.amount.abs();
      }
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return [
        ['Day', 'Total Amount'],
        ...List.generate(7, (i) => [days[i], weekdayTotals[i + 1] ?? 0])
      ];
    }
  }

  Widget _buildHeader(NavigationProvider navigation, List allExpenses, List filteredExpenses, List<List<dynamic>> chartData, Map<String, dynamic> summary) {
    return Row(
      children: [
        Text(
          'Reports',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _showExportDialog(allExpenses, filteredExpenses, chartData, summary),
          icon: const Icon(Icons.download),
          label: const Text('Export Report'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _showExportDialog(List allExpenses, List filteredExpenses, List<List<dynamic>> chartData, Map<String, dynamic> summary) async {
    bool exportAllData = true;
    bool exportGraphData = false;
    bool exportSummary = false;
    bool exportGraphImage = false;
    String exportFormat = 'CSV';
    String fileName = 'Expense_Report';
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Export Report'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: exportAllData,
                    onChanged: (val) => setState(() => exportAllData = val!),
                    title: const Text('All Data'),
                  ),
                  CheckboxListTile(
                    value: exportGraphData,
                    onChanged: (val) => setState(() => exportGraphData = val!),
                    title: const Text('Graph Data'),
                  ),
                  CheckboxListTile(
                    value: exportSummary,
                    onChanged: (val) => setState(() => exportSummary = val!),
                    title: const Text('Summary'),
                  ),
                  CheckboxListTile(
                    value: exportGraphImage,
                    onChanged: (val) => setState(() => exportGraphImage = val!),
                    title: const Text('Graph Image (PNG)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'File Name',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: fileName),
                    onChanged: (val) => fileName = val,
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    value: exportFormat,
                    items: ['CSV']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => exportFormat = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (!exportAllData && !exportGraphData && !exportSummary && !exportGraphImage) return;
                  Navigator.pop(context);
                  _exportReportWithOptions(
                    exportAllData,
                    exportGraphData,
                    exportSummary,
                    exportGraphImage,
                    exportFormat,
                    allExpenses,
                    filteredExpenses,
                    chartData,
                    summary,
                    fileName,
                  );
                },
                child: const Text('Export'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportReportWithOptions(
    bool exportAllData,
    bool exportGraphData,
    bool exportSummary,
    bool exportGraphImage,
    String exportFormat,
    List allExpenses,
    List filteredExpenses,
    List<List<dynamic>> chartData,
    Map<String, dynamic> summary,
    String fileName,
  ) async {
    List<List<dynamic>> rows = [];
    if (exportAllData) {
      rows.add(['Date', 'Description', 'Category', 'Amount', 'Status']);
      rows.addAll(filteredExpenses.map((e) => [
        '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
        e.description,
        e.category,
        e.amount,
        e.status ?? '',
      ]));
    }
    if (exportGraphData) {
      if (rows.isNotEmpty) rows.add([]); // blank line between sections
      rows.addAll(chartData);
    }
    if (exportSummary) {
      if (rows.isNotEmpty) rows.add([]);
      rows.add(['Type', 'Amount']);
      rows.addAll(summary.entries.map((e) => [e.key, e.value]));
    }
    if (rows.isNotEmpty) {
      String csv = const ListToCsvConverter().convert(rows);
      final bytes = Uint8List.fromList(csv.codeUnits);
      await FileSaver.instance.saveFile(
        name: fileName.isNotEmpty ? fileName : 'Expense_Report',
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );
    }
    if (exportGraphImage) {
      try {
        RenderRepaintBoundary boundary = _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final pngBytes = byteData.buffer.asUint8List();
          await FileSaver.instance.saveFile(
            name: (fileName.isNotEmpty ? fileName : 'Expense_Report') + '_chart',
            bytes: pngBytes,
            ext: 'png',
            mimeType: MimeType.png,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to export chart image: $e')),
          );
        }
      }
    }
    if (mounted && (rows.isNotEmpty || exportGraphImage)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report exported successfully!')),
      );
    }
  }

  Widget _buildDateFilter(List<String> categories) {
    // Defensive: Use a local variable for dropdown value
    final dropdownValue = dateRanges.contains(selectedDateRange)
        ? selectedDateRange
        : dateRanges.first;
    // Determine allowed groupBy options
    List<String> allowedGroupBy = groupByOptions;
    if (dropdownValue == 'This Month' || dropdownValue == 'Last Month') {
      allowedGroupBy = ['Daily', 'Weekly'];
      if (!allowedGroupBy.contains(groupBy)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => groupBy = 'Daily');
        });
      }
    } else if (dropdownValue == 'Overall') {
      allowedGroupBy = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
      if (!allowedGroupBy.contains(groupBy)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => groupBy = 'Yearly');
        });
      }
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterDropdown('Date Range', dateRanges, dropdownValue, (val) async {
            if (val == 'Custom') {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                initialDateRange: (customStartDate != null && customEndDate != null)
                    ? DateTimeRange(start: customStartDate!, end: customEndDate!)
                    : null,
              );
              if (picked != null) {
                setState(() {
                  selectedDateRange = val;
                  customStartDate = picked.start;
                  customEndDate = picked.end;
                  selectedQuarter = null;
                  selectedMonth = null;
                });
              } else if (selectedDateRange != 'Custom') {
                setState(() {
                  selectedDateRange = selectedDateRange;
                });
              }
            } else if (val == 'Monthly') {
              setState(() {
                selectedDateRange = val;
                selectedMonth = monthOptions.first;
                _setMonthDates(selectedMonth);
                selectedQuarter = null;
              });
            } else {
              setState(() {
                selectedDateRange = val;
                customStartDate = null;
                customEndDate = null;
                selectedQuarter = null;
                selectedMonth = null;
              });
            }
          },
          displayText: dropdownValue == 'Custom' && customStartDate != null && customEndDate != null
              ? '${customStartDate!.month}/${customStartDate!.day}/${customStartDate!.year} - ${customEndDate!.month}/${customEndDate!.day}/${customEndDate!.year}'
              : dropdownValue,
          ),
          if (selectedDateRange == 'Monthly')
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _buildFilterDropdown('Month', monthOptions, selectedMonth ?? monthOptions.first, (val) {
                _setMonthDates(val);
              }),
            ),
          const SizedBox(width: 16),
          _buildFilterDropdown('Category', categories, selectedCategory, (val) {
            setState(() => selectedCategory = val);
          }),
          const SizedBox(width: 16),
          _buildFilterDropdown('Status', statuses, selectedStatus, (val) {
            setState(() => selectedStatus = val);
          }),
          const SizedBox(width: 16),
          // Group By dropdown with allowed options
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group By',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: groupBy,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    items: allowedGroupBy.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => groupBy = val);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, List<String> items, String? selected, ValueChanged<String> onChanged, {String? displayText}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: (val) => onChanged(val!),
              selectedItemBuilder: (context) {
                return items.map((item) {
                  if (label == 'Date Range' && item == 'Custom' && displayText != null && selected == 'Custom') {
                    return Text(displayText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500));
                  }
                  return Text(item, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500));
                }).toList();
              },
            ),
          ),
        ],
      ),
    );
  }

  List _applyFilters(List expenses) {
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;
    if (selectedDateRange == 'Last 30 Days') {
      startDate = now.subtract(const Duration(days: 30));
    } else if (selectedDateRange == 'This Month') {
      startDate = DateTime(now.year, now.month, 1);
    } else if (selectedDateRange == 'Last Month') {
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      startDate = lastMonth;
      endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
    } else if (selectedDateRange == 'This Year') {
      startDate = DateTime(2025, 1, 1);
      endDate = DateTime(2025, 12, 31, 23, 59, 59);
    } else if (selectedDateRange == 'Last Year') {
      startDate = DateTime(now.year - 1, 1, 1);
      endDate = DateTime(now.year - 1, 12, 31, 23, 59, 59);
    } else if (selectedDateRange == 'Yearly') {
      startDate = DateTime(now.year, 1, 1);
    } else if (selectedDateRange == 'Quarterly') {
      int currentQuarter = ((now.month - 1) ~/ 3) + 1;
      int startMonth = (currentQuarter - 1) * 3 + 1;
      startDate = DateTime(now.year, startMonth, 1);
    } else if (selectedDateRange == 'Overall') {
      startDate = DateTime(2000);
      endDate = now;
    } else if (selectedDateRange == 'Custom' && customStartDate != null && customEndDate != null) {
      startDate = customStartDate!;
      endDate = customEndDate!;
    } else {
      startDate = DateTime(2000); // fallback
    }
    return expenses.where((e) {
      final inDate = selectedDateRange == 'Overall' || (e.date.isAfter(startDate.subtract(const Duration(days: 1))) && e.date.isBefore(endDate.add(const Duration(days: 1))));
      final inCategory = selectedCategory == 'All Categories' || e.category == selectedCategory;
      final inStatus = selectedStatus == 'All Status' || (e.status ?? '').toLowerCase() == selectedStatus.toLowerCase();
      return inDate && inCategory && inStatus;
    }).toList();
  }

  // Utility to group expenses by groupBy
  List<Map<String, dynamic>> groupExpenses(List expenses, String groupBy) {
    Map<String, double> grouped = {};
    if (groupBy == 'Daily') {
      // Always include all days of the week
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (final day in days) {
        grouped[day] = 0;
      }
      for (var e in expenses) {
        final key = DateFormat('EEE').format(e.date); // e.g., Mon, Tue
        grouped[key] = (grouped[key] ?? 0) + e.amount.abs();
      }
      return days.map((d) => {'label': d, 'amount': grouped[d] ?? 0}).toList();
    } else if (groupBy == 'Weekly') {
      // Always include Week 1 to Week 4
      final weeks = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
      for (final week in weeks) {
        grouped[week] = 0;
      }
      for (var e in expenses) {
        final weekOfMonth = ((e.date.day - 1) ~/ 7) + 1;
        final key = 'Week $weekOfMonth';
        grouped[key] = (grouped[key] ?? 0) + e.amount.abs();
      }
      return weeks.map((w) => {'label': w, 'amount': grouped[w] ?? 0}).toList();
    } else if (groupBy == 'Monthly') {
      // Group by month name (Jan-Dec)
      return _groupByMonth(expenses);
    } else if (groupBy == 'Yearly') {
      // Group by year
      final years = <int>{};
      for (var e in expenses) {
        years.add(e.date.year);
      }
      for (final year in years) {
        grouped[year.toString()] = 0;
      }
      for (var e in expenses) {
        final key = e.date.year.toString();
        grouped[key] = (grouped[key] ?? 0) + e.amount.abs();
      }
      // Sort years ascending
      final sortedYears = years.toList()..sort();
      return sortedYears.map((y) => {'label': y.toString(), 'amount': grouped[y.toString()] ?? 0}).toList();
    } else {
      for (var e in expenses) {
        String key = DateFormat('yyyy-MM-dd').format(e.date);
        grouped[key] = (grouped[key] ?? 0) + e.amount.abs();
      }
      return grouped.entries.map((e) => {'label': e.key, 'amount': e.value}).toList();
    }
  }

  // Helper for monthly grouping (Jan-Dec, always all months)
  List<Map<String, dynamic>> _groupByMonth(List expenses) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    Map<String, double> grouped = {for (var m in months) m: 0};
    for (var e in expenses) {
      final key = DateFormat('MMM').format(e.date);
      grouped[key] = (grouped[key] ?? 0) + e.amount.abs();
    }
    return months.map((m) => {'label': m, 'amount': grouped[m] ?? 0}).toList();
  }

  int weekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    return ((date.difference(firstMonday).inDays) / 7).ceil() + 1;
  }

  Widget _buildExpenseChart(List expenses) {
    // Use groupBy for grouping
    final grouped = groupExpenses(expenses, groupBy);
    final spots = List.generate(grouped.length, (i) => FlSpot(i.toDouble(), grouped[i]['amount']));
    final maxY = ((spots.map((e) => e.y).fold<double>(0, (prev, y) => y > prev ? y : prev) / 10000).ceil() * 10000).clamp(10000, double.infinity);
    final labels = grouped.map((e) => e['label'] as String).toList();
    return RepaintBoundary(
      key: _chartKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expense Trend (Group By: $groupBy)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 10, getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: maxY / 10, getTitlesWidget: (value, meta) {
                      return Text('₱${value ~/ 1000}k', style: TextStyle(color: Colors.grey.shade600, fontSize: 12));
                    })),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(labels[idx], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        );
                      }
                      return const Text('');
                    })),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                    ),
                  ],
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY.toDouble(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(List expenses) {
    final Map<String, double> categoryTotals = {};
    for (var e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount.abs();
    }
    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.grey];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: List.generate(sortedCategories.length, (i) {
                        final entry = sortedCategories[i];
                        return PieChartSectionData(
                          value: entry.value,
                          color: colors[i % colors.length],
                          title: '',
                          radius: 80,
                        );
                      }),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SizedBox(
                    // Set a max height to prevent overflow
                    height: 180,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(sortedCategories.length, (i) {
                          final entry = sortedCategories[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: colors[i % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                ),
                                Text('₱${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List expenses) {
    // Use groupBy for grouping
    final grouped = groupExpenses(expenses, groupBy);
    final total = grouped.fold<double>(0, (sum, e) => sum + (e['amount'] as double));
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Text('Total: ₱${total.toStringAsFixed(0)} (Group By: $groupBy)', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...grouped.map((e) => Text('${e['label']}: ₱${e['amount'].toStringAsFixed(0)}')),
        ],
      ),
    );
  }

  Widget _buildTopExpenses(List expenses) {
    // Use groupBy for grouping
    final grouped = groupExpenses(expenses, groupBy);
    final top = grouped..sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top ${groupBy} Groups', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ...top.take(4).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e['label'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    Text('₱${e['amount'].toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
} 