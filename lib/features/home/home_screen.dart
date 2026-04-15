import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/fuel_calculator_screen.dart';
import 'km_history_screen.dart';
import '../../models/service.dart';
import '../../services/expense_service.dart';
import '../../services/home_refresh_notifier.dart';
import '../../services/service_api.dart';
import '../../services/user_profile_service.dart';
import '../../services/vehicle_profile_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/dark_card.dart';
import '../../widgets/premium_carsync_header.dart';
import '../../widgets/status_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _summaryCardsHeight = 168;

  bool _isLoadingMetrics = true;
  String? _metricsError;

  double _monthlyTotal = 0;
  double _fuelMonthlyTotal = 0;
  double _fuelMonthlyLiters = 0;
  Map<String, Map<String, double>> _fuelByType =
      {}; // {fuelType: {total, liters}}
  int _monthlyDrivenKm = 0;
  int? _currentTotalKm;
  bool _hasCurrentMonthKm = false;
  bool _hasVehicleProfile = false;
  String _activeVehicleModel = '';
  String _userName = '';
  List<VehicleProfileData> _availableVehicles = const <VehicleProfileData>[];

  int _scheduledServices = 0;
  int _upcomingServices = 0;
  List<Service> _activeMaintenanceServices = const [];

  @override
  void initState() {
    super.initState();
    HomeRefreshNotifier.listenable.addListener(_handleHomeTabSelected);
    _loadHomeData();
  }

  @override
  void dispose() {
    HomeRefreshNotifier.listenable.removeListener(_handleHomeTabSelected);
    super.dispose();
  }

  void _handleHomeTabSelected() {
    if (!mounted) {
      return;
    }

    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoadingMetrics = true;
      _metricsError = null;
    });

    String? error;
    double? monthlyTotal;
    double? fuelMonthlyTotal;
    int? scheduledServices;
    int? upcomingServices;
    List<Service>? activeMaintenanceServices;
    int? monthlyDrivenKm;
    int? currentTotalKm;
    bool? hasCurrentMonthKm;
    bool? hasVehicleProfile;
    String? userName;
    String activeVehicleModel = '';
    List<VehicleProfileData> availableVehicles = const <VehicleProfileData>[];

    try {
      final expensesData = await ExpenseService.getExpenses();

      double total = 0;
      double fuel = 0;
      double fuelLiters = 0;
      Map<String, Map<String, double>> fuelByType = {};

      for (final dynamic entry in expensesData) {
        if (entry is! Map<String, dynamic>) continue;

        final amount = _parseAmount(entry['amount']);
        total += amount;

        if (_isFuelEntry(entry)) {
          fuel += amount;
          final liters = entry['liters'];
          if (liters != null) {
            fuelLiters += (liters is num) ? liters.toDouble() : 0;
          }

          // Agrupa por tipo de combustível
          final fuelType = (entry['fuelType'] as String?) ?? 'Desconhecido';
          final litersValue = (liters is num) ? liters.toDouble() : 0;

          if (!fuelByType.containsKey(fuelType)) {
            fuelByType[fuelType] = {'total': 0, 'liters': 0};
          }
          fuelByType[fuelType]!['total'] =
              (fuelByType[fuelType]!['total'] ?? 0) + amount;
          fuelByType[fuelType]!['liters'] =
              (fuelByType[fuelType]!['liters'] ?? 0) + litersValue;
        }
      }

      monthlyTotal = total;
      fuelMonthlyTotal = fuel;
      _fuelMonthlyLiters = fuelLiters;
      _fuelByType = fuelByType;
    } catch (_) {
      error = 'Nao foi possivel atualizar os dados de gastos.';
    }

    try {
      final response = await ServiceApi.getAllServices(limit: 100);
      final services = response.data
          .where((service) =>
              service.status == ServiceStatus.scheduled ||
              service.status == ServiceStatus.upcoming)
          .toList();

      scheduledServices = services
          .where((service) => service.status == ServiceStatus.scheduled)
          .length;
      upcomingServices = services
          .where((service) => service.status == ServiceStatus.upcoming)
          .length;
      activeMaintenanceServices = services;
    } catch (_) {
      if (error == null) {
        error = 'Nao foi possivel atualizar os dados de manutencao.';
      } else {
        error = '$error E tambem da manutencao.';
      }
    }

    try {
      final summary = await VehicleProfileService.getMileageSummary();
      final profiles = await VehicleProfileService.listProfiles();
      final profile = await VehicleProfileService.getProfile();
      monthlyDrivenKm = summary.monthlyDistanceKm;
      currentTotalKm = summary.currentTotalKm;
      hasCurrentMonthKm = summary.hasCurrentMonthEntry;
      availableVehicles = profiles;
      final model = profile?.model.trim() ?? '';
      activeVehicleModel = model;
      hasVehicleProfile = profile != null &&
          model.isNotEmpty &&
          profile.plate.trim().isNotEmpty &&
          profile.plate.trim() != '--';
    } catch (_) {
      if (error == null) {
        error = 'Nao foi possivel atualizar a quilometragem.';
      } else {
        error = '$error E tambem da quilometragem.';
      }
    }

    try {
      final userProfile = await UserProfileService.getProfile();
      final name = userProfile?.name.trim() ?? '';
      if (name.isNotEmpty) {
        userName = name;
      }
    } catch (_) {
      // Keep fallback greeting when profile is unavailable.
    }

    if (!mounted) return;
    setState(() {
      if (monthlyTotal != null) _monthlyTotal = monthlyTotal;
      if (fuelMonthlyTotal != null) _fuelMonthlyTotal = fuelMonthlyTotal;
      if (scheduledServices != null) _scheduledServices = scheduledServices;
      if (upcomingServices != null) _upcomingServices = upcomingServices;
      if (activeMaintenanceServices != null) {
        _activeMaintenanceServices = activeMaintenanceServices;
      }
      if (monthlyDrivenKm != null) _monthlyDrivenKm = monthlyDrivenKm;
      if (hasCurrentMonthKm != null) _hasCurrentMonthKm = hasCurrentMonthKm;
      if (hasVehicleProfile != null) _hasVehicleProfile = hasVehicleProfile;
      _activeVehicleModel = activeVehicleModel;
      if (userName != null) _userName = userName;
      _currentTotalKm = currentTotalKm;
      _availableVehicles = availableVehicles;

      _metricsError = error;
      _isLoadingMetrics = false;
    });
  }

  Future<void> _openVehicleSwitcher() async {
    if (_availableVehicles.length <= 1) {
      return;
    }

    final current = await VehicleProfileService.getProfile();
    if (!mounted) {
      return;
    }

    final selectedPlate = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x16000000),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Trocar veículo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              ..._availableVehicles.map((vehicle) {
                final isCurrent =
                    current != null && vehicle.plate == current.plate;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.of(sheetContext).pop(vehicle.plate),
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0x0A000000),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.car,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    vehicle.model,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  subtitle: Text(
                    vehicle.plate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(
                          LucideIcons.circleCheck,
                          size: 16,
                          color: AppColors.accent,
                        )
                      : const Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: AppColors.quarter,
                        ),
                );
              }),
            ],
          ),
        );
      },
    );

    if (selectedPlate == null) {
      return;
    }

    final switched =
        await VehicleProfileService.setActiveProfileByPlate(selectedPlate);
    if (!switched) {
      return;
    }

    await _loadHomeData();
    if (!mounted) {
      return;
    }

    AppFeedback.show(
      context,
      message: 'Veículo alterado com sucesso.',
      tone: AppFeedbackTone.success,
    );
  }

  double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  bool _isFuelEntry(Map<String, dynamic> entry) {
    final category = (entry['category'] ?? '').toString().toUpperCase();
    final categoryLabel =
        (entry['categoryLabel'] ?? '').toString().toLowerCase();
    return category == 'FUEL' || categoryLabel.contains('combust');
  }

  String _formatMoney(double value, {bool withSpace = false}) {
    final prefix = withSpace ? 'R\$ ' : 'R\$';
    return '$prefix${value.toStringAsFixed(2)}';
  }

  String _formatKm(int value) {
    return VehicleProfileService.formatKm(value);
  }

  String _maintenanceSummary() {
    if (_isLoadingMetrics && _activeMaintenanceServices.isEmpty) {
      return 'Atualizando servicos...';
    }
    if (_scheduledServices == 0 && _upcomingServices == 0) {
      return 'Sem servicos agendados ou em breve';
    }

    final parts = <String>[];
    if (_scheduledServices > 0) {
      parts.add(
          '$_scheduledServices agendado${_scheduledServices > 1 ? 's' : ''}');
    }
    if (_upcomingServices > 0) {
      parts.add('$_upcomingServices em breve');
    }
    return parts.join(' • ');
  }

  String _maintenancePreview() {
    if (_activeMaintenanceServices.isEmpty) {
      return 'Todos os sistemas operando';
    }

    final names = _activeMaintenanceServices
        .take(2)
        .map((service) => service.serviceType)
        .join(' • ');

    final rest = _activeMaintenanceServices.length - 2;
    if (rest > 0) return '$names • +$rest';
    return names;
  }

  Color _maintenanceColor() {
    if (_upcomingServices > 0) return AppColors.amber;
    if (_scheduledServices > 0) return AppColors.accent;
    return AppColors.green;
  }

  Color _maintenanceBg() {
    if (_upcomingServices > 0) return const Color(0x14F59E0B);
    if (_scheduledServices > 0) return const Color(0x143B82F6);
    return const Color(0x1422C55E);
  }

  int _carHealthPercentage() {
    if (!_hasVehicleProfile) {
      return 100;
    }

    if (_scheduledServices == 0 && _upcomingServices == 0) {
      return 100;
    }

    final deduction = (_upcomingServices * 18) + (_scheduledServices * 10);
    final health = 100 - deduction;
    return health.clamp(25, 100);
  }

  String _carHealthLabel(int health) {
    if (!_hasVehicleProfile) {
      return 'Sem carro cadastrado';
    }

    if (health >= 95) {
      return 'Excelente estado';
    }
    if (health >= 80) {
      return 'Bom estado';
    }
    if (health >= 60) {
      return 'Atencao necessaria';
    }
    return 'Revisao urgente';
  }

  String _carHealthTitle() {
    final model = _activeVehicleModel.trim();
    if (model.isEmpty || !_hasVehicleProfile) {
      return 'SAUDE DO CARRO';
    }

    return 'SAUDE DO ${model.toUpperCase()}';
  }

  String _headerGreeting() {
    final trimmed = _userName.trim();
    if (trimmed.isEmpty) {
      return 'Olá, usuário';
    }

    final firstName = trimmed.split(RegExp(r'\s+')).first;
    return 'Olá, $firstName';
  }

  Widget _buildFuelCard({
    required String? fuelType,
    required double total,
    required double liters,
  }) {
    final label = fuelType ?? 'Combustível';
    return GestureDetector(
      onTap: _goToExpenses,
      child: AppCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: const Color(0x143B82F6),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(LucideIcons.droplet,
                      size: 18, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Text(
                    _isLoadingMetrics
                        ? '...'
                        : _formatMoney(total, withSpace: true),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _openFuelCalculator,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.calculator,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            if (!_isLoadingMetrics && liters > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xF5F5F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Litros',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${liters.toStringAsFixed(2)} L',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'L / R\$',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          total > 0
                              ? '${(liters / total).toStringAsFixed(3)}'
                              : '0',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _carHealthColor(int health) {
    if (!_hasVehicleProfile || health >= 95) {
      return AppColors.green;
    }
    if (health >= 80) {
      return AppColors.accent;
    }
    if (health >= 60) {
      return AppColors.amber;
    }
    return AppColors.red;
  }

  void _goToExpenses() {
    context.go('/expenses');
  }

  void _goToMaintenance() {
    context.go('/maintenance');
  }

  Future<void> _openFuelCalculator() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FuelCalculatorScreen(),
      ),
    );
  }

  Future<void> _openAddExpenseQuickAction() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AddExpenseScreen(),
      ),
    );

    if (!mounted || created != true) {
      return;
    }

    await _loadHomeData();
    if (!mounted) {
      return;
    }

    AppFeedback.show(
      context,
      message: 'Gasto adicionado com sucesso.',
      tone: AppFeedbackTone.success,
    );
  }

  Future<void> _openKmHistoryScreen() async {
    final profile = await VehicleProfileService.getProfile();
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => KmHistoryScreen(
          vehicleName: profile?.model ?? 'CarSync',
          vehiclePlate: profile?.plate,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadHomeData();
  }

  @override
  Widget build(BuildContext context) {
    final health = _carHealthPercentage();
    final healthLabel = _carHealthLabel(health);
    final healthColor = _carHealthColor(health);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHomeData,
          color: AppColors.accent,
          backgroundColor: AppColors.card,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PremiumCarSyncHeader(
                        appName: 'CarSync',
                        greeting: _headerGreeting(),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/alerts'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.separator,
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.bell,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (_availableVehicles.length > 1) ...[
                      const SizedBox(width: 10),
                      TextButton.icon(
                        onPressed: _openVehicleSwitcher,
                        icon: const Icon(LucideIcons.refreshCw, size: 14),
                        label: const Text('Trocar'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          backgroundColor: AppColors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                              color: AppColors.separator,
                              width: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                if (_metricsError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.triangleAlert,
                              size: 16, color: AppColors.amber),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _metricsError!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.secondary),
                            ),
                          ),
                          TextButton(
                              onPressed: _loadHomeData,
                              child: const Text('Tentar')),
                        ],
                      ),
                    ),
                  ),
                DarkCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _carHealthTitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.sectionLabelStyle
                            .copyWith(color: const Color(0xCCFFFFFF)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$health',
                              style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1,
                                  letterSpacing: -2)),
                          const SizedBox(width: 6),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text('%',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w300,
                                    color: Color(0xB3FFFFFF))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          StatusIndicator(color: healthColor, size: 5),
                          const SizedBox(width: 6),
                          Text(healthLabel,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: healthColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_fuelByType.isEmpty)
                  _buildFuelCard(
                      fuelType: null,
                      total: _fuelMonthlyTotal,
                      liters: _fuelMonthlyLiters)
                else if (_fuelByType.length == 1)
                  _buildFuelCard(
                    fuelType: _fuelByType.keys.first,
                    total: _fuelByType.values.first['total'] ?? 0,
                    liters: _fuelByType.values.first['liters'] ?? 0,
                  )
                else
                  ..._fuelByType.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildFuelCard(
                        fuelType: entry.key,
                        total: entry.value['total'] ?? 0,
                        liters: entry.value['liters'] ?? 0,
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = MediaQuery.sizeOf(context).width < 360;

                    if (compact) {
                      return Column(
                        children: [
                          _buildMonthlyExpenseCard(),
                          const SizedBox(height: 12),
                          _buildMonthlyKmCard(),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: _buildMonthlyExpenseCard()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMonthlyKmCard()),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _goToMaintenance,
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    borderRadius: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status da manutencao',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
                              const SizedBox(height: 4),
                              Text(_maintenanceSummary(),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.secondary,
                                      letterSpacing: 0.2)),
                              const SizedBox(height: 2),
                              Text(
                                _maintenancePreview(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.tertiary,
                                    letterSpacing: 0.1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: _maintenanceBg(), shape: BoxShape.circle),
                          child: Icon(LucideIcons.circleCheck,
                              size: 16, color: _maintenanceColor()),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyExpenseCard() {
    return SizedBox(
      height: _summaryCardsHeight,
      child: AppCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MENSAL', style: AppTheme.sectionLabelStyle),
            const SizedBox(height: 8),
            Text(
              _isLoadingMetrics ? '...' : _formatMoney(_monthlyTotal),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            Material(
              color: const Color(0xFFF3F4F7),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _openAddExpenseQuickAction,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.plus,
                        size: 13,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Adicionar gasto',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyKmCard() {
    return SizedBox(
      height: _summaryCardsHeight,
      child: AppCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KM NO MES', style: AppTheme.sectionLabelStyle),
            const SizedBox(height: 8),
            Text(
              _isLoadingMetrics ? '...' : _formatKm(_monthlyDrivenKm),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _hasCurrentMonthKm
                  ? 'Total atual: ${_currentTotalKm != null ? _formatKm(_currentTotalKm!) : '--'}'
                  : 'Registre a KM deste mes no Perfil',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.secondary,
                letterSpacing: 0.1,
              ),
            ),
            const Spacer(),
            Material(
              color: const Color(0xFFF3F4F7),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _openKmHistoryScreen,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.history,
                        size: 13,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Histórico',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
