import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/dark_card.dart';
import '../../widgets/progress_bar.dart';
import '../../services/expense_service.dart';
import 'add_expense_screen.dart';

class ExpenseItem {
  final String id;
  final String category;
  final double amount;
  final DateTime createdAt;
  final IconData icon;
  final Color color;
  final Color iconBg;
  final String? fuelType;
  final double? liters;
  final double? pricePerLiter;

  const ExpenseItem({
    required this.id,
    required this.category,
    required this.amount,
    required this.createdAt,
    required this.icon,
    required this.color,
    required this.iconBg,
    this.fuelType,
    this.liters,
    this.pricePerLiter,
  });
}

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<ExpenseItem> _expenses = [];
  bool _isLoading = true;
  String? _errorMessage;
  final DateTime _referenceMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final expensesData = await ExpenseService.getExpenses();
      final loadedExpenses = <ExpenseItem>[];
      final monthStart =
          DateTime(_referenceMonth.year, _referenceMonth.month, 1);
      final nextMonthStart =
          DateTime(_referenceMonth.year, _referenceMonth.month + 1, 1);

      for (var item in expensesData) {
        final createdAtRaw = item['createdAt']?.toString();
        final createdAt = createdAtRaw != null
            ? DateTime.tryParse(createdAtRaw)?.toLocal()
            : null;

        // Only include expenses from the selected month.
        if (createdAt == null ||
            createdAt.isBefore(monthStart) ||
            !createdAt.isBefore(nextMonthStart)) {
          continue;
        }

        final category = item['categoryLabel'] ?? item['category'] ?? 'Outro';
        final style = _categoryStyle(category);
        loadedExpenses.add(
          ExpenseItem(
            id: item['id'] ?? '',
            category: category,
            amount: (item['amount'] ?? 0).toDouble(),
            createdAt: createdAt,
            icon: style.$1,
            color: style.$2,
            iconBg: style.$3,
            fuelType: item['fuelType'] as String?,
            liters: (item['liters'] as num?)?.toDouble(),
            pricePerLiter: (item['pricePerLiter'] as num?)?.toDouble(),
          ),
        );
      }

      setState(() {
        _expenses = loadedExpenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar gastos: $e';
        _isLoading = false;
      });
    }
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _shortMonthLabel(DateTime date) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    return months[date.month - 1];
  }

  List<Map<String, dynamic>> _buildMonthlyTrendData(double currentMonthTotal) {
    final months = List<DateTime>.generate(
      4,
      (index) => DateTime(
        _referenceMonth.year,
        _referenceMonth.month - (3 - index),
        1,
      ),
    );

    return months.asMap().entries.map((entry) {
      final index = entry.key;
      final month = entry.value;
      final isCurrent = index == months.length - 1;
      final value = isCurrent ? currentMonthTotal : 0.0;

      return {
        'month': _shortMonthLabel(month),
        'value': value,
        'current': isCurrent,
      };
    }).toList();
  }

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

  void _removeExpense(ExpenseItem expense) async {
    final confirmed = await AppFeedback.confirmDestructive(
      context,
      title: 'Excluir gasto?',
      message: 'Essa ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
    );

    if (!confirmed || !mounted) {
      return;
    }

    final originalExpenses = [..._expenses];

    // Remove locally first for optimistic update
    setState(() {
      _expenses.removeWhere((e) => e.id == expense.id);
    });

    try {
      await ExpenseService.deleteExpense(expense.id);

      AppFeedback.show(
        context,
        message: '${expense.category} removido',
        tone: AppFeedbackTone.info,
        actionLabel: 'Desfazer',
        onAction: () {
          try {
            setState(() {
              _expenses.insert(0, expense);
            });
          } catch (e) {
            AppFeedback.show(
              context,
              message: 'Erro ao desfazer: $e',
              tone: AppFeedbackTone.error,
            );
          }
        },
      );
    } catch (e) {
      // Restore the original list if deletion failed
      setState(() {
        _expenses = originalExpenses;
      });

      AppFeedback.show(
        context,
        message: 'Erro ao remover gasto: $e',
        tone: AppFeedbackTone.error,
      );
    }
  }

  void _goToAddExpense() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    )
        .then((result) {
      if (result == true) {
        _loadExpenses();
        AppFeedback.show(
          context,
          message: 'Gasto adicionado com sucesso.',
          tone: AppFeedbackTone.success,
        );
      }
    });
  }

  Future<void> _exportToPDF() async {
    try {
      await initializeDateFormatting('pt_BR');

      final total = _expenses.fold(0.0, (sum, e) => sum + e.amount);
      final monthFormat = DateFormat('MMMM/yyyy', 'pt_BR');
      final dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
      final regularFont = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          theme: pw.ThemeData.withFont(
            base: regularFont,
            bold: boldFont,
          ),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Relatório de Gastos',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Período: ${monthFormat.format(_referenceMonth)}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Total do Mês',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'R\$ ${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Detalhamento',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              if (_expenses.isEmpty)
                pw.Text(
                  'Nenhum gasto cadastrado neste mês',
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Data',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Categoria',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Valor',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ..._expenses.map(
                      (e) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              dateFormat.format(e.createdAt),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              e.category,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'R\$ ${e.amount.toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (_) => pdf.save());
    } catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          message: 'Erro ao exportar PDF: $e',
          tone: AppFeedbackTone.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: _loadExpenses,
          color: AppColors.accent,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.72,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Carregando gastos...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
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
          onRefresh: _loadExpenses,
          color: AppColors.accent,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.72,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadExpenses,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                        ),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = _expenses.fold(0.0, (sum, e) => sum + e.amount);
    const previousMonthTotal = 390.0;
    final deltaPercent =
        ((total - previousMonthTotal).abs() / previousMonthTotal * 100).round();
    final lowerThanPreviousMonth = total <= previousMonthTotal;

    final chartData = _buildMonthlyTrendData(total);
    final chartMax = chartData.fold<double>(
      0,
      (maxValue, item) {
        final value = item['value'] as double;
        return value > maxValue ? value : maxValue;
      },
    );

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
      body: RefreshIndicator(
        onRefresh: _loadExpenses,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_monthLabel(_referenceMonth),
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text('Gastos',
                          style: Theme.of(context).textTheme.displayLarge),
                    ],
                  ),
                  IconButton.filled(
                    onPressed: _exportToPDF,
                    icon: const Icon(LucideIcons.fileText, size: 20),
                    tooltip: 'Exportar PDF',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.card,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
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
                          total.toStringAsFixed(2),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                                      child: Icon(e.icon,
                                          size: 15, color: e.color),
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
                                    'R\$${e.amount.toStringAsFixed(2)}',
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
                          if (e.category == 'Combustível' &&
                              (e.fuelType != null || e.liters != null)) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xF5F5F7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (e.fuelType != null)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Tipo:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          e.fuelType!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (e.liters != null) ...[
                                    if (e.fuelType != null)
                                      const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Litros:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${e.liters!.toStringAsFixed(2)} L',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (e.pricePerLiter != null) ...[
                                    if (e.fuelType != null || e.liters != null)
                                      const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Preço/L:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'R\$${e.pricePerLiter!.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
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
                      final value = item['value'] as double;
                      final heightPct = chartMax > 0 ? value / chartMax : 0.0;
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
                                fontWeight: isCurrent
                                    ? FontWeight.w600
                                    : FontWeight.w400,
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
      ),
    );
  }
}
