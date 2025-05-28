import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/expense.dart';
import '../models/team.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'x-auth-token': _token!,
    };
  }

  // Auth endpoints
  Future<String> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['token'];
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['token'];
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // Expense endpoints
  Future<List<Expense>> getExpenses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/expenses'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Expense.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load expenses');
    }
  }

  Future<Expense> createExpense(Expense expense) async {
    final response = await http.post(
      Uri.parse('$baseUrl/expenses'),
      headers: _headers,
      body: json.encode(expense.toJson()),
    );

    if (response.statusCode == 200) {
      return Expense.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create expense');
    }
  }

  Future<Expense> updateExpense(String id, Expense expense) async {
    final response = await http.put(
      Uri.parse('$baseUrl/expenses/$id'),
      headers: _headers,
      body: json.encode(expense.toJson()),
    );

    if (response.statusCode == 200) {
      return Expense.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update expense');
    }
  }

  Future<void> deleteExpense(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/expenses/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete expense');
    }
  }

  // Team endpoints
  Future<List<Team>> getTeams() async {
    final response = await http.get(
      Uri.parse('$baseUrl/teams'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Team.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load teams');
    }
  }

  Future<Team> createTeam(Team team) async {
    final response = await http.post(
      Uri.parse('$baseUrl/teams'),
      headers: _headers,
      body: json.encode(team.toJson()),
    );

    if (response.statusCode == 200) {
      return Team.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create team');
    }
  }

  Future<Team> updateTeam(String id, Team team) async {
    final response = await http.put(
      Uri.parse('$baseUrl/teams/$id'),
      headers: _headers,
      body: json.encode(team.toJson()),
    );

    if (response.statusCode == 200) {
      return Team.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update team');
    }
  }

  Future<Team> addTeamMember(String teamId, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/teams/$teamId/members'),
      headers: _headers,
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      return Team.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add team member');
    }
  }

  Future<Team> removeTeamMember(String teamId, String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/teams/$teamId/members/$userId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Team.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to remove team member');
    }
  }
} 