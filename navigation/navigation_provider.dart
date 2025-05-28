import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  String _selectedTeam = 'Marketing';
  String _expenseType = 'Team Expenses';
  final List<String> _availableTeams = ['Marketing', 'Sales', 'Development', 'Finance', 'HR'];
  final List<String> _expenseTypes = ['Personal Expenses', 'Team Expenses'];

  // Navigation indices
  static const int dashboard = 0;
  static const int expenses = 1;
  static const int reports = 2;
  static const int approvals = 3;
  static const int settings = 4;

  // Getters
  int get currentIndex => _currentIndex;
  String get selectedTeam => _selectedTeam;
  String get expenseType => _expenseType;
  List<String> get availableTeams => _availableTeams;
  List<String> get expenseTypes => _expenseTypes;

  // Navigation methods
  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void setSelectedTeam(String team) {
    if (_selectedTeam != team && _availableTeams.contains(team)) {
      _selectedTeam = team;
      notifyListeners();
    }
  }

  void setExpenseType(String type) {
    if (_expenseType != type && _expenseTypes.contains(type)) {
      _expenseType = type;
      notifyListeners();
    }
  }

  String getPageTitle() {
    switch (_currentIndex) {
      case dashboard:
        return 'Dashboard';
      case expenses:
        return 'Expenses';
      case reports:
        return 'Reports';
      case approvals:
        return 'Approvals';
      case settings:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  IconData getPageIcon() {
    switch (_currentIndex) {
      case dashboard:
        return Icons.dashboard;
      case expenses:
        return Icons.receipt_long;
      case reports:
        return Icons.bar_chart;
      case approvals:
        return Icons.check_circle_outline;
      case settings:
        return Icons.settings;
      default:
        return Icons.dashboard;
    }
  }

  bool isQuickAccessItem(int index) {
    return index >= approvals && index <= settings;
  }

  bool isMainNavigationItem(int index) {
    return index >= dashboard && index <= reports;
  }

  bool isAdditionalNavigationItem(int index) {
    return index == approvals || index == settings;
  }
} 