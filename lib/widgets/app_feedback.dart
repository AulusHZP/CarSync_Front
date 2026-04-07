import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'delete_confirmation_modal.dart';
import 'logout_confirmation_modal.dart';

enum AppFeedbackTone { info, success, warning, error }

class AppFeedback {
  static void show(
    BuildContext context, {
    required String message,
    AppFeedbackTone tone = AppFeedbackTone.info,
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final scheme = _toneScheme(tone);

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.borderColor, width: 1),
          ),
          elevation: 0,
          backgroundColor: scheme.backgroundColor,
          duration: duration,
          content: Row(
            children: [
              Icon(scheme.icon, size: 18, color: scheme.iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          action: actionLabel != null && onAction != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: scheme.actionColor,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }

  static Future<bool> confirmDestructive(
    BuildContext context, {
    required String title,
    required String message,
    String? highlightedText,
    String confirmLabel = 'Excluir',
    String cancelLabel = 'Cancelar',
    bool barrierDismissible = true,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Fechar confirmação',
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return DeleteConfirmationModal(
          title: title,
          message: message,
          highlightedText: highlightedText,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    return result ?? false;
  }

  static Future<bool> confirmLogout(
    BuildContext context, {
    String title = 'Sair da conta?',
    String subtitle = 'Você realmente deseja sair?',
    String confirmLabel = 'Sair',
    String cancelLabel = 'Cancelar',
    bool barrierDismissible = true,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Fechar confirmação',
      barrierColor: Colors.black.withValues(alpha: 0.26),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, _, __) {
        return LogoutConfirmationModal(
          title: title,
          subtitle: subtitle,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    return result ?? false;
  }

  static _SnackStyle _toneScheme(AppFeedbackTone tone) {
    switch (tone) {
      case AppFeedbackTone.success:
        return const _SnackStyle(
          backgroundColor: Color(0xFFEFFCF4),
          borderColor: Color(0xFFBAEACD),
          iconColor: AppColors.green,
          actionColor: AppColors.green,
          icon: Icons.check_circle_outline,
        );
      case AppFeedbackTone.warning:
        return const _SnackStyle(
          backgroundColor: Color(0xFFFFF8EC),
          borderColor: Color(0xFFF8D9A3),
          iconColor: AppColors.amber,
          actionColor: AppColors.amber,
          icon: Icons.warning_amber_rounded,
        );
      case AppFeedbackTone.error:
        return const _SnackStyle(
          backgroundColor: Color(0xFFFFF0F0),
          borderColor: Color(0xFFF4B7B7),
          iconColor: AppColors.red,
          actionColor: AppColors.red,
          icon: Icons.error_outline,
        );
      case AppFeedbackTone.info:
        return const _SnackStyle(
          backgroundColor: Color(0xFFEEF5FF),
          borderColor: Color(0xFFB8D3FF),
          iconColor: AppColors.accent,
          actionColor: AppColors.accent,
          icon: Icons.info_outline,
        );
    }
  }
}

class _SnackStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color actionColor;
  final IconData icon;

  const _SnackStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.actionColor,
    required this.icon,
  });
}
