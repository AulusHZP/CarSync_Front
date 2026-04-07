import 'package:flutter/material.dart';
import 'carsync_logo_mark.dart';

class PremiumCarSyncHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool showLogo;

  const PremiumCarSyncHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showLogo) ...[
                    const CarSyncLogoMark(size: 28),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F1115),
                        letterSpacing: -0.8,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
                const SizedBox(height: 9),
              Text(
                subtitle,
                maxLines: 2,
                style: const TextStyle(
                    fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.02,
                    height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: trailing,
          ),
        ],
      ],
    );
  }
}
