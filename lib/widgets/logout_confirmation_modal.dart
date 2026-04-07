import 'package:flutter/material.dart';

class LogoutConfirmationModal extends StatelessWidget {
  final String title;
  final String subtitle;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const LogoutConfirmationModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFDFE),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 26,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Color(0x0D0F172A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        letterSpacing: -0.35,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B7280),
                        height: 1.42,
                        letterSpacing: 0.05,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            onPressed: onCancel,
                            text: cancelLabel,
                            backgroundColor: const Color(0xFFF3F4F6),
                            foregroundColor: const Color(0xFF6B7280),
                            borderColor: const Color(0xFFE9EBEF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionButton(
                            onPressed: onConfirm,
                            text: confirmLabel,
                            backgroundColor: const Color(0x0FFF3B30),
                            foregroundColor: const Color(0xFFE7584E),
                            borderColor: const Color(0x33FF3B30),
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final bool isPrimary;

  const _ActionButton({
    required this.onPressed,
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    this.isPrimary = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: _pressed ? 0.86 : 1,
      child: Material(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (isPressed) {
            if (!mounted) {
              return;
            }
            setState(() => _pressed = isPressed);
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: widget.foregroundColor.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.borderColor, width: 1),
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    widget.isPrimary ? FontWeight.w700 : FontWeight.w600,
                color: widget.foregroundColor,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
