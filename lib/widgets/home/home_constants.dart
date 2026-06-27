import 'package:flutter/material.dart';

/// Centralized design tokens for all home-screen widgets.
///
/// Every home widget should reference these constants instead of
/// hardcoding colors, text styles, or spacing values.
class HomeColors {
  HomeColors._();

  // ── Brand / Clinical ──────────────────────────────────────────────
  static const Color teal = Color(0xFF0E8C93);
  static const Color tealLight = Color(0xFFE6F7F8);
  static const Color tealDark = Color(0xFF064E6E);
  static const Color deepBlue = Color(0xFF0F2A44);
  static const Color navyDark = Color(0xFF0A1628);
  static const Color orange = Color(0xFFF97316);
  static const Color orangeLight = Color(0xFFFFF7ED);
  static const Color blueAccent = Color(0xFF2563EB);
  static const Color blueLight = Color(0xFFEFF4FF);
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color danger = Color(0xFFDC2626);
  static const Color healingGreen = Color(0xFF059669);
  static const Color lavender = Color(0xFF8B5CF6);
  static const Color lavenderBg = Color(0xFFF5F3FF);

  // ── Backgrounds ────────────────────────────────────────────────────
  static const Color bgTop = Color(0xFF064E6E);
  static const Color bgMid = Color(0xFFF0F7FA);
  static const Color bgBottom = Color(0xFFF8FAFB);

  // ── Surfaces ───────────────────────────────────────────────────────
  static const Color cardWhite = Color(0xFFFDFDFD);
  static const Color surfaceGlass = Color(0xD9FFFFFF); // white at ~85%
  static const Color border = Color(0x0F000000); // 6% black
  static const Color borderLight = Color(0x0A000000); // 4% black
  static const Color shadow = Color(0x0C000000); // ~5% black

  // ── Text ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0A1628);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
}

class HomeTextStyles {
  HomeTextStyles._();

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: HomeColors.navyDark,
    letterSpacing: -0.3,
  );

  static const TextStyle sectionAction = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 13.5,
    color: HomeColors.teal,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w800,
    color: HomeColors.navyDark,
    letterSpacing: -0.2,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12.7,
    color: HomeColors.textSecondary,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle badgeLabel = TextStyle(
    fontSize: 12.4,
    fontWeight: FontWeight.w800,
    color: HomeColors.navyDark,
  );

  static const TextStyle badgeCaption = TextStyle(
    fontSize: 10.5,
    color: HomeColors.textMuted,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle tileLabel = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: HomeColors.navyDark,
  );
}

class HomeSpacing {
  HomeSpacing._();

  static const double sectionGap = 20.0;
  static const double cardGap = 14.0;
  static const double smallGap = 10.0;
  static const double horizontalPad = 16.0;

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(16, 20, 16, 0);

  static const EdgeInsets listPadding = EdgeInsets.fromLTRB(0, 12, 0, 108);
}

class HomeAnimations {
  HomeAnimations._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.easeInOutCubic;
}

class HomeDecorations {
  HomeDecorations._();

  static BoxDecoration card({double radius = 20}) => BoxDecoration(
    color: HomeColors.surfaceGlass,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: HomeColors.border),
    boxShadow: [
      BoxShadow(
        color: HomeColors.shadow,
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: HomeColors.teal.withValues(alpha: .03),
        blurRadius: 40,
        offset: const Offset(0, 16),
      ),
    ],
  );

  static BoxDecoration glassCard({double radius = 20}) => BoxDecoration(
    color: Colors.white.withValues(alpha: .88),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: .6), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: HomeColors.shadow,
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration gradientCard({
    double radius = 20,
    List<Color>? colors,
  }) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors ?? [Colors.white, const Color(0xFFF5FAFB)],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: HomeColors.border),
    boxShadow: [
      BoxShadow(
        color: HomeColors.shadow,
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
