import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/navigation_provider.dart';
import '../providers/expense_provider.dart';
import '../data/models/expense.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../utils/expense_utils.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  int _currentPage = 1;
  static const int _rowsPerPage = 10;

  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All Status';
  bool _sortRecentFirst = true;
  bool _isAddingExpense = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final allExpenses = provider.personalExpenses;
        final categories = [
          'All Categories',
          ...{
            for (final e in allExpenses)
              if (e.category.isNotEmpty) e.category
          }
        ];
        final statuses = ['All Status', 'Approved', 'Pending', 'Rejected'];
        // Filtering
        List<Expense> filtered = allExpenses.where((e) {
          final catOk = _selectedCategory == 'All Categories' || e.category == _selectedCategory;
          final statusOk = _selectedStatus == 'All Status' || (e.status ?? '').toLowerCase() == _selectedStatus.toLowerCase();
          return catOk && statusOk;
        }).toList();
        // Sorting
        filtered.sort((a, b) => _sortRecentFirst ? b.date.compareTo(a.date) : a.date.compareTo(b.date));
        final totalPages = (filtered.length / _rowsPerPage).ceil().clamp(1, double.infinity).toInt();
        final start = (_currentPage - 1) * _rowsPerPage;
        final end = (_currentPage * _rowsPerPage).clamp(0, filtered.length);
        final pageExpenses = filtered.sublist(start, end);
        // Make the page fit in one window (no vertical scroll)
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final availableWidth = constraints.maxWidth;
            // Responsive font size based on width
            double baseFont = availableWidth > 1200 ? 15 : availableWidth > 900 ? 14 : 13;
            double headingFont = baseFont + 1;
            double smallFont = baseFont - 2;
            return Padding(
              padding: const EdgeInsets.all(32), // Small gap from all sides
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long, color: Color(0xFF1A73E8), size: 22),
                              const SizedBox(width: 10),
                              Text('Expenses', style: TextStyle(fontSize: headingFont, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showAddExpenseDialog(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text('Add Expense', style: TextStyle(fontSize: baseFont)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A73E8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildFilterBar(categories, statuses, fontSize: baseFont, smallFont: smallFont),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _buildDataTable(pageExpenses, fontSize: baseFont, headingFont: headingFont, smallFont: smallFont),
                      ),
                      const SizedBox(height: 10),
                      _buildPagination(filtered.length, start, end, totalPages, fontSize: smallFont),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExpensesList(List<Expense> pageExpenses, int totalCount, int start, int end, int totalPages) {
    if (totalCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('No expenses found.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }
    // Prepare categories and statuses for the filter bar
    final categories = [
      'All Categories',
      ...{
        for (final e in pageExpenses)
          if (e.category.isNotEmpty) e.category
      }
    ];
    final statuses = ['All Status', 'Approved', 'Pending', 'Rejected'];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FAFF), Color(0xFFF3F6FB), Color(0xFFF7FAFF)],
        ),
      ),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.receipt_long, color: Color(0xFF1A73E8), size: 20),
                      SizedBox(width: 6),
                      Text('All Personal Expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddExpenseDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Expense', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
                      shadowColor: Colors.blueAccent.withOpacity(0.18),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildFilterBar(categories, statuses),
              const SizedBox(height: 14),
              Divider(height: 1, thickness: 1, color: Color(0xFFF0F1F6)),
              const SizedBox(height: 10),
              Expanded(
                child: _buildDataTable(pageExpenses),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, thickness: 1, color: Color(0xFFF0F1F6)),
              const SizedBox(height: 6),
              _buildPagination(totalCount, start, end, totalPages),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable(List<Expense> pageExpenses, {double fontSize = 14, double headingFont = 15, double smallFont = 12}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DataTable(
        columnSpacing: 18,
        dataRowMinHeight: fontSize + 16,
        dataRowMaxHeight: fontSize + 22,
        headingRowHeight: headingFont + 16,
        horizontalMargin: 8,
        headingRowColor: MaterialStateProperty.all(Color(0xFFF5F7FA)),
        border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200)),
        columns: [
          DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: headingFont, fontFamily: 'Roboto'))),
          DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: headingFont, fontFamily: 'Roboto'))),
          DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: headingFont, fontFamily: 'Roboto'))),
          DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: headingFont, fontFamily: 'Roboto'))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: headingFont, fontFamily: 'Roboto'))),
        ],
        rows: List.generate(pageExpenses.length, (index) {
          final expense = pageExpenses[index];
          final isEven = index % 2 == 0;
          return DataRow(
            color: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.hovered)) {
                  return Colors.blue.withOpacity(0.08);
                }
                return isEven ? const Color(0xFFF8FAFC) : Colors.white;
              },
            ),
            cells: [
              DataCell(
                Text(
                  expense.description.isNotEmpty ? expense.description : '(No Description)',
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: fontSize, fontFamily: 'Roboto'),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              DataCell(Row(
                children: [
                  Icon(_getCategoryIcon(expense.category), color: _getCategoryColor(expense.category), size: fontSize + 2),
                  SizedBox(width: 6),
                  Text(expense.category, style: TextStyle(color: Colors.grey.shade800, fontSize: fontSize, fontFamily: 'Roboto')),
                ],
              )),
              DataCell(Text(_formatDate(expense.date), style: TextStyle(color: Colors.black87, fontSize: fontSize, fontFamily: 'Roboto'))),
              DataCell(Text(_formatCurrency(expense.amount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, fontFamily: 'Roboto'))),
              DataCell(Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(expense.status).withOpacity(0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      expense.status?.toLowerCase() == 'approved' ? Icons.check_circle :
                      expense.status?.toLowerCase() == 'pending' ? Icons.hourglass_top :
                      expense.status?.toLowerCase() == 'rejected' ? Icons.cancel : Icons.info,
                      color: _getStatusColor(expense.status),
                      size: fontSize,
                    ),
                    SizedBox(width: 4),
                    Text(
                      expense.status ?? 'N/A',
                      style: TextStyle(
                        color: _getStatusColor(expense.status),
                        fontWeight: FontWeight.w600,
                        fontSize: fontSize,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              )),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPagination(int totalCount, int start, int end, int totalPages, {double fontSize = 12}) {
    List<Widget> pageButtons = [];
    int window = 2;
    for (int i = 1; i <= totalPages; i++) {
      // Always show first, last, current, and window around current
      if (i == 1 || i == totalPages || (i - _currentPage).abs() <= window) {
        pageButtons.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: i == _currentPage ? const Color(0xFF1A73E8) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: i == _currentPage
                    ? [BoxShadow(color: Colors.blue.withOpacity(0.13), blurRadius: 8, offset: Offset(0, 2))]
                    : [],
                border: Border.all(color: i == _currentPage ? const Color(0xFF1A73E8) : Colors.grey.shade200, width: 1.2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _currentPage = i),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                    child: Text('$i',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize + 1,
                        color: i == _currentPage ? Colors.white : Colors.black87,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      } else if (
        // Show '...' if the previous button is not adjacent
        (i == 2 && _currentPage - window > 2) ||
        (i == totalPages - 1 && _currentPage + window < totalPages - 1) ||
        (i > 1 && i < totalPages &&
          ((i == _currentPage - window - 1) || (i == _currentPage + window + 1)))
      ) {
        if (pageButtons.isEmpty || pageButtons.last is! Text) {
          pageButtons.add(Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(fontSize: fontSize, color: Colors.grey)),
          ));
        }
      }
    }
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.07), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing ${start + 1} to $end of $totalCount entries', style: TextStyle(color: Colors.grey, fontSize: fontSize, fontFamily: 'Roboto')),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                color: _currentPage > 1 ? Colors.black87 : Colors.grey.shade400,
                tooltip: 'Previous',
                iconSize: fontSize + 4,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: fontSize + 12, minHeight: fontSize + 12),
              ),
              ...pageButtons,
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                color: _currentPage < totalPages ? Colors.black87 : Colors.grey.shade400,
                tooltip: 'Next',
                iconSize: fontSize + 4,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: fontSize + 12, minHeight: fontSize + 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(List<String> categories, List<String> statuses, {double fontSize = 14, double smallFont = 12}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: const Color(0xFFF3F6FB),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            // Category Dropdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category', style: TextStyle(fontSize: smallFont, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down),
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: TextStyle(fontSize: fontSize)))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val!;
                          _currentPage = 1;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            // Status Dropdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status', style: TextStyle(fontSize: smallFont, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down),
                      items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(fontSize: fontSize)))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedStatus = val!;
                          _currentPage = 1;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            // Sort by date checkbox
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sort by Date', style: TextStyle(fontSize: smallFont, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Checkbox(
                      value: _sortRecentFirst,
                      onChanged: (val) {
                        setState(() {
                          _sortRecentFirst = val!;
                          _currentPage = 1;
                        });
                      },
                      activeColor: const Color(0xFF1A73E8),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(_sortRecentFirst ? 'Recent' : 'Oldest', style: TextStyle(fontSize: fontSize)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'marketing':
      case 'advertising':
        return Colors.blue;
      case 'sales':
        return Colors.pink;
      case 'development':
        return Colors.red;
      case 'travel':
        return Colors.orange;
      case 'hr':
        return Colors.green;
      case 'operations':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'marketing':
      case 'advertising':
        return Icons.campaign;
      case 'sales':
        return Icons.trending_up;
      case 'development':
        return Icons.code;
      case 'travel':
        return Icons.flight;
      case 'hr':
        return Icons.people;
      case 'operations':
        return Icons.settings;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getStatusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(double amount) {
    return '₱${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showAddExpenseDialog(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final _formKey = GlobalKey<FormState>();
    String description = '';
    String category = '';
    double? amount;
    DateTime date = DateTime.now();
    String userId = '';
    String teamId = '';
    String tags = '';
    String receipt = '';
    final categories = [
      'Food', 'Transportation', 'Entertainment', 'Shopping', 'Bills', 'Other',
      ...{
        for (final e in provider.personalExpenses)
          if (e.category.isNotEmpty) e.category
      }
    ];
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: const [
                  Icon(Icons.add, color: Color(0xFF1A73E8)),
                  SizedBox(width: 8),
                  Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 350,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Description (Subject)'),
                          onChanged: (v) => description = v,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Employee (User)'),
                          onChanged: (v) => userId = v,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Team (optional)'),
                          onChanged: (v) => teamId = v,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Amount', prefixText: '₱'),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => amount = double.tryParse(v),
                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a valid amount' : null,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: category.isNotEmpty ? category : null,
                          items: categories.toSet().map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                          onChanged: (v) => setState(() => category = v ?? ''),
                          decoration: const InputDecoration(labelText: 'Category'),
                          validator: (v) => v == null || v.isEmpty ? 'Select a category' : null,
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: date,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setState(() => date = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Date'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('yMMMd').format(date)),
                                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Tags (comma separated, optional)'),
                          onChanged: (v) => tags = v,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Receipt (URL, optional)'),
                          onChanged: (v) => receipt = v,
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All fields except Tags and Receipt are required. New expense will appear in all personal expense datasets and CSV exports.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isAddingExpense ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isAddingExpense
                      ? null
                      : () async {
                          if (_formKey.currentState?.validate() != true) return;
                          setState(() => _isAddingExpense = true);
                          final newExpense = Expense(
                            id: '',
                            description: description,
                            amount: amount!,
                            date: date,
                            category: category,
                            status: 'pending',
                            notes: null,
                            teamId: teamId,
                            userId: userId,
                            receipt: receipt.isNotEmpty ? receipt : null,
                          );
                          // Add tags if present
                          if (tags.trim().isNotEmpty) {
                            // If your Expense model supports tags, add them here
                            // e.g. newExpense.tags = tags.split(',').map((t) => t.trim()).toList();
                          }
                          try {
                            final body = {
                              'description': newExpense.description,
                              'Subject': newExpense.description,
                              'amount': newExpense.amount,
                              'Amount': newExpense.amount,
                              'date': newExpense.date.toIso8601String(),
                              'Date': newExpense.date.toIso8601String(),
                              'category': newExpense.category,
                              'Category': newExpense.category,
                              'status': newExpense.status,
                              'Status': newExpense.status,
                              'notes': newExpense.notes,
                              'Notes': newExpense.notes,
                              'teamId': newExpense.teamId,
                              'Team': newExpense.teamId,
                              'userId': newExpense.userId,
                              'User': newExpense.userId,
                              'receipt': newExpense.receipt,
                              'Receipt': newExpense.receipt,
                              // Add tags if you want, e.g. 'tags': ...
                            };
                            final response = await http.post(
                              Uri.parse('http://localhost:5000/api/personal-expenses'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode(body),
                            );

                            final responseData = jsonDecode(response.body);
                            print('Backend response: $responseData'); // Print the backend response for debugging

                            if (response.statusCode == 201 && responseData['success'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(responseData['message'] ?? 'Expense added successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.of(ctx).pop();
                              await context.read<ExpenseProvider>().loadPersonalExpenses(); // Reload the expenses list
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(responseData['error'] ?? 'Failed to add expense'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: _isAddingExpense
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryBreakdown(List<Expense> expenses) {
    final categoryTotals = <String, double>{};
    for (var expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Wrap the legend in a scrollable container with a max height
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200), // adjust as needed
              child: SingleChildScrollView(
                child: Column(
                  children: sortedCategories.take(10).map((entry) {
                    final percentage = (entry.value / expenses.fold(0, (sum, e) => sum + e.amount)) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key),
                              Text(_formatCurrency(entry.value)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                          Text('${percentage.toStringAsFixed(1)}%'),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => isEmpty ? '' : this[0].toUpperCase() + substring(1);
} 