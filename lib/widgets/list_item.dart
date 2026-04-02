import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';

class ListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final Color? iconBgColor;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool showDivider;

  const ListItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.iconBgColor,
    this.onTap,
    this.showChevron = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBgColor ?? const Color(0x0A000000), // rgba(0,0,0,0.04)
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: iconColor ?? AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.quarter,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (showChevron)
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: AppColors.quarter,
                  ),
              ],
            ),
          ),
          if (showDivider)
            const Divider(
              height: 0.5,
              indent: 68, // width of icon + padding
            ),
        ],
      ),
    );
  }
}
