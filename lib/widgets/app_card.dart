import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? color;
  final BoxShadow? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ?? 18;
    final BorderRadius borderRadiusGeometry = BorderRadius.all(Radius.circular(radius));
    
    return ClipRRect(
      borderRadius: borderRadiusGeometry,
      child: Container(
        padding: padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color ?? AppColors.card,
          borderRadius: borderRadiusGeometry,
          boxShadow: [
            boxShadow ??
                const BoxShadow(
                  color: Color(0x0A000000), // rgba(0,0,0,0.04)
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
            const BoxShadow(
              color: Color(0x05000000), // rgba(0,0,0,0.02)
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
