import 'package:flutter/material.dart';

/// Design system Lumora — 100 % organique.
/// Aucun gris brut, aucun bord droit, uniquement des formes arrondies,
/// des dégradés fluides, du glassmorphism et des ombres douces.

abstract class LumoraColors {
  // Fond & Surfaces (jamais de gris #808080)
  static const Color deepSpace = Color(0xFF0F0C29);
  static const Color twilight = Color(0xFF302B63);
  static const Color dawn = Color(0xFF24243E);
  static const Color midnight = Color(0xFF1A1A2E);
  static const Color softMist = Color(0xFFE0E0F8);
  static const Color pearl = Color(0xFFF5F5FA);

  // Accent lumineux
  static const Color auroraGreen = Color(0xFF00F5A0);
  static const Color auroraBlue = Color(0xFF00D9F5);
  static const Color auroraPurple = Color(0xFF9D4EDD);
  static const Color auroraPink = Color(0xFFFF6B9D);
  static const Color auroraGold = Color(0xFFFFD166);
  static const Color auroraOrange = Color(0xFFFF9F1C);

  // États fonctionnels (pas de gris brut)
  static const Color lifeCoral = Color(0xFFFF6B6B);
  static const Color lifeRose = Color(0xFFFF8E8E);
  static const Color energyAmber = Color(0xFFFFB703);
  static const Color successMint = Color(0xFF06D6A0);
  static const Color syncGreen = Color(0xFF2ECC71);
  static const Color waitOrange = Color(0xFFF39C12);
  static const Color errorRose = Color(0xFFE74C3C);

  // Verrous & inactifs (translucides, jamais gris brut)
  static const Color lockOverlay = Color(0x66C8B6DB);
  static const Color disabledMist = Color(0x99B8C0CC);
}

abstract class LumoraGradients {
  static const Gradient homeBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [LumoraColors.deepSpace, LumoraColors.twilight, LumoraColors.dawn],
  );

  static const Gradient authBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [LumoraColors.midnight, LumoraColors.deepSpace, LumoraColors.twilight],
  );

  static const Gradient victory = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [LumoraColors.auroraGold, LumoraColors.auroraOrange],
  );

  static const Gradient primaryBubble = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [LumoraColors.auroraGreen, LumoraColors.auroraBlue],
  );

  static const Gradient secondaryBubble = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [LumoraColors.auroraPurple, LumoraColors.auroraPink],
  );

  static const Gradient dangerBubble = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [LumoraColors.lifeCoral, LumoraColors.auroraPink],
  );

  static const Gradient glassOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x22FFFFFF), Color(0x11FFFFFF)],
  );
}

abstract class LumoraShadows {
  static BoxShadow soft({Color color = LumoraColors.auroraBlue}) => BoxShadow(
    color: color.withAlpha(80),
    blurRadius: 16,
    spreadRadius: -4,
    offset: const Offset(0, 6),
  );

  static BoxShadow glow({Color color = LumoraColors.auroraGreen}) => BoxShadow(
    color: color.withAlpha(120),
    blurRadius: 24,
    spreadRadius: 0,
    offset: const Offset(0, 0),
  );

  static BoxShadow floating({Color color = LumoraColors.auroraPurple}) => BoxShadow(
    color: color.withAlpha(60),
    blurRadius: 20,
    spreadRadius: -2,
    offset: const Offset(0, 10),
  );

  static BoxShadow innerGlow({Color color = LumoraColors.auroraGold}) => BoxShadow(
    color: color.withAlpha(40),
    blurRadius: 12,
    spreadRadius: -6,
    offset: const Offset(0, -4),
  );
}

abstract class LumoraTextStyles {
  static const String _fontFamily = 'Nunito';

  static TextStyle displayLarge({Color color = LumoraColors.pearl}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: color,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium({Color color = LumoraColors.pearl}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: -0.3,
  );

  static TextStyle titleLarge({Color color = LumoraColors.pearl}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 0,
  );

  static TextStyle bodyLarge({Color color = LumoraColors.softMist}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: 0.2,
  );

  static TextStyle bodyMedium({Color color = LumoraColors.softMist}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: color,
    letterSpacing: 0.1,
  );

  static TextStyle label({Color color = LumoraColors.softMist}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 0.4,
  );
}

abstract class LumoraRadii {
  static const double card = 16.0;
  static const double modal = 24.0;
  static const double screen = 32.0;
  static const double bubble = 9999.0; // fully rounded / pill
  static const double small = 12.0;
  static const double chip = 20.0;
}

class LumoraTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: LumoraColors.deepSpace,
      textTheme: base.textTheme.apply(
        fontFamily: 'Nunito',
        bodyColor: LumoraColors.softMist,
        displayColor: LumoraColors.pearl,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(LumoraRadii.card)),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(LumoraRadii.modal)),
        ),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(LumoraRadii.modal)),
        ),
      ),
    );
  }
}
