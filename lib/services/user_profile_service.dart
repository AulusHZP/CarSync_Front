import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_auth_service.dart';

class UserProfileData {
  final String name;
  final String email;

  const UserProfileData({
    required this.name,
    required this.email,
  });
}

class UserProfileService {
  static const _profileKeyPrefix = 'carsync.user.profile';
  static const _legacyProfileKey = 'carsync.user.profile';
  static const _guestScope = 'guest';
  static final Map<String, UserProfileData> _memoryProfilesByScope =
      <String, UserProfileData>{};

  static Future<UserProfileData?> getProfile() async {
    final scope = await _currentScope();

    try {
      final prefs = await SharedPreferences.getInstance();
      final scopedKey = _profileKeyForScope(scope);
      String? raw = prefs.getString(scopedKey);

      if ((raw == null || raw.isEmpty) && scope != _guestScope) {
        final legacyRaw = prefs.getString(_legacyProfileKey);
        if (legacyRaw != null && legacyRaw.isNotEmpty) {
          final decodedLegacy = jsonDecode(legacyRaw);
          if (decodedLegacy is Map<String, dynamic>) {
            final legacyEmail =
                (decodedLegacy['email'] ?? '').toString().trim().toLowerCase();
            final currentEmail = await LocalAuthService.getCurrentUserEmail();

            if (currentEmail != null && currentEmail == legacyEmail) {
              await prefs.setString(scopedKey, legacyRaw);
              raw = legacyRaw;
            }
          }
        }
      }

      if (raw == null || raw.isEmpty) {
        return _memoryProfilesByScope[scope];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return _memoryProfilesByScope[scope];
      }

      final name = (decoded['name'] ?? '').toString().trim();
      final email = (decoded['email'] ?? '').toString().trim();
      if (name.isEmpty || email.isEmpty) {
        return _memoryProfilesByScope[scope];
      }

      final profile = UserProfileData(name: name, email: email);
      _memoryProfilesByScope[scope] = profile;
      return profile;
    } on MissingPluginException {
      return _memoryProfilesByScope[scope];
    } on PlatformException {
      return _memoryProfilesByScope[scope];
    } catch (_) {
      return _memoryProfilesByScope[scope];
    }
  }

  static Future<void> saveProfile({
    required String name,
    required String email,
  }) async {
    final scope = await _currentScope();

    _memoryProfilesByScope[scope] = UserProfileData(
      name: name.trim(),
      email: email.trim(),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final scopedKey = _profileKeyForScope(scope);
      await prefs.setString(
        scopedKey,
        jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
        }),
      );
    } on MissingPluginException {
      // Keep UI flow working even if plugin registration is stale.
    } catch (_) {
      // Best-effort local persistence.
    }
  }

  static Future<void> clearProfile() async {
    final scope = await _currentScope();
    _memoryProfilesByScope.remove(scope);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKeyForScope(scope));
    } on MissingPluginException {
      // Best-effort cleanup.
    } on PlatformException {
      // Best-effort cleanup.
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  static Future<String> _currentScope() async {
    final email = await LocalAuthService.getCurrentUserEmail();
    if (email == null || email.isEmpty) {
      return _guestScope;
    }
    return _sanitizeScope(email);
  }

  static String _profileKeyForScope(String scope) {
    return '$_profileKeyPrefix.$scope';
  }

  static String _sanitizeScope(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }
}
