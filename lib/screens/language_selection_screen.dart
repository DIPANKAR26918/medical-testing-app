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
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = null;
  }

  /// Handle language selection without navigating yet
  void _selectLanguage(String locale) {
    setState(() {
      _selectedLanguage = locale;
    });
  }

  Future<void> _applySelection() async {
    if (_selectedLanguage == null) return;

    await context.setLocale(Locale(_selectedLanguage!));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.paddingXLarge,
                horizontal: AppTheme.paddingLarge,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.paddingLarge),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusLarge,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                          ),
                          child: Icon(
                            Icons.medical_services,
                            size: 42,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.paddingLarge),
                        Text(
                          LocalizationKeys.appTitle.tr(),
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeTitle + 8,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.paddingSmall),
                        Text(
                          LocalizationKeys.selectLanguage.tr(),
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeLarge,
                            color: AppTheme.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.paddingXLarge),
                        _buildLanguageOption(
                          context,
                          'ইংরেজি',
                          'en',
                          Icons.language,
                        ),
                        const SizedBox(height: AppTheme.paddingMedium),
                        _buildLanguageOption(
                          context,
                          'বাংলা',
                          'bn',
                          Icons.language,
                        ),
                        if (_selectedLanguage != null) ...[
                          const SizedBox(height: AppTheme.paddingXLarge),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _applySelection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusLarge,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.paddingLarge,
                                ),
                              ),
                              child: Text(
                                _selectedLanguage == 'en'
                                    ? 'Continue'
                                    : 'চলিয়ে যান',
                                style: const TextStyle(
                                  fontSize: AppTheme.fontSizeLarge,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
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
    String locale,
    IconData icon,
  ) {
    final isSelected = _selectedLanguage == locale;

    return GestureDetector(
      onTap: () => _selectLanguage(locale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.paddingLarge,
          horizontal: AppTheme.paddingMedium,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          color: isSelected
              ? Colors.white
              : AppTheme.borderColor.withValues(alpha: 0.12),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  AppTheme.borderRadiusMedium,
                ),
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.18)
                    : AppTheme.borderColor.withValues(alpha: 0.15),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textDark,
              ),
            ),
            const SizedBox(width: AppTheme.paddingMedium),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textDark,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
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
