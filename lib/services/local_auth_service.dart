import 'dart:convert';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class AuthUser {
  final String name;
  final String email;
  final String password;

  const AuthUser({
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
    );
  }
}

class LocalAuthService {
  static const _legacyUsersKey = 'carsync.auth.users';
  static const _currentUserKey = 'carsync.auth.current_user';
  static const _tokenKey = 'carsync.auth.token';
  static const _timeout = Duration(seconds: 12);
  static const _maxRetries = 3;
  
  // Get the base URL dynamically from ApiConfig
  static String get _baseUrl => '${ApiConfig.baseUrl}/auth';

  static Map<String, dynamic>? _memoryCurrentUser;

  static Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = name.trim();

    final response = await _post(
      '/register',
      body: {
        'name': normalizedName,
        'email': normalizedEmail,
        'password': password,
      },
    );

    if (response.statusCode != 201) {
      throw Exception(_extractError(response));
    }

    final parsed = jsonDecode(response.body);
    final data = parsed is Map<String, dynamic> ? parsed['data'] : null;
    final userJson = data is Map<String, dynamic> ? data['user'] : null;
    final token = data is Map<String, dynamic> ? data['token'] : null;

    if (userJson is! Map<String, dynamic>) {
      throw Exception('Resposta invalida do servidor.');
    }

    final user = AuthUser(
      name: (userJson['name'] ?? normalizedName).toString(),
      email: (userJson['email'] ?? normalizedEmail).toString(),
      password: '',
    );

    await _saveCurrentSession(user: user, token: token?.toString());
    return user;
  }

  static Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final response = await _post(
      '/login',
      body: {
        'email': normalizedEmail,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      final data = parsed is Map<String, dynamic> ? parsed['data'] : null;
      final userJson = data is Map<String, dynamic> ? data['user'] : null;
      final token = data is Map<String, dynamic> ? data['token'] : null;

      if (userJson is! Map<String, dynamic>) {
        throw Exception('Resposta invalida do servidor.');
      }

      final user = AuthUser(
        name: (userJson['name'] ?? 'Usuario').toString(),
        email: (userJson['email'] ?? normalizedEmail).toString(),
        password: '',
      );

      await _saveCurrentSession(user: user, token: token?.toString());
      return user;
    }

    if (response.statusCode == 401) {
      final migrated = await _migrateLegacyAccount(normalizedEmail, password);
      if (migrated) {
        return login(email: normalizedEmail, password: password);
      }
    }

    throw Exception(_extractError(response));
  }

  static Future<void> clearCurrentUser() async {
    _memoryCurrentUser = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      await prefs.remove(_tokenKey);
    } on MissingPluginException {
      // Best-effort cleanup.
    } on PlatformException {
      // Best-effort cleanup.
    }
  }

  static Future<AuthUser?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_currentUserKey);
      if (raw == null || raw.isEmpty) {
        if (_memoryCurrentUser == null) {
          return null;
        }
        return AuthUser.fromJson(_memoryCurrentUser!);
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      _memoryCurrentUser = decoded;
      return AuthUser.fromJson(decoded);
    } on MissingPluginException {
      if (_memoryCurrentUser == null) {
        return null;
      }
      return AuthUser.fromJson(_memoryCurrentUser!);
    } on PlatformException {
      if (_memoryCurrentUser == null) {
        return null;
      }
      return AuthUser.fromJson(_memoryCurrentUser!);
    } catch (_) {
      if (_memoryCurrentUser == null) {
        return null;
      }
      return AuthUser.fromJson(_memoryCurrentUser!);
    }
  }

  static Future<String?> getCurrentUserEmail() async {
    final user = await getCurrentUser();
    final email = user?.email.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      return null;
    }
    return email;
  }

  static Future<void> _saveCurrentSession({
    required AuthUser user,
    String? token,
  }) async {
    _memoryCurrentUser = user.toJson();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
      if (token != null && token.isNotEmpty) {
        await prefs.setString(_tokenKey, token);
      }
    } on MissingPluginException {
      // Keep in-memory session only.
    } on PlatformException {
      // Keep in-memory session only.
    }
  }

  static Future<bool> _migrateLegacyAccount(
    String normalizedEmail,
    String password,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_legacyUsersKey);
      if (raw == null || raw.isEmpty) {
        return false;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return false;
      }

      final users = decoded.whereType<Map>();
      final legacy = users.firstWhere(
        (u) {
          final sameEmail =
              (u['email'] ?? '').toString().trim().toLowerCase() == normalizedEmail;
          final samePassword = (u['password'] ?? '').toString() == password;
          return sameEmail && samePassword;
        },
        orElse: () => <String, dynamic>{},
      );

      if (legacy.isEmpty) {
        return false;
      }

      final name = (legacy['name'] ?? 'Usuario').toString().trim();

      final registerResponse = await _post(
        '/register',
        body: {
          'name': name.isEmpty ? 'Usuario' : name,
          'email': normalizedEmail,
          'password': password,
        },
      );

      // 201 = migrated now; 409 = already exists remotely, still ok.
      return registerResponse.statusCode == 201 || registerResponse.statusCode == 409;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<http.Response> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    return _postWithRetry(path, body: body);
  }

  static Future<http.Response> _postWithRetry(
    String path, {
    required Map<String, dynamic> body,
    int retryCount = 0,
  }) async {
    try {
      final url = '$_baseUrl$path';
      print('[LocalAuthService] Tentando conectar a: $url (tentativa ${retryCount + 1}/$_maxRetries)');
      
      final response = await http
          .post(
            Uri.parse(url),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      print('[LocalAuthService] Resposta recebida com status: ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      print('[LocalAuthService] Timeout na tentativa ${retryCount + 1}/$_maxRetries: $e');
      if (retryCount < _maxRetries - 1) {
        // Aguardar antes de retentar (backoff exponencial)
        final delayMs = 500 * (retryCount + 1);
        print('[LocalAuthService] Aguardando ${delayMs}ms antes de retentar...');
        await Future.delayed(Duration(milliseconds: delayMs));
        return _postWithRetry(path, body: body, retryCount: retryCount + 1);
      }
      throw Exception(
        'Não foi possível conectar ao servidor após $_maxRetries tentativas.\n'
        'Servidor em: $_baseUrl\n'
        'Erro: $e\n'
        'Verifique:\n'
        '1. Se o servidor está rodando em http://localhost:3000\n'
        '2. Se sua conexão de internet está ativa\n'
        '3. Se o firewall não está bloqueando a porta 3000'
      );
    } on http.ClientException catch (e) {
      print('[LocalAuthService] Erro de cliente na tentativa ${retryCount + 1}/$_maxRetries: $e');
      if (retryCount < _maxRetries - 1) {
        final delayMs = 500 * (retryCount + 1);
        print('[LocalAuthService] Aguardando ${delayMs}ms antes de retentar...');
        await Future.delayed(Duration(milliseconds: delayMs));
        return _postWithRetry(path, body: body, retryCount: retryCount + 1);
      }
      throw Exception(
        'Erro de conexão com o servidor após $_maxRetries tentativas.\n'
        'Servidor: $_baseUrl\n'
        'Detalhes: $e\n'
        'Verificar:\n'
        '• Se o servidor backend está rodando\n'
        '• Se você está conectado à internet ou rede correta\n'
        '• Se a porta 3000 não está bloqueada'
      );
    } on FormatException catch (e) {
      throw Exception('Resposta inválida do servidor: $e');
    } catch (e) {
      print('[LocalAuthService] Erro inesperado: $e');
      if (retryCount < _maxRetries - 1) {
        final delayMs = 500 * (retryCount + 1);
        await Future.delayed(Duration(milliseconds: delayMs));
        return _postWithRetry(path, body: body, retryCount: retryCount + 1);
      }
      throw Exception(
        'Erro inesperado ao conectar ao servidor após $_maxRetries tentativas.\n'
        'Detalhes: $e'
      );
    }
  }

  static String _extractError(http.Response response) {
    try {
      final parsed = jsonDecode(response.body);
      if (parsed is Map<String, dynamic>) {
        final error = parsed['error']?.toString();
        if (error != null && error.isNotEmpty) {
          if (error.toLowerCase().contains('invalid email or password')) {
            return 'Email ou senha invalidos.';
          }
          if (error.toLowerCase().contains('email already registered')) {
            return 'Este email ja esta cadastrado.';
          }
          return error;
        }
      }
    } catch (_) {
      // Fall through to generic status mapping.
    }

    if (response.statusCode == 401) {
      return 'Email ou senha invalidos.';
    }
    if (response.statusCode == 409) {
      return 'Este email ja esta cadastrado.';
    }
    return 'Erro no servidor (${response.statusCode}).';
  }
}
