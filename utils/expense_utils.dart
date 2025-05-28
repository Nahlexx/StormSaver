import 'package:intl/intl.dart';

List<Map<String, dynamic>> groupExpenses(List expenses, String groupBy) {
  Map<String, double> grouped = {};
  for (var e in expenses) {
    String key;
    if (groupBy == 'Daily') {
      key = DateFormat('yyyy-MM-dd').format(e.date);
    } else if (groupBy == 'Weekly') {
      // Get the week number
      final week = weekNumber(e.date);
      key = '${e.date.year}-W$week';
    } else if (groupBy == 'Monthly') {
      key = DateFormat('yyyy-MM').format(e.date);
    } else {
      key = DateFormat('yyyy-MM-dd').format(e.date);
    }
    grouped[key] = (grouped[key] ?? 0) + e.amount.abs();
  }
  // Convert to a list for charting
  return grouped.entries.map((e) => {'label': e.key, 'amount': e.value}).toList();
}

// Helper to get week number
int weekNumber(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  final daysOffset = firstDayOfYear.weekday - 1;
  final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
  return ((date.difference(firstMonday).inDays) / 7).ceil() + 1;
} 