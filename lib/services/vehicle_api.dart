import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'local_auth_service.dart';

class BackendVehicleData {
  final String id;
  final String model;
  final String year;
  final String plate;
  final int totalKm;

  const BackendVehicleData({
    required this.id,
    required this.model,
    required this.year,
    required this.plate,
    required this.totalKm,
  });

  factory BackendVehicleData.fromJson(Map<String, dynamic> json) {
    final totalKmRaw = json['totalKm'];
    final totalKm = totalKmRaw is num ? totalKmRaw.toInt() : 0;

    return BackendVehicleData(
      id: (json['id'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      year: (json['year'] ?? '').toString(),
      plate: (json['plate'] ?? '').toString(),
      totalKm: totalKm,
    );
  }
}

class VehicleApi {
  static const String baseUrl = 'http://localhost:3000/api';
  static const Duration timeout = Duration(seconds: 15);

  static Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final email = await LocalAuthService.getCurrentUserEmail();
    if (email == null || email.isEmpty) {
      throw Exception('Sessao invalida. Faca login novamente.');
    }

    return {
      if (jsonBody) 'Content-Type': 'application/json',
      'x-user-email': email,
    };
  }

  static Future<BackendVehicleData> createVehicle({
    required String model,
    required String year,
    required String plate,
    required int totalKm,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/vehicles'),
            headers: await _headers(jsonBody: true),
            body: jsonEncode({
              'model': model,
              'year': year,
              'plate': plate,
              'totalKm': totalKm,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        final data = jsonData['data'];
        if (data is Map<String, dynamic>) {
          return BackendVehicleData.fromJson(data);
        }
        throw Exception('Resposta invalida do servidor.');
      }

      throw Exception(_extractError(response));
    } on TimeoutException {
      throw Exception('Tempo de conexão esgotado ao salvar veículo.');
    } on http.ClientException {
      throw Exception('Erro de conexão ao salvar veículo.');
    }
  }

  static Future<List<BackendVehicleData>> listVehicles() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/vehicles'), headers: await _headers())
          .timeout(timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final data = jsonData['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((item) => BackendVehicleData.fromJson(item))
              .toList();
        }
        return const <BackendVehicleData>[];
      }

      throw Exception(_extractError(response));
    } on TimeoutException {
      throw Exception('Tempo de conexão esgotado ao carregar veículos.');
    } on http.ClientException {
      throw Exception('Erro de conexão ao carregar veículos.');
    }
  }

  static Future<void> deleteVehicleByPlate(String plate) async {
    final normalizedPlate = plate.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (normalizedPlate.isEmpty) {
      throw Exception('Placa invalida para exclusao.');
    }

    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/vehicles/$normalizedPlate'),
            headers: await _headers(),
          )
          .timeout(timeout);

      if (response.statusCode == 204) {
        return;
      }

      throw Exception(_extractError(response));
    } on TimeoutException {
      throw Exception('Tempo de conexão esgotado ao excluir veículo.');
    } on http.ClientException {
      throw Exception('Erro de conexão ao excluir veículo.');
    }
  }

  static String _extractError(http.Response response) {
    try {
      final parsed = jsonDecode(response.body);
      if (parsed is Map<String, dynamic>) {
        final error = parsed['error']?.toString();
        if (error != null && error.isNotEmpty) {
          if (error.toLowerCase().contains('vehicle already registered')) {
            return 'Este veículo já está cadastrado.';
          }
            if (error.toLowerCase().contains('vehicle not found')) {
              return 'Veículo não encontrado.';
            }
          return error;
        }
      }
    } catch (_) {
      // Ignore parse issues and use status code fallback.
    }

    if (response.statusCode == 409) {
      return 'Este veículo já está cadastrado.';
    }

    if (response.statusCode == 404) {
      return 'Veículo não encontrado.';
    }

    return 'Erro no servidor (${response.statusCode}).';
  }
}
