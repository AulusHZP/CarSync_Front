import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_card.dart';

class FuelCalculatorScreen extends StatefulWidget {
  const FuelCalculatorScreen({super.key});

  @override
  State<FuelCalculatorScreen> createState() => _FuelCalculatorScreenState();
}

class _FuelCalculatorScreenState extends State<FuelCalculatorScreen> {
  final gasolinaPriceController = TextEditingController();
  final alcoholPriceController = TextEditingController();
  final amountController = TextEditingController();

  double? alcoholRatio;
  bool? alcoholWorth;
  double? gasolinaLiters;
  double? alcoholLiters;

  @override
  void dispose() {
    gasolinaPriceController.dispose();
    alcoholPriceController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void _calculate() {
    final gasolinaPrice = double.tryParse(gasolinaPriceController.text.trim());
    final alcoholPrice = double.tryParse(alcoholPriceController.text.trim());
    final amount = double.tryParse(amountController.text.trim());

    if (gasolinaPrice == null ||
        gasolinaPrice <= 0 ||
        alcoholPrice == null ||
        alcoholPrice <= 0 ||
        amount == null ||
        amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos com valores válidos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      // Calcula a razão: preço álcool / preço gasolina
      alcoholRatio = alcoholPrice / gasolinaPrice;

      // Se razão < 0.7 (70%), álcool compensa
      alcoholWorth = alcoholRatio! < 0.7;

      // Calcula litros
      gasolinaLiters = amount / gasolinaPrice;
      alcoholLiters = amount / alcoholPrice;
    });
  }

  Widget _buildPriceField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.tertiary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0x143C3C43),
                width: 0.8,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0x143C3C43),
                width: 0.8,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accent,
                width: 1,
              ),
            ),
            filled: true,
            fillColor: const Color(0x0A000000),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.card,
                    minimumSize: const Size(38, 38),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calculadora',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text('Combustível',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PREÇOS ATUAIS', style: AppTheme.sectionLabelStyle),
                  const SizedBox(height: 14),
                  _buildPriceField(
                    label: 'Preço Gasolina (R\$/L)',
                    controller: gasolinaPriceController,
                    hint: 'Ex: 5.97',
                  ),
                  const SizedBox(height: 12),
                  _buildPriceField(
                    label: 'Preço Álcool (R\$/L)',
                    controller: alcoholPriceController,
                    hint: 'Ex: 3.49',
                  ),
                  const SizedBox(height: 12),
                  _buildPriceField(
                    label: 'Quanto quer gastar (R\$)',
                    controller: amountController,
                    hint: 'Ex: 150',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  const Icon(LucideIcons.info,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'O álcool rende ~30% menos. Se custar <70% da gasolina, compensa.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 12,
                shadowColor: Colors.black.withOpacity(0.14),
              ),
              child: const Text(
                'Calcular',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            if (alcoholRatio != null && alcoholWorth != null) ...[
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RESULTADO', style: AppTheme.sectionLabelStyle),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: alcoholWorth!
                            ? const Color(0x1422C55E)
                            : const Color(0x143B82F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alcoholWorth!
                                ? '✓ ÁLCOOL COMPENSA'
                                : '✗ GASOLINA É MELHOR',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: alcoholWorth!
                                  ? AppColors.green
                                  : AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Razão de preço: ${(alcoholRatio! * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Com Gasolina',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xF5F5F7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${gasolinaLiters?.toStringAsFixed(2) ?? '0'} L',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'de gasolina',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Com Álcool',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xF5F5F7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${alcoholLiters?.toStringAsFixed(2) ?? '0'} L',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'de álcool',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.secondary,
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
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
