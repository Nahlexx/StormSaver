import 'package:flutter/foundation.dart';
import '../data/models/expense.dart';
import '../data/services/expense_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();
  List<Expense> _personalExpenses = [];
  List<Expense> _teamExpenses = [];
  bool _isLoading = false;
  String? _error;
  double _monthlyBudget = 5000.0;
  String _companyName = 'Storm Tech Solutions';
  String _companyAddress = '123 Business Avenue, Makati City';
  String _companyContact = '+63 912 345 6789';
  String _companyEmail = 'josh.nimo@email.com';

  List<Expense> get personalExpenses => _personalExpenses;
  List<Expense> get teamExpenses => _teamExpenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get monthlyBudget => _monthlyBudget;
  String get companyName => _companyName;
  String get companyAddress => _companyAddress;
  String get companyContact => _companyContact;
  String get companyEmail => _companyEmail;

  Future<void> loadPersonalExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _personalExpenses = await _expenseService.getPersonalExpenses();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTeamExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _teamExpenses = await _expenseService.getTeamExpenses();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense, {bool isTeam = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newExpense = await _expenseService.addExpense(expense, isTeam: isTeam);
      if (isTeam) {
        _teamExpenses.add(newExpense);
      } else {
        _personalExpenses.add(newExpense);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateExpense(Expense expense, {bool isTeam = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedExpense = await _expenseService.updateExpense(expense, isTeam: isTeam);
      if (isTeam) {
        final index = _teamExpenses.indexWhere((e) => e.id == expense.id);
        if (index != -1) {
          _teamExpenses[index] = updatedExpense;
        }
      } else {
        final index = _personalExpenses.indexWhere((e) => e.id == expense.id);
        if (index != -1) {
          _personalExpenses[index] = updatedExpense;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id, {bool isTeam = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _expenseService.deleteExpense(id, isTeam: isTeam);
      if (isTeam) {
        _teamExpenses.removeWhere((e) => e.id == id);
      } else {
        _personalExpenses.removeWhere((e) => e.id == id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveExpense(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('http://localhost:5000/api/personal-expenses/$id/approve'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Refresh the expenses list
        await loadPersonalExpenses();
        notifyListeners();
      } else {
        throw Exception('Failed to approve expense');
      }
    } catch (e) {
      throw Exception('Error approving expense: $e');
    }
  }

  Future<void> rejectExpense(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('http://localhost:5000/api/personal-expenses/$id/reject'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Refresh the expenses list
        await loadPersonalExpenses();
        notifyListeners();
      } else {
        throw Exception('Failed to reject expense');
      }
    } catch (e) {
      throw Exception('Error rejecting expense: $e');
    }
  }

  Future<void> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    _monthlyBudget = prefs.getDouble('monthlyBudget') ?? 5000.0;
    notifyListeners();
  }

  Future<void> setMonthlyBudget(double value) async {
    _monthlyBudget = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthlyBudget', value);
    notifyListeners();
  }

  Future<void> loadCompanyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _companyName = prefs.getString('companyName') ?? 'Storm Tech Solutions';
    _companyAddress = prefs.getString('companyAddress') ?? '123 Business Avenue, Makati City';
    _companyContact = prefs.getString('companyContact') ?? '+63 912 345 6789';
    _companyEmail = prefs.getString('companyEmail') ?? 'josh.nimo@email.com';
    notifyListeners();
  }

  Future<void> setCompanyInfo(String name, String address, String contact, String email) async {
    _companyName = name;
    _companyAddress = address;
    _companyContact = contact;
    _companyEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('companyName', name);
    await prefs.setString('companyAddress', address);
    await prefs.setString('companyContact', contact);
    await prefs.setString('companyEmail', email);
    notifyListeners();
  }
} 