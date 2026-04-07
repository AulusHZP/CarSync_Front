import 'package:flutter/material.dart';

class DeleteConfirmationModal extends StatelessWidget {
  final String title;
  final String message;
  final String? highlightedText;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const DeleteConfirmationModal({
    super.key,
    required this.title,
    required this.message,
    this.highlightedText,
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 26,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                        letterSpacing: -0.2,
                        height: 1.14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMessage(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _ModalActionButton(
                            onPressed: onCancel,
                            text: cancelLabel,
                            backgroundColor: const Color(0xFFF2F2F7),
                            foregroundColor: const Color(0xFF6B7280),
                            borderColor: const Color(0x00FFFFFF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModalActionButton(
                            onPressed: onConfirm,
                            text: confirmLabel,
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFFFF3B30),
                            borderColor: const Color(0x33FF3B30),
                            isDestructive: true,
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

  Widget _buildMessage() {
    final highlight = highlightedText;
    if (highlight == null || highlight.isEmpty || !message.contains(highlight)) {
      return const Text(
        'Essa ação não pode ser desfeita.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF7E8490),
          height: 1.45,
          letterSpacing: 0.02,
        ),
      );
    }

    final start = message.indexOf(highlight);
    final prefix = message.substring(0, start);
    final suffix = message.substring(start + highlight.length);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: highlight,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
          TextSpan(text: suffix),
        ],
      ),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF7E8490),
        height: 1.45,
        letterSpacing: 0.02,
      ),
    );
  }
}

class _ModalActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final bool isDestructive;

  const _ModalActionButton({
    required this.onPressed,
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    this.isDestructive = false,
  });

  @override
  State<_ModalActionButton> createState() => _ModalActionButtonState();
}

class _ModalActionButtonState extends State<_ModalActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.985 : 1,
      child: Material(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (isPressed) {
            if (mounted) {
              setState(() {
                _pressed = isPressed;
              });
            }
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: widget.foregroundColor.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.borderColor, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    widget.isDestructive ? FontWeight.w700 : FontWeight.w600,
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
