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
  bool _showLogo = false;
  bool _showTitle = false;
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _showLogo = true);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        setState(() => _showTitle = true);
      });
      Future.delayed(const Duration(milliseconds: 240), () {
        if (!mounted) return;
        setState(() => _showButtons = true);
      });
    });
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.paddingXLarge,
              horizontal: AppTheme.paddingLarge,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.paddingLarge),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusLarge,
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AnimatedOpacity(
                        opacity: _showLogo ? 1 : 0,
                        duration: const Duration(milliseconds: 360),
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 360),
                          offset: _showLogo
                              ? Offset.zero
                              : const Offset(0, 0.1),
                          child: Image.asset(
                            'assets/images/Testified_image.png',
                            width: 120,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingLarge),
                      AnimatedOpacity(
                        opacity: _showTitle ? 1 : 0,
                        duration: const Duration(milliseconds: 360),
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 360),
                          offset: _showTitle
                              ? Offset.zero
                              : const Offset(0, 0.1),
                          child: Text(
                            'Select Language',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingLarge),
                      AnimatedOpacity(
                        opacity: _showButtons ? 1 : 0,
                        duration: const Duration(milliseconds: 360),
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 360),
                          offset: _showButtons
                              ? Offset.zero
                              : const Offset(0, 0.1),
                          child: Column(
                            children: [
                              _buildLanguageButton(
                                context: context,
                                title: 'English',
                                subtitle: 'ইংরেজি',
                                locale: 'en',
                              ),
                              const SizedBox(height: AppTheme.paddingMedium),
                              _buildLanguageButton(
                                context: context,
                                title: 'বাংলা',
                                subtitle: 'Bengali',
                                locale: 'bn',
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedLanguage != null) ...[
                        const SizedBox(height: AppTheme.paddingXLarge),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _applySelection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.lightGreen,
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
    );
  }

  Widget _buildLanguageButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String locale,
  }) {
    final isSelected = _selectedLanguage == locale;

    return GestureDetector(
      onTap: () => _selectLanguage(locale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.12 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                color: isSelected
                    ? AppTheme.lightGreen.withOpacity(0.18)
                    : const Color(0xFFE8F5E9),
              ),
              child: const Icon(Icons.translate, color: AppTheme.lightGreen),
            ),
            const SizedBox(width: AppTheme.paddingLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingXSmall),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
              size: 18,
              color: isSelected ? AppTheme.lightGreen : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
