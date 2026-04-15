import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/expenses/expenses_screen.dart';
import '../features/expenses/fuel_calculator_screen.dart';
import '../features/maintenance/maintenance_screen.dart';
import '../features/maintenance/schedule_service_screen.dart';
import '../features/maintenance/service_detail_screen.dart';
import '../models/service.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/profile/profile_screen.dart';
import '../layout/app_layout.dart';
import '../services/auth_session.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: AuthSession.instance,
    redirect: (context, state) {
      if (!AuthSession.instance.isReady) {
        return null;
      }

      final loggingIn = state.matchedLocation == '/login';
      final isAuthenticated = AuthSession.instance.isAuthenticated;

      if (!isAuthenticated && !loggingIn) {
        return '/login';
      }

      if (isAuthenticated && loggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (context, state) => const ExpensesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calculator',
                builder: (context, state) => const FuelCalculatorScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/maintenance',
                builder: (context, state) => const MaintenanceScreen(),
                routes: [
                  GoRoute(
                    path: 'schedule',
                    builder: (context, state) => const ScheduleServiceScreen(),
                  ),
                  GoRoute(
                    path: 'detail/:serviceId',
                    builder: (context, state) {
                      final service = state.extra as Service;
                      return ServiceDetailScreen(service: service);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
    ],
  );
}
