import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_auth_service.dart';
import 'user_profile_service.dart';

class AuthSession extends ChangeNotifier {
  static const _sessionKey = 'carsync.session.active';
  static final AuthSession instance = AuthSession._();

  AuthSession._();

  bool _isAuthenticated = false;
  bool _isReady = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isReady => _isReady;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool(_sessionKey) ?? false;
    } on MissingPluginException {
      // Allows app usage even when native plugin registration is stale.
      _isAuthenticated = false;
    } catch (_) {
      _isAuthenticated = false;
    }

    _isReady = true;
    notifyListeners();
  }

  Future<void> login() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sessionKey, true);
    } on MissingPluginException {
      // Fallback to in-memory session only.
    } catch (_) {
      // Fallback to in-memory session only.
    }

    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await LocalAuthService.clearCurrentUser();
      await UserProfileService.clearProfile();
    } on MissingPluginException {
      // Fallback to in-memory session only.
      await UserProfileService.clearProfile();
    } catch (_) {
      // Fallback to in-memory session only.
      await UserProfileService.clearProfile();
    }

    _isAuthenticated = false;
    notifyListeners();
  }
}
