import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../data/models/expense.dart';

class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({Key? key}) : super(key: key);

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage> {
  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'Pending';
  bool _sortRecentFirst = true;
  int _currentPage = 1;
  static const int _rowsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final allExpenses = provider.personalExpenses;
    final categories = [
      'All Categories',
      ...{
        for (final e in allExpenses)
          if (e.category.isNotEmpty) e.category
      }
    ];
    final statuses = ['All Status', 'Pending', 'Approved', 'Rejected'];
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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32),
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
                        const Icon(Icons.verified, color: Color(0xFF1A73E8), size: 22),
                        const SizedBox(width: 10),
                        const Text('Expense Approvals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Category Dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Category', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
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
                              items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
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
                          const Text('Status', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
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
                              items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
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
                        const Text('Sort by Date', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
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
                            Text(_sortRecentFirst ? 'Recent' : 'Oldest', style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DataTable(
                          columnSpacing: 10,
                          dataRowMinHeight: 32,
                          dataRowMaxHeight: 38,
                          headingRowHeight: 36,
                          horizontalMargin: 2,
                          headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F7FA)),
                          border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200)),
                          columns: const [
                            DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Roboto'))),
                            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Roboto'))),
                            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Roboto'))),
                            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Roboto'))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Roboto'))),
                            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Roboto'))),
                          ],
                          rows: List.generate(pageExpenses.length, (index) {
                            final expense = pageExpenses[index];
                            final isEven = index % 2 == 0;
                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                                if (states.contains(MaterialState.hovered)) {
                                  return Colors.blue.withOpacity(0.08);
                                }
                                return isEven ? const Color(0xFFF8FAFC) : Colors.white;
                              }),
                              cells: [
                                DataCell(
                                  Text(
                                    expense.description.isNotEmpty ? expense.description : '(No Description)',
                                    style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12, fontFamily: 'Roboto'),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                DataCell(Row(
                                  children: [
                                    Icon(_getCategoryIcon(expense.category), color: _getCategoryColor(expense.category), size: 12),
                                    const SizedBox(width: 3),
                                    Text(expense.category, style: TextStyle(color: Colors.grey.shade800, fontSize: 12, fontFamily: 'Roboto')),
                                  ],
                                )),
                                DataCell(Text(_formatDate(expense.date), style: const TextStyle(color: Colors.black87, fontSize: 12, fontFamily: 'Roboto'))),
                                DataCell(Text(_formatCurrency(expense.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Roboto'))),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(expense.status).withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        expense.status?.toLowerCase() == 'approved' ? Icons.check_circle :
                                        expense.status?.toLowerCase() == 'pending' ? Icons.hourglass_top :
                                        expense.status?.toLowerCase() == 'rejected' ? Icons.cancel : Icons.info,
                                        color: _getStatusColor(expense.status),
                                        size: 11,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        expense.status ?? 'N/A',
                                        style: TextStyle(
                                          color: _getStatusColor(expense.status),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                DataCell(
                                  (expense.status?.toLowerCase() == 'pending')
                                      ? Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.check, color: Colors.green, size: 14),
                                              tooltip: 'Approve',
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(minWidth: 22, minHeight: 22),
                                              onPressed: () => _showConfirmationDialog(
                                                context,
                                                'Approve Expense',
                                                'Are you sure you want to approve this expense?',
                                                () async {
                                                  try {
                                                    await provider.approveExpense(expense.id);
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Row(
                                                            children: [
                                                              const Icon(Icons.check_circle, color: Colors.white),
                                                              const SizedBox(width: 8),
                                                              const Text('Expense approved successfully'),
                                                            ],
                                                          ),
                                                          backgroundColor: Colors.green,
                                                          behavior: SnackBarBehavior.floating,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Error: ${e.toString()}'),
                                                          backgroundColor: Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, color: Colors.red, size: 14),
                                              tooltip: 'Reject',
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(minWidth: 22, minHeight: 22),
                                              onPressed: () => _showConfirmationDialog(
                                                context,
                                                'Reject Expense',
                                                'Are you sure you want to reject this expense?',
                                                () async {
                                                  try {
                                                    await provider.rejectExpense(expense.id);
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Row(
                                                            children: [
                                                              const Icon(Icons.cancel, color: Colors.white),
                                                              const SizedBox(width: 8),
                                                              const Text('Expense rejected'),
                                                            ],
                                                          ),
                                                          backgroundColor: Colors.red,
                                                          behavior: SnackBarBehavior.floating,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Error: ${e.toString()}'),
                                                          backgroundColor: Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            );
                          }),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _buildPagination(filtered.length, start, end, totalPages),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(int totalCount, int start, int end, int totalPages, {double fontSize = 12}) {
    List<Widget> pageButtons = [];
    int window = 2;
    for (int i = 1; i <= totalPages; i++) {
      if (i == 1 || i == totalPages || (i - _currentPage).abs() <= window) {
        pageButtons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: i == _currentPage ? const Color(0xFF1A73E8) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: i == _currentPage
                    ? [BoxShadow(color: Colors.blue.withOpacity(0.13), blurRadius: 8, offset: const Offset(0, 2))]
                    : [],
                border: Border.all(color: i == _currentPage ? const Color(0xFF1A73E8) : Colors.grey.shade200, width: 1.2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _currentPage = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
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
        (i == 2 && _currentPage - window > 2) ||
        (i == totalPages - 1 && _currentPage + window < totalPages - 1) ||
        (i > 1 && i < totalPages &&
          ((i == _currentPage - window - 1) || (i == _currentPage + window + 1)))
      ) {
        if (pageButtons.isEmpty || pageButtons.last is! Text) {
          pageButtons.add(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing b[${start + 1}] to $end of $totalCount entries', style: TextStyle(color: Colors.grey, fontSize: fontSize, fontFamily: 'Roboto')),
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return '₱${amount.toStringAsFixed(2)}';
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
      case 'bills':
        return Icons.receipt_long;
      case 'other':
        return Icons.description;
      case 'finance':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'marketing':
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
      case 'bills':
        return Colors.grey;
      case 'other':
        return Colors.grey;
      case 'finance':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                title.contains('Approve') ? Icons.check_circle : Icons.cancel,
                color: title.contains('Approve') ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: title.contains('Approve') ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(title.contains('Approve') ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );
  }
} 