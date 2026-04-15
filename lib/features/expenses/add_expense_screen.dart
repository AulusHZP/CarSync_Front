import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/modern_dropdown.dart';
import '../../services/expense_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // Modern dropdown items with icons
  late final List<ModernDropdownItem> dropdownItems = [
    ModernDropdownItem(
      label: 'Combustível',
      value: 'Combustível',
      icon: LucideIcons.droplets,
    ),
    ModernDropdownItem(
      label: 'Manutenção',
      value: 'Manutenção',
      icon: LucideIcons.wrench,
    ),
    ModernDropdownItem(
      label: 'Seguro',
      value: 'Seguro',
      icon: LucideIcons.shield,
    ),
    ModernDropdownItem(
      label: 'Lava-rápido',
      value: 'Lava-rápido',
      icon: LucideIcons.sun,
    ),
    ModernDropdownItem(
      label: 'Estacionamento',
      value: 'Estacionamento',
      icon: LucideIcons.squareParking,
    ),
    ModernDropdownItem(
      label: 'Pedágio',
      value: 'Pedágio',
      icon: LucideIcons.ticketSlash,
    ),
    ModernDropdownItem(
      label: 'Outro',
      value: 'Outro',
      icon: LucideIcons.ellipsis,
    ),
  ];

  String? selectedCategory;
  final amountController = TextEditingController();
  final litersController = TextEditingController();
  final pricePerLiterController = TextEditingController();
  String? selectedFuelType = 'Gasolina';

  final fuelTypes = ['Gasolina', 'Diesel', 'Álcool'];

  @override
  void dispose() {
    amountController.dispose();
    litersController.dispose();
    pricePerLiterController.dispose();
    super.dispose();
  }

  Widget _buildCategoryDropdown() {
    return ModernDropdown(
      selectedValue: selectedCategory,
      items: dropdownItems,
      hint: 'Selecione uma categoria',
      label: 'Categoria',
      onChanged: (value) {
        setState(() {
          selectedCategory = value;
        });
      },
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Valor (R\$)',
            style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
        const SizedBox(height: 6),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Ex: 85',
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

  Widget _buildFuelTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo de Combustível',
            style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0x143C3C43),
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            value: selectedFuelType,
            isExpanded: true,
            underline: const SizedBox(),
            items: fuelTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedFuelType = newValue ?? 'Gasolina';
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLitersField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Litros',
            style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
        const SizedBox(height: 6),
        TextField(
          controller: litersController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Ex: 45.5',
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

  Widget _buildPricePerLiterField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preço por Litro (R\$)',
            style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
        const SizedBox(height: 6),
        TextField(
          controller: pricePerLiterController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Ex: 5.89',
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

  void _addExpense() async {
    final amount = double.tryParse(amountController.text.trim());

    if (selectedCategory == null ||
        selectedCategory!.isEmpty ||
        amount == null ||
        amount <= 0) {
      AppFeedback.show(
        context,
        message: 'Preencha categoria e valor válido.',
        tone: AppFeedbackTone.warning,
      );
      return;
    }

    // Additional validation for fuel category
    double? liters;
    double? pricePerLiter;

    if (selectedCategory == 'Combustível') {
      liters = double.tryParse(litersController.text.trim());
      pricePerLiter = double.tryParse(pricePerLiterController.text.trim());

      if (liters == null ||
          liters <= 0 ||
          pricePerLiter == null ||
          pricePerLiter <= 0) {
        AppFeedback.show(
          context,
          message:
              'Preencha litros e preço do combustível com valores válidos.',
          tone: AppFeedbackTone.warning,
        );
        return;
      }
    }

    try {
      await ExpenseService.createExpense(
        category: selectedCategory!,
        amount: amount,
        fuelType: selectedFuelType,
        liters: liters,
        pricePerLiter: pricePerLiter,
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      AppFeedback.show(
        context,
        message: 'Erro ao adicionar gasto: $e',
        tone: AppFeedbackTone.error,
      );
    }
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
                    Text('Março 2026',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text('Adicionar Gasto',
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
                  Text('DETALHES DO GASTO', style: AppTheme.sectionLabelStyle),
                  const SizedBox(height: 14),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 12),
                  _buildAmountField(),
                  if (selectedCategory == 'Combustível') ...[
                    const SizedBox(height: 12),
                    _buildFuelTypeDropdown(),
                    const SizedBox(height: 12),
                    _buildLitersField(),
                    const SizedBox(height: 12),
                    _buildPricePerLiterField(),
                  ],
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
                      'O gasto será adicionado ao seu histórico imediatamente.',
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
              onPressed: _addExpense,
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
                'Adicionar Gasto',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
