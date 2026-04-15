import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/service.dart';
import 'local_auth_service.dart';
import 'api_config.dart';

class ServiceApi {
  static String get baseUrl => ApiConfig.baseUrl;
  static const Duration timeout = Duration(seconds: 30);

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

  /// Create a new service
  static Future<Service> createService({
    required String serviceType,
    required DateTime date,
    String? notes,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/services'),
            headers: await _headers(json: true),
            body: jsonEncode({
              'serviceType': serviceType,
              // Backend validator requires ISO 8601 with timezone (UTC `Z`).
              'date': date.toUtc().toIso8601String(),
              if (notes != null && notes.isNotEmpty) 'notes': notes,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return Service.fromJson(jsonData['data']);
      } else {
        final error = jsonDecode(response.body);
        if (error is Map<String, dynamic>) {
          final details = error['details'];
          if (details is Map<String, dynamic> && details.isNotEmpty) {
            final detailsText =
                details.entries.map((e) => '${e.key}: ${e.value}').join(', ');
            throw Exception('Erro ao criar serviço: $detailsText');
          }
          throw Exception(
              'Erro ao criar serviço: ${error['error'] ?? 'Erro desconhecido'}');
        }
        throw Exception('Erro ao criar serviço');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro ao criar serviço: $e');
    }
  }

  /// Get all services with pagination
  static Future<ServiceResponse> getAllServices({
    int page = 1,
    int limit = 10,
    ServiceStatus? status,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status.apiValue,
      };

      final response = await http.get(
        Uri.parse('$baseUrl/services').replace(queryParameters: queryParams),
        headers: await _headers(json: true),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return ServiceResponse.fromJson(jsonData);
      } else {
        throw Exception('Erro ao carregar serviços: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar serviços: $e');
    }
  }

  /// Get service by ID
  static Future<Service> getServiceById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services/$id'),
        headers: await _headers(json: true),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Service.fromJson(jsonData['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Serviço não encontrado');
      } else {
        throw Exception('Erro ao carregar serviço: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar serviço: $e');
    }
  }

  /// Update service details
  static Future<Service> updateService({
    required String id,
    String? serviceType,
    DateTime? date,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        if (serviceType != null) 'serviceType': serviceType,
        if (date != null) 'date': date.toUtc().toIso8601String(),
        if (notes != null) 'notes': notes,
      };

      final response = await http
          .put(
            Uri.parse('$baseUrl/services/$id'),
            headers: await _headers(json: true),
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Service.fromJson(jsonData['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Serviço não encontrado');
      } else {
        throw Exception('Erro ao atualizar serviço: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar serviço: $e');
    }
  }

  /// Update service status
  static Future<Service> updateServiceStatus({
    required String id,
    required ServiceStatus status,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/services/$id/status'),
            headers: await _headers(json: true),
            body: jsonEncode({'status': status.apiValue}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Service.fromJson(jsonData['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Serviço não encontrado');
      } else {
        throw Exception('Erro ao atualizar status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar status: $e');
    }
  }

  /// Delete a service
  static Future<void> deleteService(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/services/$id'),
        headers: await _headers(json: true),
      ).timeout(timeout);

      if (response.statusCode != 204) {
        if (response.statusCode == 404) {
          throw Exception('Serviço não encontrado');
        } else {
          throw Exception('Erro ao deletar serviço: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Erro ao deletar serviço: $e');
    }
  }

  /// Get upcoming services
  static Future<List<Service>> getUpcomingServices({int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services/upcoming/list?days=$days'),
        headers: await _headers(json: true),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final items = (jsonData['data'] as List)
            .map((e) => Service.fromJson(e as Map<String, dynamic>))
            .toList();
        return items;
      } else {
        throw Exception(
            'Erro ao carregar serviços próximos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar serviços próximos: $e');
    }
  }

  /// Get service statistics
  static Future<ServiceStats> getServiceStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services/statistics/summary'),
        headers: await _headers(json: true),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return ServiceStats.fromJson(jsonData['data']);
      } else {
        throw Exception(
            'Erro ao carregar estatísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar estatísticas: $e');
    }
  }
}
