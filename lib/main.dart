import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_theme.dart';
import 'navigation/app_router.dart';
import 'services/auth_session.dart';
import 'services/api_config.dart';
import 'services/debug_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    ApiConfig.setEnvironment('prod');

    // Auto-detect backend URL (prod → local → local-ip)
    await ApiConfig.detectAndSetBaseUrl();
    print('[main] Base URL configurada: ${ApiConfig.baseUrl}');

    // Test connection on startup
    final isConnected = await ApiConfig.testConnection();
    if (!isConnected) {
      print('[main] ⚠ Aviso: Servidor pode estar indisponível');
      await DebugService.printConnectionReport();
    }
  } catch (e) {
    print('[main] Erro ao inicializar API: $e');
  }

  try {
    await AuthSession.instance.init();
  } catch (e) {
    print('[main] Erro ao inicializar sessão de autenticação: $e');
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const CarSyncApp());
}

class CarSyncApp extends StatelessWidget {
  const CarSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CarSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
