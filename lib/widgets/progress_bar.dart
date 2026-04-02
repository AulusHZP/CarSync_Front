import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final Color? backgroundColor;
  final double height;

  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(999),
      ),
      clipBehavior: Clip.antiAlias,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
