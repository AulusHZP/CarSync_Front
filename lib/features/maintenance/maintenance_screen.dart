import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/list_item.dart';
import '../../widgets/status_indicator.dart';
import '../../models/service.dart';
import '../../services/service_api.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  late Future<ServiceResponse> futureServices;

  @override
  void initState() {
    super.initState();
    futureServices = ServiceApi.getAllServices();
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.completed:
        return AppColors.green;
      case ServiceStatus.scheduled:
        return AppColors.accent;
      case ServiceStatus.upcoming:
        return AppColors.amber;
    }
  }

  Color _getStatusBgColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.completed:
        return const Color(0x1422C55E);
      case ServiceStatus.scheduled:
        return const Color(0x143B82F6);
      case ServiceStatus.upcoming:
        return const Color(0x14F59E0B);
    }
  }

  Future<void> _refreshServices() async {
    final nextFuture = ServiceApi.getAllServices();
    setState(() {
      futureServices = nextFuture;
    });

    try {
      await nextFuture;
    } catch (_) {
      // The error state is rendered by FutureBuilder.
    }
  }

  Future<void> _goToSchedule() async {
    final result = await context.push('/maintenance/schedule');
    if (result == true && mounted) {
      await _refreshServices();
    }
  }

  Future<void> _showServiceQuickTips() async {
    await showModalBottomSheet<void>(
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
                'Checklist para começar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '1. Troca de óleo\n2. Inspeção de freios\n3. Rodízio de pneus',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondary,
                  height: 1.65,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaintenanceEmptyState(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshServices,
      color: AppColors.accent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Histórico e agenda de serviços',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Manutenção',
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x14000000), width: 0.8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    width: 180,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 148,
                          height: 148,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x223B82F6), Color(0x08FFFFFF)],
                            ),
                          ),
                        ),
                        Container(
                          width: 124,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0x11000000),
                              width: 0.8,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 16,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              LucideIcons.car,
                              size: 30,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          right: 30,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.wrench,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF5FF),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0x253B82F6),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.circleCheck,
                                  size: 12,
                                  color: AppColors.accent,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Checklist inicial',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF5FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'PRONTO PARA COMEÇAR',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.45,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Seu carro ainda está sem serviços agendados',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.18,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Agende o primeiro serviço para acompanhar revisões, status e lembretes em uma rotina simples e premium.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.darkGradientStart,
                        AppColors.darkGradientEnd
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x28000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _goToSchedule,
                      child: const SizedBox(
                        height: 54,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.calendar,
                                size: 17, color: Colors.white),
                            SizedBox(width: 9),
                            Text(
                              'Agendar primeiro serviço',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _showServiceQuickTips,
                  icon: const Icon(LucideIcons.info, size: 15),
                  label: const Text('Ver recomendações rápidas'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Dica: comece com troca de óleo para criar seu histórico de manutenção.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<ServiceResponse>(
        future: futureServices,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return RefreshIndicator(
              onRefresh: _refreshServices,
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
            );
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refreshServices,
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
                            Text(
                              'Erro ao carregar serviços',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.secondary),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _refreshServices,
                              child: const Text('Tentar Novamente'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return RefreshIndicator(
              onRefresh: _refreshServices,
              color: AppColors.accent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.72,
                    child: const Center(
                      child: Text('Nenhum serviço encontrado'),
                    ),
                  ),
                ],
              ),
            );
          }

          final response = snapshot.data!;
          final services = response.data;

          if (services.isEmpty) {
            return _buildMaintenanceEmptyState(context);
          }

          final nextService = services.isNotEmpty ? services.first : null;

          return RefreshIndicator(
            onRefresh: _refreshServices,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Histórico e agenda de serviços',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text('Manutenção',
                          style: Theme.of(context).textTheme.displayLarge),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Next Service Card
                  if (nextService != null)
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getStatusBgColor(nextService.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(LucideIcons.calendar,
                                size: 17,
                                color: _getStatusColor(nextService.status)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PRÓXIMO SERVIÇO',
                                    style: AppTheme.sectionLabelStyle),
                                const SizedBox(height: 6),
                                Text(
                                  nextService.serviceType,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                      letterSpacing: -0.2),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Agendado para ${nextService.formattedDate}',
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.secondary),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        _getStatusBgColor(nextService.status),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      StatusIndicator(
                                          color: _getStatusColor(
                                              nextService.status),
                                          size: 5),
                                      const SizedBox(width: 5),
                                      Text(
                                        nextService.status.displayName,
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(
                                                nextService.status)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // All Services List Section
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 12),
                    child: Text('TODOS OS SERVIÇOS',
                        style: AppTheme.sectionLabelStyle),
                  ),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: services.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return GestureDetector(
                          onTap: () async {
                            final result = await context.push(
                              '/maintenance/detail/${item.id}',
                              extra: item,
                            );

                            if (result == true && mounted) {
                              await _refreshServices();
                            }
                          },
                          child: ListItem(
                            icon: LucideIcons.circleCheck,
                            title: item.serviceType,
                            subtitle: item.formattedDate,
                            iconColor: _getStatusColor(item.status),
                            iconBgColor: Colors.transparent,
                            showDivider: index < services.length - 1,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: _getStatusBgColor(item.status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.status.displayName,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _getStatusColor(item.status)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Schedule Service Button
                  ElevatedButton(
                    onPressed: _goToSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 14,
                      shadowColor: Colors.black.withOpacity(0.14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.plus, size: 16),
                        SizedBox(width: 8),
                        Text('Agendar Serviço',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tips Card
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dicas de serviço',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary)),
                        const SizedBox(height: 6),
                        Text(
                          'A manutenção regular mantém o carro funcionando bem e ajuda a evitar reparos caros.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                              height: 1.65,
                              letterSpacing: 0.1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
