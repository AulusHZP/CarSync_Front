import 'package:flutter/material.dart';

class DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const DarkCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    const BorderRadius borderRadius = BorderRadius.all(Radius.circular(24));
    
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        padding: padding ?? const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF24344E), Color(0xFF14233F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: borderRadius,
          border: Border.all(
            color: const Color(0x1FFFFFFF),
            width: 0.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000), // rgba(0,0,0,0.13)
              blurRadius: 24,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
