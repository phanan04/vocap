import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class VocapLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const VocapLogo({
    super.key,
    this.size = 40,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'V',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.54,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1,
          ),
        ),
      ),
    );

    if (!showText) return badge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 10),
        const Text(
          'Vocap',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
