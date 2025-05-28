import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense.dart';

class ExpenseService {
  static const String baseUrl = 'http://localhost:5000/api';

  // Test MongoDB connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/test'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to test connection: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error testing connection: $e');
    }
  }

  // Get personal expenses
  Future<List<Expense>> getPersonalExpenses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/personal-expenses'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> expensesList = data['expenses'] ?? [];
        return expensesList.map((json) => Expense.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load personal expenses: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching personal expenses: $e');
    }
  }

  // Get team expenses
  Future<List<Expense>> getTeamExpenses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/team-expenses'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> expensesList = data['expenses'] ?? [];
        return expensesList.map((json) => Expense.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load team expenses: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching team expenses: $e');
    }
  }

  // Add new expense
  Future<Expense> addExpense(Expense expense, {bool isTeam = false}) async {
    try {
      final endpoint = isTeam ? 'team-expenses' : 'personal-expenses';
      final body = endpoint == 'personal-expenses'
          ? {
              'description': expense.description,
              'Subject': expense.description,
              'amount': expense.amount,
              'Amount': expense.amount,
              'date': expense.date.toIso8601String(),
              'Date': expense.date.toIso8601String(),
              'category': expense.category,
              'Category': expense.category,
              'status': expense.status,
              'Status': expense.status,
              'notes': expense.notes,
              'Notes': expense.notes,
              'teamId': expense.teamId,
              'Team': expense.teamId,
              'userId': expense.userId,
              'User': expense.userId,
              'receipt': expense.receipt,
              'Receipt': expense.receipt,
            }
          : expense.toJson();
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return Expense.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add expense: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding expense: $e');
    }
  }

  // Update expense
  Future<Expense> updateExpense(Expense expense, {bool isTeam = false}) async {
    try {
      final endpoint = isTeam ? 'team-expenses' : 'personal-expenses';
      final body = endpoint == 'personal-expenses'
          ? {
              'description': expense.description,
              'Subject': expense.description,
              'amount': expense.amount,
              'Amount': expense.amount,
              'date': expense.date.toIso8601String(),
              'Date': expense.date.toIso8601String(),
              'category': expense.category,
              'Category': expense.category,
              'status': expense.status,
              'Status': expense.status,
              'notes': expense.notes,
              'Notes': expense.notes,
              'teamId': expense.teamId,
              'Team': expense.teamId,
              'userId': expense.userId,
              'User': expense.userId,
              'receipt': expense.receipt,
              'Receipt': expense.receipt,
            }
          : expense.toJson();
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint/${expense.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return Expense.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update expense: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating expense: $e');
    }
  }

  // Delete expense
  Future<void> deleteExpense(String id, {bool isTeam = false}) async {
    try {
      final endpoint = isTeam ? 'team-expenses' : 'personal-expenses';
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete expense: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting expense: $e');
    }
  }

  Future<Expense> approveExpense(String id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/personal-expenses/$id/approve'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return Expense.fromJson(json.decode(response.body)['expense']);
    } else {
      throw Exception('Failed to approve expense');
    }
  }

  Future<Expense> rejectExpense(String id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/personal-expenses/$id/reject'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return Expense.fromJson(json.decode(response.body)['expense']);
    } else {
      throw Exception('Failed to reject expense');
    }
  }
} 