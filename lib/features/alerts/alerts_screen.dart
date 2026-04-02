import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_indicator.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = [
      {
        'id': 1,
        'icon': LucideIcons.circleAlert,
        'iconColor': AppColors.amber,
        'iconBg': const Color(0x14F59E0B),
        'title': 'Manutenção em breve',
        'message': 'Rodízio de pneus agendado em 12 dias',
        'time': 'há 2 horas',
        'unread': true,
      },
      {
        'id': 2,
        'icon': LucideIcons.trendingUp,
        'iconColor': AppColors.accent,
        'iconBg': const Color(0x143B82F6),
        'title': 'Consumo de combustível aumentou',
        'message': '15% maior que o normal nesta semana',
        'time': 'Ontem',
        'unread': true,
      },
      {
        'id': 3,
        'icon': LucideIcons.circleCheck,
        'iconColor': AppColors.green,
        'iconBg': const Color(0x1422C55E),
        'title': 'Serviço concluído',
        'message': 'Troca de óleo concluída com sucesso',
        'time': 'há 2 dias',
        'unread': false,
      },
      {
        'id': 4,
        'icon': LucideIcons.info,
        'iconColor': AppColors.secondary,
        'iconBg': const Color(0x0A000000),
        'title': 'Renovação do seguro',
        'message': 'Apólice renova em 45 dias',
        'time': 'há 3 dias',
        'unread': false,
      },
    ];

    final unreadCount = alerts.where((a) => a['unread'] as bool).length;

    return Scaffold(
      body: SingleChildScrollView(
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
                    Text('Fique por dentro do seu carro', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text('Alertas', style: Theme.of(context).textTheme.displayLarge),
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
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary Stats Card
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: -1),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 0.5, height: 40, color: const Color(0x1A3C3C43)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL', style: AppTheme.sectionLabelStyle),
                          const SizedBox(height: 6),
                          Text(
                            '${alerts.length}',
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: -1),
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
            ...alerts.map((alert) {
              final isUnread = alert['unread'] as bool;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Opacity(
                  opacity: isUnread ? 1.0 : 0.55,
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: alert['iconBg'] as Color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(alert['icon'] as IconData, size: 15, color: alert['iconColor'] as Color),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      alert['title'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary, letterSpacing: -0.1),
                                    ),
                                  ),
                                  if (isUnread) const SizedBox(width: 8),
                                  if (isUnread)
                                    const StatusIndicator(color: AppColors.accent, size: 7),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                alert['message'] as String,
                                style: TextStyle(fontSize: 12, color: AppColors.secondary, height: 1.5, letterSpacing: 0.1),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                alert['time'] as String,
                                style: TextStyle(fontSize: 10, color: AppColors.quarter, letterSpacing: 0.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24),

            // Mark All as Read Button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.card,
                foregroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
                side: BorderSide.none,
              ),
              child: const Text('Marcar todas como lidas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: -0.1)),
            ),
          ],
        ),
      ),
    );
  }
}
