import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Carte glassmorphism Lumora — bordure blanche légère, coins arrondis (min 16dp),
/// ombre portée colorée, fond semi-transparent avec dégradé.
/// Le BackdropFilter est optionnel et désactivé par défaut pour éviter les
/// problèmes de rendu (écran noir) sur certains appareils.
class LumoraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final double blurSigma;
  final double blurOpacity;
  final bool enableBlur;

  const LumoraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = LumoraRadii.card,
    this.borderWidth = 0.5,
    this.borderColor,
    this.backgroundColor,
    this.shadows,
    this.gradient,
    this.width,
    this.height,
    this.blurSigma = 10.0,
    this.blurOpacity = 0.15,
    this.enableBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveShadows = shadows ??
        [
          LumoraShadows.soft(color: LumoraColors.auroraPurple),
        ];

    final effectiveBgColor = backgroundColor ?? const Color(0x22FFFFFF);
    final effectiveBorderColor = borderColor ?? const Color(0x44FFFFFF);

    Widget content = Container(
      padding: padding,
      color: enableBlur
          ? Colors.white.withAlpha((effectiveBgColor.alpha * blurOpacity * 2.55).toInt().clamp(0, 255))
          : null,
      child: child,
    );

    if (enableBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: content,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                effectiveBgColor,
                effectiveBgColor.withAlpha((effectiveBgColor.alpha * 0.5).toInt().clamp(0, 255)),
              ],
            ),
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        child: content,
      ),
    );
  }
}