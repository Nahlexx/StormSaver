import 'package:flutter/material.dart';

class RecentExpensesTable extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;

  const RecentExpensesTable({Key? key, required this.expenses}) : super(key: key);

  Color _categoryColor(String category) {
    switch (category) {
      case 'Marketing':
        return Colors.blue.shade100;
      case 'Sales':
        return Colors.pink.shade100;
      case 'Development':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _amountColor(num amount) {
    return amount > 0 ? Colors.green : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  "Recent Expenses",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: "Newest",
                  items: const [
                    DropdownMenuItem(value: "Newest", child: Text("Sort by: Newest")),
                    DropdownMenuItem(value: "Oldest", child: Text("Sort by: Oldest")),
                  ],
                  onChanged: (v) {},
                ),
              ],
            ),
          ),
          // Table
          DataTable(
            columns: const [
              DataColumn(label: Text("Subject")),
              DataColumn(label: Text("Employee")),
              DataColumn(label: Text("Category")),
              DataColumn(label: Text("Amount")),
            ],
            rows: expenses.map((expense) {
              return DataRow(
                cells: [
                  DataCell(Text(expense['subject'] ?? '')),
                  DataCell(Text(expense['employee'] ?? '')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _categoryColor(expense['category']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        expense['category'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      "${expense['amount'] > 0 ? '+' : ''}${expense['amount'].toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}",
                      style: TextStyle(
                        color: _amountColor(expense['amount']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          // Pagination (simple)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("Showing data 1 to 8 of 2548 entries"),
                const SizedBox(width: 16),
                IconButton(icon: Icon(Icons.chevron_left), onPressed: () {}),
                Text("1"),
                IconButton(icon: Icon(Icons.chevron_right), onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 