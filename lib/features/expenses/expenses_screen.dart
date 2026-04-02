import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dark_card.dart';
import '../../widgets/progress_bar.dart';
import 'add_expense_screen.dart';

class ExpenseItem {
  final int id;
  final String category;
  final int amount;
  final IconData icon;
  final Color color;
  final Color iconBg;

  const ExpenseItem({
    required this.id,
    required this.category,
    required this.amount,
    required this.icon,
    required this.color,
    required this.iconBg,
  });
}

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final List<ExpenseItem> _expenses = [
    const ExpenseItem(
      id: 1,
      category: 'Combustível',
      amount: 156,
      icon: LucideIcons.droplet,
      color: AppColors.accent,
      iconBg: Color(0x143B82F6),
    ),
    const ExpenseItem(
      id: 2,
      category: 'Manutenção',
      amount: 120,
      icon: LucideIcons.wrench,
      color: AppColors.amber,
      iconBg: Color(0x14F59E0B),
    ),
    const ExpenseItem(
      id: 3,
      category: 'Seguro',
      amount: 66,
      icon: LucideIcons.shield,
      color: AppColors.green,
      iconBg: Color(0x1422C55E),
    ),
  ];

  int _nextId = 4;

  (IconData, Color, Color) _categoryStyle(String category) {
    switch (category.toLowerCase()) {
      case 'combustível':
      case 'combustivel':
        return (LucideIcons.droplet, AppColors.accent, const Color(0x143B82F6));
      case 'manutenção':
      case 'manutencao':
        return (LucideIcons.wrench, AppColors.amber, const Color(0x14F59E0B));
      case 'seguro':
        return (LucideIcons.shield, AppColors.green, const Color(0x1422C55E));
      default:
        return (
          LucideIcons.receipt,
          AppColors.primary,
          const Color(0x0A000000)
        );
    }
  }

  void _addExpense({required String category, required int amount}) {
    final trimmedCategory = category.trim();
    if (trimmedCategory.isEmpty || amount <= 0) {
      return;
    }

    final style = _categoryStyle(trimmedCategory);
    setState(() {
      _expenses.insert(
        0,
        ExpenseItem(
          id: _nextId++,
          category: trimmedCategory,
          amount: amount,
          icon: style.$1,
          color: style.$2,
          iconBg: style.$3,
        ),
      );
    });
  }

  void _removeExpense(ExpenseItem expense) {
    setState(() {
      _expenses.removeWhere((e) => e.id == expense.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${expense.category} removido'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () {
            setState(() {
              _expenses.insert(0, expense);
            });
          },
        ),
      ),
    );
  }

  void _goToAddExpense() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          onAddExpense: (category, amount) {
            _addExpense(category: category, amount: amount);
          },
        ),
      ),
    )
        .then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _expenses.fold(0, (sum, e) => sum + e.amount);
    const previousMonthTotal = 390;
    final deltaPercent =
        ((total - previousMonthTotal).abs() / previousMonthTotal * 100).round();
    final lowerThanPreviousMonth = total <= previousMonthTotal;

    final chartData = [
      {'month': 'Dez', 'value': 280, 'current': false},
      {'month': 'Jan', 'value': 320, 'current': false},
      {'month': 'Fev', 'value': 298, 'current': false},
      {'month': 'Mar', 'value': 342, 'current': true},
    ];
    const chartMax = 380;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToAddExpense,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text(
          'Adicionar',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Março 2026',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text('Gastos', style: Theme.of(context).textTheme.displayLarge),
              ],
            ),
            const SizedBox(height: 24),

            // Total Monthly Card
            DarkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL DO MES',
                      style: AppTheme.sectionLabelStyle
                          .copyWith(color: const Color(0xCCFFFFFF))),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10, right: 2),
                        child: Text(r'R$',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Color(0xCCFFFFFF))),
                      ),
                      Text(
                        '$total',
                        style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                            letterSpacing: -2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          lowerThanPreviousMonth
                              ? LucideIcons.trendingDown
                              : LucideIcons.trendingUp,
                          size: 13,
                          color: lowerThanPreviousMonth
                              ? AppColors.green
                              : AppColors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$deltaPercent% ${lowerThanPreviousMonth ? 'menor' : 'maior'} que no mês passado',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: lowerThanPreviousMonth
                                ? AppColors.green
                                : AppColors.red,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Breakdown Section
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 12),
              child: Text('DETALHAMENTO', style: AppTheme.sectionLabelStyle),
            ),
            if (_expenses.isEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nenhum gasto cadastrado',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Toque em Adicionar para criar seu primeiro gasto.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
              )
            else
              ..._expenses.map((e) {
                final pct = total > 0
                    ? (e.amount / total * 100).toStringAsFixed(0)
                    : '0';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: e.iconBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child:
                                        Icon(e.icon, size: 15, color: e.color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      e.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'R\$${e.amount}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                      letterSpacing: -0.3),
                                ),
                                Text('$pct%',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.quarter)),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2,
                                  size: 16, color: AppColors.secondary),
                              onPressed: () => _removeExpense(e),
                              tooltip: 'Remover',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ProgressBar(
                          value: total > 0 ? e.amount / total : 0,
                          color: e.color.withOpacity(0.8),
                          height: 2,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 14),

            // Monthly Trend Section
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 12),
              child:
                  Text('TENDENCIA MENSAL', style: AppTheme.sectionLabelStyle),
            ),
            AppCard(
              child: SizedBox(
                height: 88,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: chartData.map((item) {
                    final heightPct = (item['value'] as int) / chartMax;
                    final isCurrent = item['current'] as bool;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: FractionallySizedBox(
                                heightFactor: heightPct,
                                widthFactor: 1.0,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? AppColors.accent
                                        : AppColors.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['month'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isCurrent ? FontWeight.w600 : FontWeight.w400,
                              color: isCurrent
                                  ? AppColors.accent
                                  : AppColors.quarter,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
