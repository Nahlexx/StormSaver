import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/navigation_provider.dart';

class ReportSection extends StatelessWidget {
  const ReportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = Provider.of<NavigationProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reports Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildReportCard(
                context,
                'Total Expenses',
                _getTotalExpenses(context),
                Icons.account_balance_wallet,
                Colors.blue.shade100,
                Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildReportCard(
                context,
                'Pending Approvals',
                _getPendingApprovals(context),
                Icons.pending_actions,
                Colors.orange.shade100,
                Colors.orange.shade700,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildReportCard(
                context,
                'Approved This Month',
                _getApprovedExpenses(context),
                Icons.check_circle_outline,
                Colors.green.shade100,
                Colors.green.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  String _getTotalExpenses(BuildContext context) {
    final navigation = Provider.of<NavigationProvider>(context);
    final totals = {
      'Marketing': '\$5,500',
      'Development': '\$4,800',
      'Sales': '\$4,450',
    };
    return totals[navigation.selectedTeam] ?? '\$0';
  }

  String _getPendingApprovals(BuildContext context) {
    final navigation = Provider.of<NavigationProvider>(context);
    final pending = {
      'Marketing': '3',
      'Development': '4',
      'Sales': '5',
    };
    return pending[navigation.selectedTeam] ?? '0';
  }

  String _getApprovedExpenses(BuildContext context) {
    final navigation = Provider.of<NavigationProvider>(context);
    final approved = {
      'Marketing': '\$3,500',
      'Development': '\$3,000',
      'Sales': '\$2,800',
    };
    return approved[navigation.selectedTeam] ?? '\$0';
  }
} 