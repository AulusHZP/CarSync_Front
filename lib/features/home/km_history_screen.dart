import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import '../../services/vehicle_profile_service.dart';
import '../../widgets/app_feedback.dart';

class KmHistoryScreen extends StatefulWidget {
  final String vehicleName;
  final String? vehiclePlate;

  const KmHistoryScreen({
    super.key,
    required this.vehicleName,
    this.vehiclePlate,
  });

  @override
  State<KmHistoryScreen> createState() => _KmHistoryScreenState();
}

class _KmHistoryScreenState extends State<KmHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  VehicleProfileData? _activeVehicle;
  List<KmHistoryEntry> _entries = const <KmHistoryEntry>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final profile = await VehicleProfileService.getProfile();
      final entries = await VehicleProfileService.listKmHistory(
        plate: widget.vehiclePlate ?? profile?.plate,
        limit: 60,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _activeVehicle = profile;
        _entries = entries;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Nao foi possivel carregar o histórico agora.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddKm() async {
    final profile = _activeVehicle;
    if (profile == null) {
      AppFeedback.show(
        context,
        message: 'Cadastre um veículo antes de adicionar KM.',
        tone: AppFeedbackTone.warning,
      );
      return;
    }

    final newTotalKm = await Navigator.of(context).push<int>(
      PageRouteBuilder<int>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => _AddKmEntryScreen(
          currentTotalKm: profile.totalKm,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );

    if (newTotalKm == null) {
      return;
    }

    await VehicleProfileService.saveMonthlyKm(totalKm: newTotalKm);
    await _loadHistory();

    if (!mounted) {
      return;
    }

    AppFeedback.show(
      context,
      message: 'KM adicionada com sucesso.',
      tone: AppFeedbackTone.success,
    );
  }

  String _subtitle() {
    final model = _activeVehicle?.model.trim();
    final plate = _activeVehicle?.plate.trim();

    if (model != null && model.isNotEmpty && plate != null && plate.isNotEmpty) {
      return '$model • $plate';
    }

    if (model != null && model.isNotEmpty) {
      return model;
    }

    return widget.vehicleName;
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Histórico de Quilometragem',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          color: AppColors.accent,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                _subtitle(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondary,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 18),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: _HistoryEmptyState(
                    icon: LucideIcons.triangleAlert,
                    title: _error!,
                    subtitle: 'Puxe para baixo para tentar novamente.',
                  ),
                )
              else if (_entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: _HistoryEmptyState(
                    icon: LucideIcons.gauge,
                    title: 'Nenhum registro ainda',
                    subtitle: 'Toque em Adicionar KM para criar o primeiro.',
                  ),
                )
              else
                ..._entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final previous =
                      index + 1 < _entries.length ? _entries[index + 1] : null;
                  final delta = previous != null ? item.totalKm - previous.totalKm : null;

                  final duration = Duration(
                    milliseconds: 220 + ((index * 38) > 260 ? 260 : (index * 38)),
                  );

                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 14),
                          child: child,
                        ),
                      );
                    },
                    child: _HistoryTimelineItem(
                      isLast: index == _entries.length - 1,
                      totalKm: item.totalKm,
                      dateText: _formatDate(item.recordedAt),
                      deltaKm: delta,
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddKm,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(LucideIcons.plus, size: 16),
        label: const Text(
          'Adicionar KM',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _HistoryTimelineItem extends StatelessWidget {
  final bool isLast;
  final int totalKm;
  final String dateText;
  final int? deltaKm;

  const _HistoryTimelineItem({
    required this.isLast,
    required this.totalKm,
    required this.dateText,
    required this.deltaKm,
  });

  String _formatKm(int value) {
    return VehicleProfileService.formatKm(value);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 34,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: const Color(0x14000000),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.gauge,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatKm(totalKm),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (deltaKm != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: deltaKm! >= 0
                            ? const Color(0x1622C55E)
                            : const Color(0x16EF4444),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${deltaKm! >= 0 ? '+' : '-'}${_formatKm(deltaKm!.abs())}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              deltaKm! >= 0 ? AppColors.green : AppColors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HistoryEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 30, color: AppColors.secondary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddKmEntryScreen extends StatefulWidget {
  final int currentTotalKm;

  const _AddKmEntryScreen({required this.currentTotalKm});

  @override
  State<_AddKmEntryScreen> createState() => _AddKmEntryScreenState();
}

class _AddKmEntryScreenState extends State<_AddKmEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kmController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _kmController.text = widget.currentTotalKm.toString();
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final km = int.parse(_kmController.text.replaceAll(RegExp(r'[^0-9]'), ''));

    setState(() => _isSaving = true);
    await HapticFeedback.lightImpact();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(km);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Adicionar KM',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Última KM registrada: ${VehicleProfileService.formatKm(widget.currentTotalKm)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _kmController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(7),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Ex.: 99000',
                    filled: true,
                    fillColor: const Color(0xFFF5F6F8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0x333B82F6),
                        width: 1,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.isEmpty) {
                      return 'Informe a KM total';
                    }
                    final km = int.tryParse(digits);
                    if (km == null || km < 0) {
                      return 'KM inválida';
                    }
                    if (km < widget.currentTotalKm) {
                      return 'A KM nao pode ser menor que a anterior';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Salvar KM',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
