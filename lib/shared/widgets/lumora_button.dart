import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/utils/haptics.dart';

/// Bouton organique Lumora — forme bulle flottante, dégradé, ombre colorée,
/// inkWell circulaire, animation de pression (scale 0.95), haptique.
/// Jamais de bords droits, jamais de gris brut.
class LumoraButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String? text;
  final Widget? icon;
  final List<Color>? gradientColors;
  final double? size;
  final EdgeInsetsGeometry padding;
  final bool isFloating;
  final double elevation;
  final Duration animationDuration;
  final bool isCompact;

  const LumoraButton({
    super.key,
    this.onPressed,
    this.text,
    this.icon,
    this.gradientColors,
    this.size,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    this.isFloating = true,
    this.elevation = 6.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.isCompact = false,
  });

  @override
  State<LumoraButton> createState() => _LumoraButtonState();
}

class _LumoraButtonState extends State<LumoraButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _floatController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pressController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = true);
    _pressController.forward();
    LumoraHaptics.buttonPress();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ??
        [LumoraColors.auroraGreen, LumoraColors.auroraBlue];

    final effectiveSize = widget.size ?? (widget.isCompact ? 48.0 : null);

    Widget child;
    if (effectiveSize != null) {
      child = widget.icon ?? const SizedBox.shrink();
    } else {
      child = FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              widget.icon!,
              const SizedBox(width: 10),
            ],
            if (widget.text != null)
              Text(
                widget.text!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LumoraTextStyles.bodyLarge(color: LumoraColors.pearl),
              ),
          ],
        ),
      );
    }

    // Animation de pression : scale 1.0 → 0.95
    final pressScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    // Animation flottante : translate Y de -2px
    final floatOffset = Tween<double>(begin: 0.0, end: -2.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Intensité du glow selon l'état
    final glowMultiplier = _isPressed ? 1.5 : 1.0;

    final baseWidget = Container(
      width: effectiveSize,
      height: effectiveSize,
      padding: effectiveSize == null ? widget.padding : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LumoraRadii.bubble),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: widget.onPressed != null
            ? [
                BoxShadow(
                  color: colors.last.withAlpha(((widget.elevation * 14) * glowMultiplier).toInt().clamp(0, 200)),
                  blurRadius: widget.elevation * 2.5 * glowMultiplier,
                  spreadRadius: -2,
                  offset: Offset(0, widget.elevation),
                ),
                BoxShadow(
                  color: colors.first.withAlpha(((widget.elevation * 8) * glowMultiplier).toInt().clamp(0, 120)),
                  blurRadius: widget.elevation * 1.5,
                  spreadRadius: -4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(LumoraRadii.bubble),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          borderRadius: BorderRadius.circular(LumoraRadii.bubble),
          splashColor: Colors.white.withAlpha(40),
          highlightColor: Colors.white.withAlpha(20),
          child: Center(child: child),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _pressController,
      builder: (context, _) {
        return ScaleTransition(
          scale: pressScale,
          child: widget.isFloating
              ? AnimatedBuilder(
                  animation: _floatController,
                  builder: (context, _) {
                    return Transform.translate(
                      offset: Offset(0, floatOffset.value),
                      child: baseWidget,
                    );
                  },
                )
              : baseWidget,
        );
      },
    );
  }
}