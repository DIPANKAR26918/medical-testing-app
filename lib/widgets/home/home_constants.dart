import 'package:flutter/material.dart';

/// Centralized design tokens for all home-screen widgets.
///
/// Every home widget should reference these constants instead of
/// hardcoding colors, text styles, or spacing values.
class HomeColors {
  HomeColors._();

  // ── Brand / Clinical ──────────────────────────────────────────────
  static const Color teal        = Color(0xFF0E8C93);
  static const Color tealLight   = Color(0xFFE6F7F8);
  static const Color deepBlue    = Color(0xFF0F2A44);
  static const Color orange      = Color(0xFFF97316);
  static const Color orangeLight = Color(0xFFFFF7ED);
  static const Color blueAccent  = Color(0xFF2563EB);
  static const Color blueLight   = Color(0xFFEFF4FF);
  static const Color success     = Color(0xFF16A34A);
  static const Color successBg   = Color(0xFFF0FDF4);
  static const Color danger      = Color(0xFFDC2626);

  // ── Backgrounds ────────────────────────────────────────────────────
  static const Color bgTop       = Color.fromARGB(255, 1, 131, 134);
  static const Color bgMid       = Color(0xFFEAF8FF);
  static const Color bgBottom    = Color(0xFFFFFFFF);

  // ── Surfaces ───────────────────────────────────────────────────────
  static const Color cardWhite   = Color(0xFFFDFDFD);
  static const Color border      = Color(0x0D000000); // 5% black
  static const Color shadow      = Color(0x09000000); // 3.5% black

  // ── Text ───────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F2A44);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted     = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFF9CA3AF);
}

class HomeTextStyles {
  HomeTextStyles._();

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w900,
    color: HomeColors.deepBlue,
  );

  static const TextStyle sectionAction = TextStyle(
    fontWeight: FontWeight.w800,
    color: HomeColors.teal,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w900,
    color: HomeColors.deepBlue,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12.7,
    color: Colors.black54,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle badgeLabel = TextStyle(
    fontSize: 12.4,
    fontWeight: FontWeight.w800,
    color: HomeColors.deepBlue,
  );

  static const TextStyle badgeCaption = TextStyle(
    fontSize: 10.2,
    color: Color(0x8C000000), // 55% black
    fontWeight: FontWeight.w600,
    height: 1.15,
  );

  static const TextStyle tileLabel = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w800,
    color: Color(0xFF111827),
  );
}

class HomeSpacing {
  HomeSpacing._();

  static const double sectionGap    = 18.0;
  static const double cardGap       = 14.0;
  static const double smallGap      = 10.0;
  static const double horizontalPad = 16.0;

  static const EdgeInsets contentPadding =
      EdgeInsets.fromLTRB(16, 18, 16, 0);

  static const EdgeInsets listPadding =
      EdgeInsets.fromLTRB(0, 12, 0, 104);
}

class HomeDecorations {
  HomeDecorations._();

  static BoxDecoration card({double radius = 22}) => BoxDecoration(
    color: Colors.white.withValues(alpha: .96),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: HomeColors.border),
    boxShadow: [
      BoxShadow(
        color: HomeColors.shadow,
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
