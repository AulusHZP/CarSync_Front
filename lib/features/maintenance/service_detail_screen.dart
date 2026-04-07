import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_feedback.dart';
import '../../models/service.dart';
import '../../services/service_api.dart';

class ServiceDetail {
  final String title;
  final String description;

  ServiceDetail({required this.title, required this.description});
}

final Map<String, ServiceDetail> serviceDetails = {
  'Troca de óleo': ServiceDetail(
    title: 'Troca de óleo',
    description:
        'Substitui o óleo antigo do motor por óleo novo, essencial para manter o motor funcionando corretamente.',
  ),
  'Rodízio de pneus': ServiceDetail(
    title: 'Rodízio de pneus',
    description:
        'Rotaciona os pneus para garantir desgaste uniforme e estender a durabilidade dos pneus.',
  ),
  'Inspeção dos freios': ServiceDetail(
    title: 'Inspeção dos freios',
    description:
        'Verifica o sistema de freios para garantir a segurança e o funcionamento adequado.',
  ),
  'Troca do filtro de ar': ServiceDetail(
    title: 'Troca do filtro de ar',
    description:
        'Substitui o filtro de ar do motor para manter a qualidade do ar que entra no motor.',
  ),
};

class ServiceDetailScreen extends StatefulWidget {
  final Service service;

  const ServiceDetailScreen({
    required this.service,
    super.key,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  late Service currentService;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentService = widget.service;
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.completed:
        return AppColors.green;
      case ServiceStatus.scheduled:
        return AppColors.accent;
      case ServiceStatus.upcoming:
        return AppColors.amber;
    }
  }

  Color _getStatusBgColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.completed:
        return const Color(0x1422C55E);
      case ServiceStatus.scheduled:
        return const Color(0x143B82F6);
      case ServiceStatus.upcoming:
        return const Color(0x14F59E0B);
    }
  }

  Future<void> _changeStatus(ServiceStatus newStatus) async {
    if (currentService.status == newStatus) return;

    setState(() => isLoading = true);

    try {
      await ServiceApi.updateServiceStatus(
        id: currentService.id,
        status: newStatus,
      );

      setState(() {
        currentService = currentService.copyWith(status: newStatus);
      });

      if (mounted) {
        AppFeedback.show(
          context,
          message: 'Status alterado para ${newStatus.displayName}.',
          tone: AppFeedbackTone.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          message: 'Erro ao atualizar: ${e.toString()}',
          tone: AppFeedbackTone.error,
        );
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await AppFeedback.confirmDestructive(
      context,
      title: 'Excluir serviço?',
      message: 'Essa ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
    );

    if (confirmed && mounted) {
      _performDelete();
    }
  }

  Future<void> _performDelete() async {
    setState(() => isLoading = true);

    try {
      await ServiceApi.deleteService(currentService.id);

      if (mounted) {
        AppFeedback.show(
          context,
          message: 'Serviço excluído com sucesso.',
          tone: AppFeedbackTone.success,
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          context.pop(true); // Return to maintenance screen with refresh signal
        });
      }
    } catch (e) {
      final errorMessage = e.toString();

      // If backend returns 404 here, the item was already removed.
      if (errorMessage.contains('Serviço não encontrado')) {
        if (mounted) {
          AppFeedback.show(
            context,
            message: 'Este serviço já foi excluído.',
            tone: AppFeedbackTone.info,
          );
          context.pop(true);
        }
        return;
      }

      if (mounted) {
        AppFeedback.show(
          context,
          message: 'Erro ao excluir: $errorMessage',
          tone: AppFeedbackTone.error,
        );
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = serviceDetails[currentService.serviceType] ??
        ServiceDetail(
            title: currentService.serviceType,
            description: 'Sem descrição disponível');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444)),
                onPressed: isLoading ? null : _showDeleteConfirmation,
                tooltip: 'Excluir serviço',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getStatusColor(currentService.status).withOpacity(0.3),
                      _getStatusColor(currentService.status).withOpacity(0.1),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(currentService.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        LucideIcons.wrench,
                        size: 40,
                        color: _getStatusColor(currentService.status),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Title and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentService.serviceType,
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentService.formattedDate,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(currentService.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currentService.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(currentService.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Description
                  Text(
                    'Descrição',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      detail.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
                        height: 1.6,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Change Status Section
                  Text(
                    'Alterar Status',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),

                  // Status Options
                  _buildStatusOption(
                    title: 'Concluído',
                    description: 'Marcar como concluído',
                    icon: LucideIcons.check,
                    color: AppColors.green,
                    status: ServiceStatus.completed,
                    isSelected:
                        currentService.status == ServiceStatus.completed,
                  ),
                  const SizedBox(height: 12),

                  _buildStatusOption(
                    title: 'Agendado',
                    description: 'Serviço agendado',
                    icon: LucideIcons.calendar,
                    color: AppColors.accent,
                    status: ServiceStatus.scheduled,
                    isSelected:
                        currentService.status == ServiceStatus.scheduled,
                  ),
                  const SizedBox(height: 12),

                  _buildStatusOption(
                    title: 'Em Breve',
                    description: 'Serviço em breve',
                    icon: LucideIcons.clock,
                    color: AppColors.amber,
                    status: ServiceStatus.upcoming,
                    isSelected: currentService.status == ServiceStatus.upcoming,
                  ),
                  const SizedBox(height: 28),

                  // Additional Info
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.info,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Informações Importantes',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Mantenha registros de todas as manutenções\n'
                          '• Planeje os serviços com antecedência\n'
                          '• Consulte o manual do proprietário',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Delete Button
                  GestureDetector(
                    onTap: isLoading ? null : _showDeleteConfirmation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0x14EF4444),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Excluir Serviço',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF4444),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
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

  Widget _buildStatusOption({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required ServiceStatus status,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : () => _changeStatus(status),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? color : AppColors.secondary.withOpacity(0.3),
                  width: 2,
                ),
                color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
