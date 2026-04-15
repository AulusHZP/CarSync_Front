import 'package:http/http.dart' as http;
import 'dart:convert';
import 'local_auth_service.dart';
import 'api_config.dart';

class ExpenseService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final email = await LocalAuthService.getCurrentUserEmail();
    if (email == null || email.isEmpty) {
      throw Exception('Sessao invalida. Faca login novamente.');
    }

    return {
      if (json) 'Content-Type': 'application/json',
      'x-user-email': email,
    };
  }

  // Mapping between Portuguese labels and API categories
  static const Map<String, String> categoryMap = {
    'Combustível': 'FUEL',
    'Manutenção': 'MAINTENANCE',
    'Seguro': 'INSURANCE',
    'Lava-rápido': 'CAR_WASH',
    'Estacionamento': 'PARKING',
    'Pedágio': 'TOLL',
    'Outro': 'OTHER',
  };

  static const Map<String, String> categoryLabelMap = {
    'FUEL': 'Combustível',
    'MAINTENANCE': 'Manutenção',
    'INSURANCE': 'Seguro',
    'CAR_WASH': 'Lava-rápido',
    'PARKING': 'Estacionamento',
    'TOLL': 'Pedágio',
    'OTHER': 'Outro',
  };

  // Get all expenses
  static Future<List<dynamic>> getExpenses(
      {int page = 1, int limit = 100}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/expenses?page=$page&limit=$limit'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['data'] ?? [];
      } else {
        throw Exception('Failed to load expenses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching expenses: $e');
    }
  }

  // Create a new expense
  static Future<Map<String, dynamic>> createExpense({
    required String category,
    required double amount,
    String? description,
    String? fuelType,
    double? liters,
    double? pricePerLiter,
  }) async {
    try {
      final apiCategory = categoryMap[category] ?? 'OTHER';

      final body = {
        'category': apiCategory,
        'amount': amount,
        'description': description ?? '',
      };

      // Add fuel-specific fields if it's a fuel expense
      if (apiCategory == 'FUEL') {
        if (fuelType != null) body['fuelType'] = fuelType;
        if (liters != null) body['liters'] = liters;
        if (pricePerLiter != null) body['pricePerLiter'] = pricePerLiter;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/expenses'),
            headers: await _headers(json: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['data'] ?? {};
      } else {
        throw Exception('Failed to create expense: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating expense: $e');
    }
  }

  // Get expense by ID
  static Future<Map<String, dynamic>> getExpenseById(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/expenses/$id'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['data'] ?? {};
      } else {
        throw Exception('Failed to load expense: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching expense: $e');
    }
  }

  // Update an expense
  static Future<Map<String, dynamic>> updateExpense({
    required String id,
    String? category,
    double? amount,
    String? description,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (category != null) {
        body['category'] = categoryMap[category] ?? category;
      }
      if (amount != null) {
        body['amount'] = amount;
      }
      if (description != null) {
        body['description'] = description;
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/expenses/$id'),
            headers: await _headers(json: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['data'] ?? {};
      } else {
        throw Exception('Failed to update expense: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating expense: $e');
    }
  }

  // Delete an expense
  static Future<void> deleteExpense(String id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/expenses/$id'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete expense: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting expense: $e');
    }
  }
}
