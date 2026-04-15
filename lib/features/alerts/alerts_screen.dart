import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../models/service.dart';
import '../../services/alerts_refresh_notifier.dart';
import '../../services/expense_service.dart';
import '../../services/service_api.dart';
import '../../services/vehicle_profile_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/status_indicator.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  static const _readAlertsKey = 'carsync.alerts.read.ids';

  List<_AlertItem> _alerts = const [];
  final Set<String> _volatileReadIds = <String>{};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    AlertsRefreshNotifier.listenable.addListener(_handleAlertsTabSelected);
    _loadAlerts();
  }

  @override
  void dispose() {
    AlertsRefreshNotifier.listenable.removeListener(_handleAlertsTabSelected);
    super.dispose();
  }

  void _handleAlertsTabSelected() {
    if (!mounted) {
      return;
    }

    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final readIds = await _readPersistedIds();
    final dynamicAlerts = <_AlertItem>[];
    var servicesLoaded = false;
    var expensesLoaded = false;
    List<Service> loadedServices = const [];

    Object? servicesError;
    Object? expensesError;

    try {
      final serviceResponse = await ServiceApi.getAllServices(limit: 50);
      servicesLoaded = true;
      loadedServices = serviceResponse.data;
      dynamicAlerts.addAll(_buildServiceAlerts(loadedServices, readIds));
    } catch (e) {
      servicesError = e;
    }

    try {
      // Keep API call aligned with backend pagination defaults.
      final expenses = await ExpenseService.getExpenses();
      expensesLoaded = true;
      dynamicAlerts.addAll(_buildFuelAlerts(expenses, readIds));
    } catch (e) {
      expensesError = e;
    }

    if (servicesLoaded) {
      try {
        final oilAlert = await _buildMileageOilAlert(loadedServices, readIds);
        if (oilAlert != null) {
          dynamicAlerts.add(oilAlert);
        }
      } catch (_) {
        // Keep existing alerts even if mileage recommendation cannot be built.
      }
    }

    if (dynamicAlerts.isNotEmpty) {
      dynamicAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _alerts = dynamicAlerts;
        _isLoading = false;
      });
      return;
    }

    if (!servicesLoaded && !expensesLoaded) {
      final errors = <String>[];
      if (servicesError != null) {
        errors.add('serviços: $servicesError');
      }
      if (expensesError != null) {
        errors.add('gastos: $expensesError');
      }

      setState(() {
        _errorMessage = 'Erro ao carregar alertas (${errors.join(' | ')})';
        _isLoading = false;
      });
      return;
    }

    final now = DateTime.now();
    setState(() {
      _alerts = [
        _AlertItem(
          id: 'all-good-${now.year}-${now.month}',
          icon: LucideIcons.shieldCheck,
          iconColor: AppColors.green,
          iconBg: const Color(0x1422C55E),
          title: 'Tudo em dia',
          message: 'Nenhum alerta crítico no momento para seu carro.',
          time: 'agora',
          timestamp: now,
          unread: false,
        ),
      ];
      _isLoading = false;
    });
  }

  List<_AlertItem> _buildServiceAlerts(
    List<Service> services,
    Set<String> readIds,
  ) {
    final now = DateTime.now();
    final items = <_AlertItem>[];

    for (final service in services) {
      final dateLocal = service.date.toLocal();
      final updatedLocal = service.updatedAt.toLocal();
      final daysDiff =
          dateLocal.difference(DateTime(now.year, now.month, now.day)).inDays;

      final id =
          'service-${service.id}-${service.status.name}-${service.updatedAt.toIso8601String()}';

      if (service.status == ServiceStatus.completed) {
        if (now.difference(updatedLocal).inDays > 30) {
          continue;
        }

        items.add(
          _AlertItem(
            id: id,
            icon: LucideIcons.circleCheck,
            iconColor: AppColors.green,
            iconBg: const Color(0x1422C55E),
            title: 'Serviço concluído',
            message:
                '${service.serviceType} concluído em ${_formatShortDate(dateLocal)}',
            time: _relativeTime(updatedLocal),
            timestamp: updatedLocal,
            unread: !readIds.contains(id),
          ),
        );
        continue;
      }

      if (daysDiff < -2) {
        continue;
      }

      final isToday = daysDiff == 0;
      final dayLabel = isToday
          ? 'hoje'
          : daysDiff == 1
              ? 'amanhã'
              : 'em $daysDiff dias';

      final title = service.status == ServiceStatus.scheduled
          ? 'Manutenção agendada'
          : 'Manutenção em breve';

      items.add(
        _AlertItem(
          id: id,
          icon: LucideIcons.circleAlert,
          iconColor: AppColors.amber,
          iconBg: const Color(0x14F59E0B),
          title: title,
          message: '${service.serviceType} agendado $dayLabel',
          time: _relativeTime(updatedLocal),
          timestamp: updatedLocal,
          unread: !readIds.contains(id),
        ),
      );
    }

    return items;
  }

  List<_AlertItem> _buildFuelAlerts(
    List<dynamic> expenses,
    Set<String> readIds,
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);

    double currentFuelTotal = 0;
    double previousFuelTotal = 0;

    for (final raw in expenses) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }

      final categoryRaw =
          (raw['category'] ?? raw['categoryLabel'] ?? '').toString();
      final category = categoryRaw.toUpperCase();
      final isFuel = category == 'FUEL' ||
          categoryRaw.toLowerCase() == 'combustível' ||
          categoryRaw.toLowerCase() == 'combustivel';

      if (!isFuel) {
        continue;
      }

      final createdAtRaw = raw['createdAt']?.toString();
      final createdAt = createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw)?.toLocal()
          : null;
      if (createdAt == null) {
        continue;
      }

      final amount = ((raw['amount'] ?? 0) as num).toDouble();

      if (!createdAt.isBefore(monthStart) &&
          createdAt.isBefore(nextMonthStart)) {
        currentFuelTotal += amount;
      } else if (!createdAt.isBefore(prevMonthStart) &&
          createdAt.isBefore(monthStart)) {
        previousFuelTotal += amount;
      }
    }

    if (previousFuelTotal <= 0 ||
        currentFuelTotal <= previousFuelTotal * 1.15) {
      return const [];
    }

    final increasePercent =
        ((currentFuelTotal - previousFuelTotal) / previousFuelTotal * 100)
            .round();
    final id = 'fuel-trend-${now.year}-${now.month}';

    return [
      _AlertItem(
        id: id,
        icon: LucideIcons.trendingUp,
        iconColor: AppColors.accent,
        iconBg: const Color(0x143B82F6),
        title: 'Consumo de combustível aumentou',
        message: '$increasePercent% maior que no mês passado',
        time: 'este mês',
        timestamp: now,
        unread: !readIds.contains(id),
      ),
    ];
  }

  Future<_AlertItem?> _buildMileageOilAlert(
    List<Service> services,
    Set<String> readIds,
  ) async {
    final summary = await VehicleProfileService.getMileageSummary();
    final currentKm = summary.currentTotalKm;
    if (currentKm == null || currentKm < 9500) {
      return null;
    }

    if (_hasOilServicePlanned(services) ||
        _hasRecentCompletedOilService(services)) {
      return null;
    }

    final now = DateTime.now();
    final history = await VehicleProfileService.listKmHistory(limit: 2);

    int? crossedMilestone;
    if (history.length >= 2) {
      final latestKm = history.first.totalKm;
      final previousKm = history[1].totalKm;
      crossedMilestone = _findLastCrossedMilestone(previousKm, latestKm);
    }

    if (crossedMilestone == null && currentKm % 10000 == 0) {
      crossedMilestone = currentKm;
    }

    if (crossedMilestone != null) {
      final id = 'mileage-oil-$crossedMilestone';
      return _AlertItem(
        id: id,
        icon: LucideIcons.droplet,
        iconColor: AppColors.amber,
        iconBg: const Color(0x14F59E0B),
        title: 'Troca de óleo recomendada',
        message:
            'Seu carro atingiu ${VehicleProfileService.formatKm(crossedMilestone)}. Recomendamos agendar a troca de óleo.',
        time: 'agora',
        timestamp: now,
        unread: !readIds.contains(id),
      );
    }

    final nextMilestone = ((currentKm ~/ 10000) + 1) * 10000;
    final remainingKm = nextMilestone - currentKm;

    if (remainingKm <= 500) {
      final id = 'mileage-oil-near-$nextMilestone-${now.year}-${now.month}';
      return _AlertItem(
        id: id,
        icon: LucideIcons.circleAlert,
        iconColor: AppColors.amber,
        iconBg: const Color(0x14F59E0B),
        title: 'Revisão de 10.000 km próxima',
        message:
            'Faltam ${VehicleProfileService.formatKm(remainingKm)} para ${VehicleProfileService.formatKm(nextMilestone)}. Agende troca de óleo.',
        time: 'agora',
        timestamp: now,
        unread: !readIds.contains(id),
      );
    }

    return null;
  }

  bool _hasOilServicePlanned(List<Service> services) {
    return services.any(
      (service) =>
          (service.status == ServiceStatus.scheduled ||
              service.status == ServiceStatus.upcoming) &&
          _isOilServiceType(service.serviceType),
    );
  }

  bool _hasRecentCompletedOilService(List<Service> services) {
    final now = DateTime.now();
    return services.any((service) {
      if (service.status != ServiceStatus.completed ||
          !_isOilServiceType(service.serviceType)) {
        return false;
      }

      final daysSinceService = now.difference(service.date.toLocal()).inDays;
      return daysSinceService >= 0 && daysSinceService <= 45;
    });
  }

  bool _isOilServiceType(String serviceType) {
    final normalized = serviceType.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    return normalized.contains('troca de óleo') ||
        normalized.contains('troca de oleo') ||
        (normalized.contains('troca') &&
            (normalized.contains('óleo') || normalized.contains('oleo'))) ||
        normalized.contains('oil change');
  }

  int? _findLastCrossedMilestone(int previousKm, int currentKm) {
    final safePreviousKm = previousKm < 0 ? 0 : previousKm;
    final safeCurrentKm = currentKm < 0 ? 0 : currentKm;

    if (safeCurrentKm < 10000 || safeCurrentKm <= safePreviousKm) {
      return null;
    }

    final firstMilestone = ((safePreviousKm ~/ 10000) + 1) * 10000;
    if (firstMilestone > safeCurrentKm) {
      return null;
    }

    var lastMilestone = firstMilestone;
    for (var km = firstMilestone; km <= safeCurrentKm; km += 10000) {
      lastMilestone = km;
    }

    return lastMilestone;
  }

  Future<void> _markAlertAsRead(String id) async {
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index < 0 || !_alerts[index].unread) {
      return;
    }

    final updated = List<_AlertItem>.from(_alerts);
    updated[index] = updated[index].copyWith(unread: false);

    setState(() {
      _alerts = updated;
    });

    await _persistReadIds(updated);
  }

  Future<void> _markAllAsRead() async {
    final hasUnread = _alerts.any((a) => a.unread);
    if (!hasUnread) {
      AppFeedback.show(
        context,
        message: 'Você já leu todos os alertas.',
        tone: AppFeedbackTone.info,
      );
      return;
    }

    final updated = _alerts.map((a) => a.copyWith(unread: false)).toList();
    setState(() {
      _alerts = updated;
    });

    await _persistReadIds(updated);

    if (!mounted) {
      return;
    }

    AppFeedback.show(
      context,
      message: 'Todos os alertas foram marcados como lidos.',
      tone: AppFeedbackTone.success,
    );
  }

  Future<void> _persistReadIds(List<_AlertItem> alerts) async {
    final readIds = alerts.where((a) => !a.unread).map((a) => a.id).toList();
    _volatileReadIds
      ..clear()
      ..addAll(readIds);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readAlertsKey, readIds);
    } on MissingPluginException {
      // Fallback keeps read status in memory only.
    } catch (_) {
      // Fallback keeps read status in memory only.
    }
  }

  Future<Set<String>> _readPersistedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final persisted = prefs.getStringList(_readAlertsKey) ?? const <String>[];
      _volatileReadIds
        ..clear()
        ..addAll(persisted);
      return persisted.toSet();
    } on MissingPluginException {
      return Set<String>.from(_volatileReadIds);
    } catch (_) {
      return Set<String>.from(_volatileReadIds);
    }
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'agora';
    }
    if (diff.inHours < 1) {
      return 'há ${diff.inMinutes} min';
    }
    if (diff.inDays < 1) {
      return 'há ${diff.inHours} horas';
    }
    if (diff.inDays == 1) {
      return 'ontem';
    }

    return 'há ${diff.inDays} dias';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: _loadAlerts,
          color: AppColors.accent,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.72,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: _loadAlerts,
          color: AppColors.accent,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.72,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 44,
                          color: AppColors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.secondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAlerts,
                          child: const Text('Tentar novamente'),
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

    final unreadCount = _alerts.where((a) => a.unread).length;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAlerts,
        color: AppColors.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fique por dentro do seu carro',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text('Alertas',
                          style: Theme.of(context).textTheme.displayLarge),
                    ],
                  ),
                  if (unreadCount > 0)
                    Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Center(
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary Stats Card
              AppCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NÃO LIDAS', style: AppTheme.sectionLabelStyle),
                          const SizedBox(height: 6),
                          Text(
                            '$unreadCount',
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: -1),
                          ),
                        ],
                      ),
                    ),
                    Container(
                        width: 0.5, height: 40, color: const Color(0x1A3C3C43)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TOTAL', style: AppTheme.sectionLabelStyle),
                            const SizedBox(height: 6),
                            Text(
                              '${_alerts.length}',
                              style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: -1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Section
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 12),
                child: Text('RECENTES', style: AppTheme.sectionLabelStyle),
              ),
              ..._alerts.map((alert) {
                final isUnread = alert.unread;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Opacity(
                    opacity: isUnread ? 1.0 : 0.55,
                    child: GestureDetector(
                      onTap: () => _markAlertAsRead(alert.id),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: alert.iconBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(alert.icon,
                                  size: 15, color: alert.iconColor),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          alert.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                              letterSpacing: -0.1),
                                        ),
                                      ),
                                      if (isUnread) const SizedBox(width: 8),
                                      if (isUnread)
                                        const StatusIndicator(
                                            color: AppColors.accent, size: 7),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    alert.message,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.secondary,
                                        height: 1.5,
                                        letterSpacing: 0.1),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    alert.time,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.quarter,
                                        letterSpacing: 0.2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),

              // Mark All as Read Button
              ElevatedButton(
                onPressed: _markAllAsRead,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                  side: BorderSide.none,
                ),
                child: const Text('Marcar todas como lidas',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertItem {
  final String id;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String message;
  final String time;
  final DateTime timestamp;
  final bool unread;

  const _AlertItem({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.message,
    required this.time,
    required this.timestamp,
    required this.unread,
  });

  _AlertItem copyWith({
    bool? unread,
  }) {
    return _AlertItem(
      id: id,
      icon: icon,
      iconColor: iconColor,
      iconBg: iconBg,
      title: title,
      message: message,
      time: time,
      timestamp: timestamp,
      unread: unread ?? this.unread,
    );
  }
}
