import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Figma'daki LinkSaver logosu:
/// Degrade (pembe→mavi) zincir halkası ikonu + "LinkSaver" yazısı
class LinkSaverLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const LinkSaverLogo({
    super.key,
    this.size = 32,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.logoStart, AppColors.logoEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.logoStart.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.link_rounded,
          color: Colors.white,
          size: size * 0.58,
        ),
      ),
    );

    if (!showText) return icon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.logoStart, AppColors.logoEnd],
          ).createShader(bounds),
          child: Text(
            'LinkSaver',
            style: TextStyle(
              fontSize: size * 0.58,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}