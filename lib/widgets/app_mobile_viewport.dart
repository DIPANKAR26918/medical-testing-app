import 'package:flutter/material.dart';

/// Keeps the mobile type hierarchy predictable without ignoring accessibility.
///
/// The app's bundled font remains in control at every device width. System text
/// scaling is still respected up to 130%, while layouts are tested at that
/// upper bound to prevent text, image, and price overflow.
class AppMobileViewport extends StatelessWidget {
  const AppMobileViewport({required this.child, super.key});

  static const double maximumTextScale = 1.3;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maximumTextScale,
      child: child,
    );
  }
}
