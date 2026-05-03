import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/index.dart';

/// First-time language selection screen
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    // Set default to English
    _selectedLanguage = 'en';
  }

  /// Handle language selection and navigate to auth screen
  void _selectLanguage(String locale) async {
    setState(() {
      _selectedLanguage = locale;
    });

    // Change the app language
    await context.setLocale(Locale(locale));

    // Navigate to authentication screen
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Header
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor,
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingLarge),

                // Title
                Text(
                  LocalizationKeys.appTitle.tr(),
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeTitle + 6,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.paddingMedium),

                // Subtitle
                Text(
                  LocalizationKeys.selectLanguage.tr(),
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: AppTheme.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.paddingXLarge),

                // Language Selection - English
                _buildLanguageOption(
                  context,
                  LocalizationKeys.english.tr(),
                  'English',
                  'en',
                  Icons.language,
                ),
                const SizedBox(height: AppTheme.paddingMedium),

                // Language Selection - Bangla
                _buildLanguageOption(
                  context,
                  LocalizationKeys.bangla.tr(),
                  'বাংলা',
                  'bn',
                  Icons.language,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build language option button
  Widget _buildLanguageOption(
    BuildContext context,
    String label,
    String nativeLabel,
    String locale,
    IconData icon,
  ) {
    final isSelected = _selectedLanguage == locale;

    return GestureDetector(
      onTap: () => _selectLanguage(locale),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
            ),
            const SizedBox(width: AppTheme.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  Text(
                    nativeLabel,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
