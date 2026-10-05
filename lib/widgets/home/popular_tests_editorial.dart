import 'package:flutter/material.dart';
import '../../models/medical_test.dart';
import '../medical_test_catalog/medical_test_catalog_widgets.dart';
import 'home_constants.dart';

class PopularTestsEditorial extends StatelessWidget {
  const PopularTestsEditorial({
    required this.tests,
    required this.onTestTap,
    required this.onSeeAll,
    super.key,
  });

  final List<MedicalTest> tests;
  final ValueChanged<MedicalTest> onTestTap;
  final VoidCallback onSeeAll;

  Color _getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('women') || lower.contains('female')) {
      return const Color(0xFFFFF0F5);
    }
    if (lower.contains('men') || lower.contains('male')) {
      return const Color(0xFFF0F4FF);
    }
    if (lower.contains('kidney') || lower.contains('renal')) {
      return const Color(0xFFFDF0FF);
    }
    if (lower.contains('liver') || lower.contains('hepatic')) {
      return const Color(0xFFFFF9E6);
    }
    if (lower.contains('heart') || lower.contains('cardiac')) {
      return const Color(0xFFFFF0F0);
    }
    if (lower.contains('diabetes') || lower.contains('sugar')) {
      return const Color(0xFFE6F9FF);
    }
    if (lower.contains('bone') || lower.contains('vitamin')) {
      return const Color(0xFFF0FFF4);
    }
    if (lower.contains('thyroid')) {
      return const Color(0xFFF4F0FF);
    }
    if (lower.contains('blood')) {
      return const Color(0xFFFFF0F0);
    }
    return const Color(0xFFF0F4FF);
  }

  Color _getCategoryAccent(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('kidney')) return const Color(0xFF7C3AED);
    if (lower.contains('liver')) return const Color(0xFFD97706);
    if (lower.contains('heart')) return const Color(0xFFDC2626);
    if (lower.contains('diabetes')) return const Color(0xFF0891B2);
    if (lower.contains('thyroid')) return const Color(0xFF6D28D9);
    if (lower.contains('vitamin')) return const Color(0xFF059669);
    if (lower.contains('blood')) return const Color(0xFFDC2626);
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayTests = tests.take(5).toList();

    return Container(
      width: double.infinity,
      color: HomeColors.surfaceAlt,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Tests',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: HomeColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              InkWell(
                onTap: onSeeAll,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'See all →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: HomeColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Test List
          ...List.generate(displayTests.length, (index) {
            final test = displayTests[index];
            final isLast = index == displayTests.length - 1;

            return Column(
              children: [
                _buildTestRow(test),
                if (!isLast)
                  const Divider(
                    height: 24,
                    thickness: 0.5,
                    color: HomeColors.border,
                    indent: 54, // 40 (icon) + 14 (spacing)
                  ),
              ],
            );
          }),
          const SizedBox(height: 14),
          // Bottom see all
          Center(
            child: InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'See all tests →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HomeColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestRow(MedicalTest test) {
    // Generate metadata string
    final parts = <String>[];
    final count = test.parameterCount;
    if (count != null && count > 0) {
      parts.add('$count parameters');
    }
    final reporting = test.reportingTime;
    if (reporting != null && reporting.isNotEmpty) {
      parts.add(reporting);
    }
    parts.add(test.homeCollectionAvailable ? 'Home collection' : 'Lab visit');

    final metadataText = parts.map((e) => '· $e').join('  ');

    return Semantics(
      label: 'Test ${test.displayName}, ${test.priceLabel}',
      button: true,
      child: InkWell(
        onTap: () => onTestTap(test),
        borderRadius: BorderRadius.circular(12),
        splashColor: HomeColors.primary.withValues(alpha: 0.06),
        highlightColor: HomeColors.primary.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCategoryColor(test.category),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(7),
                child: MedicalCategoryIllustration(
                  category: test.category,
                  color: _getCategoryAccent(test.category),
                ),
              ),
              const SizedBox(width: 14),
              // Middle Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: HomeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadataText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: HomeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right Price & Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    test.priceLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: HomeColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    label: 'Book test ${test.displayName}',
                    button: true,
                    child: InkWell(
                      onTap: () => onTestTap(test),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: HomeColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: HomeColors.primary.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Book',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
