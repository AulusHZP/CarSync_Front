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

  @override
  void dispose() {
    amountController.dispose();
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

    try {
      await ExpenseService.createExpense(
        category: selectedCategory!,
        amount: amount,
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
