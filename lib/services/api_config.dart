import 'dart:io';
import 'package:http/http.dart' as http;

class ApiConfig {
  static String? _baseUrl;
  static String? _overrideUrl;
  static bool _debugLogsEnabled = true;
  static const Duration _testTimeout = Duration(seconds: 10);

  /// URLs de ambiente
  /// Mude _currentEnvironment para trocar entre local e produção
  static const String _prodUrl = String.fromEnvironment(
    'CARSYNC_API_HOST',
    defaultValue: 'https://carsync-backend.onrender.com',
  );
  static const String _localUrl = 'http://localhost:3000/api';
  static const String _localIpUrl = 'http://192.168.1.1:3000/api'; // Para desenvolvimento local com IP

  /// Escolha o ambiente: 'prod', 'local' ou 'local-ip'
  static String _currentEnvironment = 'prod';

  /// Get the base URL for API calls
  static String get baseUrl {
    // If manually set, use that (highest priority)
    if (_overrideUrl != null) {
      return _overrideUrl!;
    }

    // If already detected/set, return it
    if (_baseUrl != null) {
      return _baseUrl!;
    }

    // Based on environment
    switch (_currentEnvironment) {
      case 'prod':
        return productionApiBaseUrl;
      case 'local':
        return _localUrl;
      case 'local-ip':
        return _localIpUrl;
      default:
        return _localUrl;
    }
  }

  static String get productionApiBaseUrl => '$_prodUrl/api';

  /// Definir o ambiente de execução
  static void setEnvironment(String env) {
    _currentEnvironment = env;
    _baseUrl = null; // Reset
    _log('Ambiente configurado para: $env');
  }

  /// Manually set the base URL (e.g., from settings)
  static void setBaseUrl(String url) {
    _overrideUrl = url;
    _log('Base URL definida manualmente: $url');
  }

  /// Auto-detect environment and set the base URL
  static Future<void> detectAndSetBaseUrl() async {
    // Manual override takes precedence
    if (_overrideUrl != null) {
      _baseUrl = _overrideUrl;
      _log('Usando URL manual: $_baseUrl');
      return;
    }

    _log('Detectando ambiente...');

    // In production mode we should NEVER fall back to local IPs.
    if (_currentEnvironment == 'prod') {
      _baseUrl = productionApiBaseUrl;
      _log('Modo produção ativo. Usando: $_baseUrl');
      return;
    }

    // Local mode: prefer localhost then local-ip.
    if (_currentEnvironment == 'local') {
      _baseUrl = _localUrl;
      _log('Modo local ativo. Usando: $_baseUrl');
      return;
    }

    if (_currentEnvironment == 'local-ip') {
      _baseUrl = _localIpUrl;
      _log('Modo local-ip ativo. Usando: $_baseUrl');
      return;
    }

    // Try with IP auto-detection for local network
    try {
      final interfaces = await NetworkInterface.list();
      _log('Procurando por interface de rede com IPv4...');
      
      final candidates = <String>[];
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.address.startsWith('127.')) {
            candidates.add(addr.address);
          }
        }
      }

      // Try each candidate IP in order
      for (final ip in candidates) {
        final url = 'http://$ip:3000/api';
        _log('Testando IP local: $url');
        
        if (await _testUrlAvailability(url)) {
          _baseUrl = url;
          _log('✓ Backend local (IP: $ip) detectado');
          return;
        }
      }
    } catch (e) {
      _log('Erro ao verificar IPs locais: $e');
    }

    // Fallback
    _baseUrl = _localUrl;
    _log('Nenhum backend local detectado, usando fallback local: $_baseUrl');
  }

  /// Test if a URL is actually available
  static Future<bool> _testUrlAvailability(String url) async {
    try {
      final response = await http
          .get(Uri.parse('$url/health'))
          .timeout(_testTimeout);
      
      final isAvailable = response.statusCode == 200 || response.statusCode == 404;
      return isAvailable;
    } catch (e) {
      return false;
    }
  }

  /// Test connection to the API server
  static Future<bool> testConnection() async {
    try {
      _log('Testando conexão com: $baseUrl/health');
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      
      final isHealthy = response.statusCode == 200 || response.statusCode == 404;
      _log(isHealthy ? '✓ Servidor respondeu' : '✗ Servidor retornou ${response.statusCode}');
      return isHealthy;
    } catch (e) {
      _log('✗ Erro ao testar: $e');
      return false;
    }
  }

  /// Reset to force re-detection on next call
  static void reset() {
    _baseUrl = null;
    _overrideUrl = null;
    _log('Configuração de URL resetada');
  }

  /// Enable or disable debug logs
  static void setDebugLogsEnabled(bool enabled) {
    _debugLogsEnabled = enabled;
  }

  static void _log(String message) {
    if (_debugLogsEnabled) {
      print('[ApiConfig] $message');
    }
  }
}
