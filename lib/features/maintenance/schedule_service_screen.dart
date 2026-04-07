import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_feedback.dart';
import '../../services/service_api.dart';

class ScheduleServiceScreen extends StatefulWidget {
  const ScheduleServiceScreen({super.key});

  @override
  State<ScheduleServiceScreen> createState() => _ScheduleServiceScreenState();
}

class _ScheduleServiceScreenState extends State<ScheduleServiceScreen> {
  late TextEditingController serviceTypeController;
  late TextEditingController dateController;
  late TextEditingController descriptionController;
  bool isLoading = false;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    serviceTypeController = TextEditingController(text: 'Troca de óleo');
    selectedDate = DateTime.now().add(const Duration(days: 7));
    dateController = TextEditingController(
      text:
          '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}',
    );
    descriptionController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    serviceTypeController.dispose();
    dateController.dispose();
    descriptionController.dispose();
    super.dispose();
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
                  onPressed: () => context.pop(),
                  icon: const Icon(LucideIcons.arrowLeft, size: 18),
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
                    Text('Manutenção',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text('Agendar Serviço',
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
                  Text('DETALHES DO SERVIÇO',
                      style: AppTheme.sectionLabelStyle),
                  const SizedBox(height: 14),
                  _buildEditableField(
                    label: 'Tipo de serviço',
                    controller: serviceTypeController,
                    icon: LucideIcons.wrench,
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.secondary)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickDate,
                        child: TextFormField(
                          controller: dateController,
                          enabled: false,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(LucideIcons.calendar,
                                size: 18, color: AppColors.secondary),
                            filled: true,
                            fillColor: const Color(0x0A000000),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0x143C3C43), width: 0.8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0x143C3C43), width: 0.8),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0x143C3C43), width: 0.8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDescriptionField(),
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
                      'O agendamento será confirmado por notificação em alguns minutos.',
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
              onPressed: isLoading ? null : _submitForm,
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
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Confirmar Agendamento',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (serviceTypeController.text.isEmpty) {
      AppFeedback.show(
        context,
        message: 'Por favor, preencha o tipo de serviço.',
        tone: AppFeedbackTone.warning,
      );
      return;
    }

    if (selectedDate == null) {
      AppFeedback.show(
        context,
        message: 'Por favor, selecione uma data.',
        tone: AppFeedbackTone.warning,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await ServiceApi.createService(
        serviceType: serviceTypeController.text,
        date: selectedDate!,
        notes: descriptionController.text,
      );

      if (mounted) {
        AppFeedback.show(
          context,
          message: 'Serviço agendado com sucesso.',
          tone: AppFeedbackTone.success,
        );
        context.pop(true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          message: 'Erro ao agendar: ${e.toString()}',
          tone: AppFeedbackTone.error,
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: AppColors.primary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.card,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.secondary),
            filled: true,
            fillColor: const Color(0x0A000000),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0x143C3C43), width: 0.8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0x143C3C43), width: 0.8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Descrição',
            style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: descriptionController,
          maxLines: 4,
          minLines: 3,
          decoration: InputDecoration(
            hintText: 'Adicione observações ou detalhes do serviço...',
            hintStyle: TextStyle(
                fontSize: 13, color: AppColors.secondary.withOpacity(0.6)),
            filled: true,
            fillColor: const Color(0x0A000000),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0x143C3C43), width: 0.8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0x143C3C43), width: 0.8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
