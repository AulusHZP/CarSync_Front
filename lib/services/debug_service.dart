import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

enum ConnectionStatus {
  connected,
  timeout,
  connectionError,
  invalidResponse,
  unknown,
}

class DebugService {
  /// Check the current API configuration
  static Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final interfaces = await NetworkInterface.list();
      final networkInfo = <Map<String, String>>[];
      
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          networkInfo.add({
            'interface': interface.name,
            'address': addr.address,
            'type': addr.type.toString(),
          });
        }
      }

      return {
        'baseUrl': ApiConfig.baseUrl,
        'networkInterfaces': networkInfo,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'baseUrl': ApiConfig.baseUrl,
      };
    }
  }

  /// Test connection to the API server
  static Future<ConnectionStatus> testApiConnection() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return ConnectionStatus.connected;
      }
      return ConnectionStatus.invalidResponse;
    } on TimeoutException {
      return ConnectionStatus.timeout;
    } on http.ClientException {
      return ConnectionStatus.connectionError;
    } catch (_) {
      return ConnectionStatus.unknown;
    }
  }

  /// Get a detailed connection report
  static Future<String> getConnectionReport() async {
    final debugInfo = await getDebugInfo();
    final connectionStatus = await testApiConnection();

    final buffer = StringBuffer();
    buffer.writeln('=== CarSync Connection Diagnostic Report ===\n');
    
    buffer.writeln('API Configuration:');
    buffer.writeln('  Base URL: ${debugInfo['baseUrl']}');
    buffer.writeln('  Timestamp: ${debugInfo['timestamp']}\n');

    if (debugInfo.containsKey('networkInterfaces')) {
      buffer.writeln('Network Interfaces:');
      final interfaces = debugInfo['networkInterfaces'] as List;
      for (final iface in interfaces) {
        buffer.writeln(
            '  - ${iface['interface']}: ${iface['address']} (${iface['type']})');
      }
      buffer.writeln();
    }

    buffer.writeln('Connection Test:');
    buffer.writeln('  Status: $connectionStatus');
    
    switch (connectionStatus) {
      case ConnectionStatus.connected:
        buffer.writeln('  ✓ Servidor está respondendo normalmente');
        break;
      case ConnectionStatus.timeout:
        buffer.writeln(
            '  ✗ Timeout: O servidor não respondeu no tempo esperado');
        buffer.writeln(
            '    Dica: Verifique se o servidor está rodando e acessível em ${debugInfo['baseUrl']}');
        break;
      case ConnectionStatus.connectionError:
        buffer.writeln('  ✗ Erro de conexão: Não foi possível conectar');
        buffer.writeln(
            '    Dica: Verifique se você está conectado à internet');
        buffer.writeln(
            '    Dica: Certifique-se que ${debugInfo['baseUrl']} é acessível');
        break;
      case ConnectionStatus.invalidResponse:
        buffer.writeln('  ✗ Resposta inválida do servidor');
        break;
      case ConnectionStatus.unknown:
        buffer.writeln('  ✗ Erro desconhecido durante a conexão');
        break;
    }

    return buffer.toString();
  }

  /// Print the connection report to the console
  static Future<void> printConnectionReport() async {
    final report = await getConnectionReport();
    print(report);
  }
}
