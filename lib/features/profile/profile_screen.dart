import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dark_card.dart';
import '../../widgets/list_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsItems = [
      {
        'id': 1,
        'icon': LucideIcons.bell,
        'label': 'Notificações',
        'value': 'Ativo',
        'iconColor': AppColors.amber,
        'iconBg': const Color(0x14F59E0B),
      },
      {
        'id': 2,
        'icon': LucideIcons.shield,
        'label': 'Privacidade',
        'value': '',
        'iconColor': AppColors.accent,
        'iconBg': const Color(0x143B82F6),
      },
      {
        'id': 3,
        'icon': LucideIcons.circleCheck,
        'label': 'Ajuda e suporte',
        'value': '',
        'iconColor': AppColors.green,
        'iconBg': const Color(0x1422C55E),
      },
      {
        'id': 4,
        'icon': LucideIcons.settings,
        'label': 'Configurações do app',
        'value': '',
        'iconColor': AppColors.secondary,
        'iconBg': const Color(0x0A000000),
      },
    ];

    final carDetails = [
      {'label': 'Marca e modelo', 'value': 'Tesla Model 3'},
      {'label': 'Ano', 'value': '2024'},
      {'label': 'Placa', 'value': 'ABC-1234'},
      {'label': 'VIN', 'value': '5YJ3E1EA…8392'},
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
                Text('Gerencie sua conta', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text('Perfil', style: Theme.of(context).textTheme.displayLarge),
              ],
            ),
            const SizedBox(height: 24),

            // User Hero Card
            DarkCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'JD',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'John Doe',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.3),
                          ),
                          SizedBox(height: 3),
                          Text('john.doe@email.com', style: TextStyle(fontSize: 12, color: Color(0xB3FFFFFF))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0x17FFFFFF),
                      foregroundColor: Colors.white.withOpacity(0.85),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0x1AFFFFFF), width: 0.5),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Editar perfil', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: -0.1)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // My Car Section
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 12),
              child: Text('MEU CARRO', style: AppTheme.sectionLabelStyle),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0x0A000000),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(LucideIcons.car, size: 15, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Tesla Model 3',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary, letterSpacing: -0.2),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0.5, indent: 20, endIndent: 20),
                  ...carDetails.asMap().entries.map((entry) {
                    final index = entry.key;
                    final d = entry.value;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(d['label']!, style: const TextStyle(fontSize: 13, color: AppColors.secondary)),
                              Text(d['value']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary, letterSpacing: -0.1)),
                            ],
                          ),
                        ),
                        if (index < carDetails.length - 1)
                          const Divider(height: 0.5, indent: 20, endIndent: 20, color: Color(0x0F3C3C43)),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Section
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 12),
              child: Text('CONFIGURAÇÕES', style: AppTheme.sectionLabelStyle),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: settingsItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return ListItem(
                    icon: item['icon'] as IconData,
                    title: item['label'] as String,
                    subtitle: (item['value'] as String).isNotEmpty ? item['value'] as String : null,
                    iconColor: item['iconColor'] as Color,
                    iconBgColor: item['iconBg'] as Color,
                    showChevron: true,
                    showDivider: index < settingsItems.length - 1,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Log Out Button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.card,
                foregroundColor: AppColors.red,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.logOut, size: 15),
                  SizedBox(width: 8),
                  Text('Sair', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: -0.1)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Version
            const Center(
              child: Text(
                'CarSync v1.0.0',
                style: TextStyle(fontSize: 10, color: AppColors.quarter, letterSpacing: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
