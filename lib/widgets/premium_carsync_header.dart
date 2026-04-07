import 'package:flutter/material.dart';
import 'carsync_logo_mark.dart';

class PremiumCarSyncHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final String appName;
  final Widget? trailing;
  final bool showLogo;

  const PremiumCarSyncHeader({
    super.key,
    required this.greeting,
    this.subtitle = '',
    this.appName = 'CarSync',
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
              if (showLogo || appName.trim().isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showLogo) ...[
                      const CarSyncLogoMark(size: 18),
                      if (appName.trim().isNotEmpty) const SizedBox(width: 8),
                    ],
                    if (appName.trim().isNotEmpty)
                      Flexible(
                        child: Text(
                          appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                            letterSpacing: 0.01,
                            height: 1.2,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 10),
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                  letterSpacing: -0.4,
                  height: 1.08,
                ),
              ),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8A8F98),
                    letterSpacing: 0.01,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: trailing,
          ),
        ],
      ],
    );
  }
}
