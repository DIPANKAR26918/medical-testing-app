import 'package:flutter/material.dart';
import '../utils/index.dart';
import 'package:easy_localization/easy_localization.dart';

/// Custom loading indicator widget
class AppLoadingWidget extends StatelessWidget {
  final String? message;

  const AppLoadingWidget({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              message!,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: AppTheme.fontSizeMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom error widget
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({required this.message, this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: AppTheme.fontSizeMedium,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.paddingLarge),
              ElevatedButton(
                onPressed: onRetry,
                child: Text(LocalizationKeys.retry.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom empty state widget
class AppEmptyWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AppEmptyWidget({
    required this.message,
    this.icon = Icons.inbox,
    this.onAction,
    this.actionLabel,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: const Color.fromRGBO(117, 117, 117, 1)),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.textLight,

                fontSize: AppTheme.fontSizeMedium,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppTheme.paddingLarge),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
