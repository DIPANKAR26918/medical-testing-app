import 'package:flutter/material.dart';

import '../search_bar.dart';
import 'home_constants.dart';

class HomeSearchSection extends StatelessWidget {
  const HomeSearchSection({super.key, this.onScanTap});

  final VoidCallback? onScanTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Expanded(child: HomeSearchBar()),
          const SizedBox(width: 10),
          _ScanButton(onTap: onScanTap),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .52)),
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: HomeColors.textSecondary,
          size: 29,
        ),
      ),
    );
  }
}
