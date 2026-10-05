import 'package:flutter/material.dart';

/// Centralized design tokens for all home-screen widgets.
///
/// Every home widget should reference these constants instead of
/// hardcoding colors, text styles, or spacing values.
class HomeColors {
  HomeColors._();

  // ── Brand / Clinical ──────────────────────────────────────────────
  static const Color primary = Color(0xFF0D9B8C);
  static const Color primaryDark = Color(0xFF087A6E);
  static const Color primarySoft = Color(0xFFEFF8F6);
  static const Color navy = Color(0xFF172554);
  static const Color deepBlue = Color(0xFF111C3B);
  static const Color navyDark = Color(0xFF111C3B);
  static const Color orange = Color(0xFFF97316);
  static const Color orangeLight = Color(0xFFFFF1E7);
  static const Color blueAccent = Color(0xFF2563EB);
  static const Color blueLight = Color(0xFFEFF6FF);
  static const Color success = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFECFDF3);
  static const Color danger = Color(0xFFE11D48);
  static const Color healingGreen = Color(0xFF2D8C92);
  static const Color mint = Color(0xFF17856D);
  static const Color mintSoft = Color(0xFFE8F5E9);
  static const Color lavender = Color(0xFF7C3AED);
  static const Color lavenderBg = Color(0xFFF5F3FF);

  // ── Status ──────────────────────────────────────────────────────────
  static const Color statusGreen = Color(0xFF2E7D32);
  static const Color statusAmber = Color(0xFFF57F17);
  static const Color statusBlue = Color(0xFF1565C0);

  // ── Backgrounds ────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF8F7F5);
  static const Color surfaceTeal = Color(0xFFEFF8F6);
  static const Color bgTop = Color(0xFFF4F7FC);
  static const Color bgMid = background;
  static const Color bgBottom = Color(0xFFFAFBFD);

  // ── Surfaces ───────────────────────────────────────────────────────
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color surfaceGlass = Color(0xD9FFFFFF); // white at ~85%
  static const Color surfaceSoft = Color(0xFFF7F9FC);
  static const Color border = Color(0xFFE8EAED);
  static const Color borderLight = Color(0xFFF0F1F3);
  static const Color shadow = Color(0x0C000000); // ~5% black

  // ── Text ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1D21);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textMuted = Color(0xFF9AA0A6);
  static const Color textHint = Color(0xFFBDC1C6);
}

class HomeTextStyles {
  HomeTextStyles._();

  /// Section titles — understated, not screaming
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: HomeColors.textSecondary,
    letterSpacing: 0.3,
  );

  /// Section action links
  static const TextStyle sectionAction = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 13,
    color: HomeColors.primary,
  );

  /// Card titles / test names / key content
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: HomeColors.textPrimary,
    letterSpacing: 0,
  );

  /// Card subtitles and descriptions
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    color: HomeColors.textSecondary,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  /// Badge labels
  static const TextStyle badgeLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: HomeColors.textPrimary,
  );

  /// Badge captions
  static const TextStyle badgeCaption = TextStyle(
    fontSize: 10.5,
    color: HomeColors.textMuted,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  /// Tile labels
  static const TextStyle tileLabel = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: HomeColors.textPrimary,
  );

  /// Greeting text
  static const TextStyle greeting = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: HomeColors.textPrimary,
    letterSpacing: -0.3,
  );

  /// Price text
  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: HomeColors.primary,
  );

  /// CTA button text
  static const TextStyle cta = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  /// Metadata / small descriptors
  static const TextStyle metadata = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: HomeColors.textSecondary,
  );
}

class HomeSpacing {
  HomeSpacing._();

  static const double sectionGap = 28.0;
  static const double cardGap = 14.0;
  static const double smallGap = 12.0;
  static const double horizontalPad = 20.0;
  static const double cardRadius = 14.0;

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(20, 16, 20, 0);

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

  static BoxDecoration card({double radius = 14}) => BoxDecoration(
    color: HomeColors.cardWhite,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: HomeColors.border),
    boxShadow: [
      BoxShadow(
        color: HomeColors.shadow,
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration glassCard({double radius = 14}) => BoxDecoration(
    color: Colors.white.withValues(alpha: .88),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: .6), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: HomeColors.shadow,
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration gradientCard({
    double radius = 14,
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
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
