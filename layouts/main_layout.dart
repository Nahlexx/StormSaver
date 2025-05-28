import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/sidebar.dart';
import '../navigation/navigation_provider.dart';
import '../navigation/sidebar_provider.dart';
import '../screens/dashboard_screen.dart';
import '../pages/expenses_page.dart';
import '../pages/reports_page.dart';
import '../pages/approvals_page.dart';
import '../pages/settings_page.dart';


class MainLayout extends StatelessWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: _buildCurrentPage(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage(BuildContext context) {
    final currentIndex = context.watch<NavigationProvider>().currentIndex;
    switch (currentIndex) {
      case NavigationProvider.dashboard:
        return const DashboardScreen();
      case NavigationProvider.expenses:
        return const ExpensesPage();
      case NavigationProvider.reports:
        return const ReportsPage();
      case NavigationProvider.approvals:
        return const ApprovalsPage();
      case NavigationProvider.settings:
        return const SettingsPage();
      default:
        return const DashboardScreen();
    }
  }
} 