import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dark_card.dart';
import '../../widgets/status_indicator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status do seu veículo', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text('Meu Carro', style: Theme.of(context).textTheme.displayLarge),
                ],
              ),
              const SizedBox(height: 24),
            DarkCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SAÚDE DO CARRO',
                    style: AppTheme.sectionLabelStyle.copyWith(color: const Color(0xCCFFFFFF)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '92',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          '%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            color: Color(0xB3FFFFFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const StatusIndicator(color: AppColors.green, size: 5),
                      const SizedBox(width: 6),
                      Text(
                        'Excelente estado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.green,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0x14FFFFFF), width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.circleCheck, size: 16, color: AppColors.amber),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Próxima revisão',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Troca de óleo em 12 dias',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color.fromARGB(0xCC, 0xFF, 0xFF, 0xFF),
                                  letterSpacing: 0.1,
                                ),
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
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0x143B82F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(LucideIcons.droplet, size: 18, color: AppColors.accent),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Combustível no mês',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'R\$ 680',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total abastecido em Março',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0x1422C55E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.dollarSign, size: 16, color: Color(0xFF22C55E)),
                        ),
                        const SizedBox(height: 14),
                        Text('MENSAL', style: AppTheme.sectionLabelStyle),
                        const SizedBox(height: 8),
                        const Text(
                          'R\$342',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0x14F59E0B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.gauge, size: 16, color: AppColors.amber),
                        ),
                        const SizedBox(height: 14),
                        Text('QUILOMETRAGEM', style: AppTheme.sectionLabelStyle),
                        const SizedBox(height: 8),
                        const Text(
                          '24.5k',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              borderRadius: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status da manutenção',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Todos os sistemas operando',
                          style: TextStyle(fontSize: 11, color: AppColors.secondary, letterSpacing: 0.2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0x1422C55E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.circleCheck, size: 16, color: AppColors.green),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
