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
}
