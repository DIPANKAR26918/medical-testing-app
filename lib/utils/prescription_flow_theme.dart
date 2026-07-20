import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Shared Material 3 tokens for the prescription-assisted booking journey.
///
/// Keeping the flow on one visual system makes the hand-off from upload to
/// review, confirmation, and tracking feel like one continuous task.
abstract class PrescriptionFlowTheme {
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF4F7FB);

  static const Color ink = Color(0xFF101828);
  static const Color text = Color(0xFF475467);
  static const Color muted = Color(0xFF7C899D);

  static const Color primary = Color(0xFF255FE6);
  static const Color primaryContainer = Color(0xFFEAF1FF);
  static const Color primaryOutline = Color(0xFFC9D8FF);

  static const Color success = Color(0xFF15803D);
  static const Color successContainer = Color(0xFFECFDF3);
  static const Color warning = Color(0xFFB54708);
  static const Color warningContainer = Color(0xFFFFF7E8);
  static const Color danger = Color(0xFFD92D20);

  static const Color outline = Color(0xFFE1E7F0);
  static const Color strongOutline = Color(0xFFD3DBE8);

  static const double cardRadius = 24;
  static const double controlRadius = 16;

  static List<BoxShadow> get cardShadow => const [
    BoxShadow(color: Color(0x0A10213D), blurRadius: 24, offset: Offset(0, 9)),
  ];

  static BoxDecoration card({
    Color color = surface,
    Color borderColor = outline,
    double radius = cardRadius,
    bool shadow = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: shadow ? cardShadow : null,
    );
  }

  static ButtonStyle filledButtonStyle({double radius = controlRadius}) {
    return FilledButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: primary.withValues(alpha: .42),
      disabledForegroundColor: Colors.white.withValues(alpha: .82),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      textStyle: const TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  static ButtonStyle outlinedButtonStyle({double radius = controlRadius}) {
    return OutlinedButton.styleFrom(
      foregroundColor: primary,
      side: const BorderSide(color: strongOutline),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      textStyle: const TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
