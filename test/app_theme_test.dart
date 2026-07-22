import 'package:flutter_test/flutter_test.dart';

import 'package:medical_diagnostic_app/utils/app_theme.dart';

void main() {
  test('light and dark themes use the bundled Testified font', () {
    final lightTheme = AppTheme.getLightTheme();
    final darkTheme = AppTheme.getDarkTheme();

    expect(
      lightTheme.textTheme.bodyMedium?.fontFamily,
      AppTheme.fontFamily,
    );
    expect(
      lightTheme.textTheme.titleLarge?.fontFamily,
      AppTheme.fontFamily,
    );
    expect(
      lightTheme.appBarTheme.titleTextStyle?.fontFamily,
      AppTheme.fontFamily,
    );
    expect(
      darkTheme.textTheme.bodyMedium?.fontFamily,
      AppTheme.fontFamily,
    );
  });

  test('all Material button families keep the bundled Testified font', () {
    for (final theme in [AppTheme.getLightTheme(), AppTheme.getDarkTheme()]) {
      expect(
        theme.elevatedButtonTheme.style?.textStyle?.resolve({})?.fontFamily,
        AppTheme.fontFamily,
      );
      expect(
        theme.filledButtonTheme.style?.textStyle?.resolve({})?.fontFamily,
        AppTheme.fontFamily,
      );
      expect(
        theme.outlinedButtonTheme.style?.textStyle?.resolve({})?.fontFamily,
        AppTheme.fontFamily,
      );
      expect(
        theme.textButtonTheme.style?.textStyle?.resolve({})?.fontFamily,
        AppTheme.fontFamily,
      );
    }
  });
}
