import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/list_item.dart';
import '../../widgets/status_indicator.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'id': 1,
        'title': 'Troca de óleo',
        'date': 'Concluído em 12 Mar 2026',
        'status': 'completed',
        'dotColor': AppColors.green,
        'badgeColor': AppColors.green,
        'badgeBg': const Color(0x1422C55E),
        'badge': 'Concluído',
      },
      {
        'id': 2,
        'title': 'Rodízio de pneus',
        'date': 'Vence em 6 Abr 2026',
        'status': 'upcoming',
        'dotColor': AppColors.amber,
        'badgeColor': AppColors.amber,
        'badgeBg': const Color(0x14F59E0B),
        'badge': 'Em breve',
      },
      {
        'id': 3,
        'title': 'Inspeção dos freios',
        'date': 'Vence em 20 Mai 2026',
        'status': 'scheduled',
        'dotColor': AppColors.accent,
        'badgeColor': AppColors.accent,
        'badgeBg': const Color(0x143B82F6),
        'badge': 'Agendado',
      },
      {
        'id': 4,
        'title': 'Troca do filtro de ar',
        'date': 'Vence em 15 Jun 2026',
        'status': 'scheduled',
        'dotColor': AppColors.quarter,
        'badgeColor': AppColors.secondary,
        'badgeBg': const Color(0x0A000000),
        'badge': 'Agendado',
      },
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Histórico e agenda de serviços', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text('Manutenção', style: Theme.of(context).textTheme.displayLarge),
              ],
            ),
            const SizedBox(height: 24),

            // Next Service Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x14F59E0B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.calendar, size: 17, color: AppColors.amber),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PRÓXIMO SERVIÇO', style: AppTheme.sectionLabelStyle),
                        const SizedBox(height: 6),
                        const Text(
                          'Rodízio de pneus',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary, letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 3),
                        Text('Agendado para 6 Abr 2026', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0x14F59E0B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const StatusIndicator(color: AppColors.amber, size: 5),
                              const SizedBox(width: 5),
                              const Text(
                                'Em 12 dias',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.amber),
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
              child: Text('TODOS OS SERVIÇOS', style: AppTheme.sectionLabelStyle),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return ListItem(
                    icon: LucideIcons.circleCheck, // Simplified for brevity, usually custom per item
                    title: item['title'] as String,
                    subtitle: item['date'] as String,
                    iconColor: item['dotColor'] as Color,
                    iconBgColor: Colors.transparent, // We'll use the dot instead
                    showDivider: index < items.length - 1,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: item['badgeBg'] as Color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item['badge'] as String,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: item['badgeColor'] as Color),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Schedule Service Button
            ElevatedButton(
              onPressed: () => context.push('/maintenance/schedule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 14,
                shadowColor: Colors.black.withOpacity(0.14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.plus, size: 16),
                  SizedBox(width: 8),
                  Text('Agendar Serviço', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tips Card
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dicas de serviço', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Text(
                    'A manutenção regular mantém o carro funcionando bem e ajuda a evitar reparos caros.',
                    style: TextStyle(fontSize: 12, color: AppColors.secondary, height: 1.65, letterSpacing: 0.1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
