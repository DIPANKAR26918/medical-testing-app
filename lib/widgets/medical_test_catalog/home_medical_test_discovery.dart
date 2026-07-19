import 'package:flutter/material.dart';

import '../../models/medical_test.dart';
import 'medical_test_catalog_widgets.dart';

class HomeMedicalTestDiscovery extends StatelessWidget {
  const HomeMedicalTestDiscovery({
    required this.isLoading,
    required this.onRetry,
    required this.onTestTap,
    required this.onCategoryTap,
    required this.onAllCategoriesTap,
    this.feed,
    this.error,
    super.key,
  });

  final HomeMedicalTestFeed? feed;
  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;
  final ValueChanged<MedicalTest> onTestTap;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onAllCategoriesTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DiscoveryHeading(onAllCategoriesTap: onAllCategoriesTap),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _content(),
        ),
      ],
    );
  }

  Widget _content() {
    final currentFeed = feed;

    if (isLoading) {
      return const _DiscoverySkeleton(key: ValueKey('discovery-loading'));
    }

    if (currentFeed == null && error != null) {
      return _DiscoveryError(
        key: const ValueKey('discovery-error'),
        onRetry: onRetry,
      );
    }

    if (currentFeed == null) {
      return const _DiscoverySkeleton(key: ValueKey('discovery-waiting'));
    }

    if (currentFeed.categories.isEmpty) {
      return _DiscoveryEmpty(
        key: ValueKey('discovery-empty-${currentFeed.feedId}'),
        onRetry: onRetry,
      );
    }

    return Column(
      key: ValueKey(currentFeed.feedId),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryQuickRail(
          categories: currentFeed.categories,
          onCategoryTap: onCategoryTap,
        ),
        const SizedBox(height: 22),
        for (var index = 0; index < currentFeed.categories.length; index++) ...[
          if (index > 0) const SizedBox(height: 16),
          _CategoryModule(
            category: currentFeed.categories[index],
            onTestTap: onTestTap,
            onCategoryTap: onCategoryTap,
          ),
        ],
      ],
    );
  }
}

class _DiscoveryHeading extends StatelessWidget {
  const _DiscoveryHeading({required this.onAllCategoriesTap});

  final VoidCallback onAllCategoriesTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Text(
                'Explore tests',
                style: TextStyle(
                  color: _DiscoveryPalette.ink,
                  fontSize: 22,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                ),
              ),
            ),
            TextButton(
              onPressed: onAllCategoriesTap,
              style: TextButton.styleFrom(
                foregroundColor: _DiscoveryPalette.primary,
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 7),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 17),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Browse by health need or choose an individual lab test.',
          style: TextStyle(
            color: _DiscoveryPalette.muted,
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CategoryQuickRail extends StatelessWidget {
  const _CategoryQuickRail({
    required this.categories,
    required this.onCategoryTap,
  });

  final List<HomeMedicalTestCategory> categories;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final style = medicalTestCategoryStyle(category.name);

          return Semantics(
            button: true,
            label: 'Open ${category.name}',
            child: SizedBox(
              width: 72,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onCategoryTap(category.name),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: style.soft,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: style.accent.withValues(alpha: .14),
                          ),
                        ),
                        child: Icon(style.icon, color: style.accent, size: 25),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _DiscoveryPalette.body,
                          fontSize: 9.8,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryModule extends StatelessWidget {
  const _CategoryModule({
    required this.category,
    required this.onTestTap,
    required this.onCategoryTap,
  });

  final HomeMedicalTestCategory category;
  final ValueChanged<MedicalTest> onTestTap;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(category.name);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _DiscoveryPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06111B30),
            blurRadius: 17,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: style.soft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(style.icon, color: style.accent, size: 21),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _DiscoveryPalette.ink,
                          fontSize: 17,
                          height: 1.16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _categorySubtitle(category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _DiscoveryPalette.muted,
                          fontSize: 11.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onCategoryTap(category.name),
                  tooltip: 'View all ${category.name} tests',
                  style: IconButton.styleFrom(
                    backgroundColor: _DiscoveryPalette.primarySoft,
                    foregroundColor: _DiscoveryPalette.primary,
                    minimumSize: const Size(40, 40),
                    maximumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 224,
            child: category.tests.isEmpty
                ? const _EmptyCategoryMessage()
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(right: 16),
                    itemCount: category.tests.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final test = category.tests[index];
                      return _HomeTestCard(
                        test: test,
                        onTap: () => onTestTap(test),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _categorySubtitle(HomeMedicalTestCategory category) {
  final name = category.name.toLowerCase();
  if (name.contains('liver')) return 'Liver function, enzymes and proteins';
  if (name.contains('kidney') || name.contains('urine')) {
    return 'Kidney function and urine screening';
  }
  if (name.contains('heart')) return 'Cholesterol and heart-risk checks';
  if (name.contains('diabetes')) return 'Blood sugar and diabetes checks';
  if (name.contains('thyroid')) return 'Thyroid function and hormone checks';
  if (name.contains('vitamin') || name.contains('mineral')) {
    return 'Vitamins and essential minerals';
  }
  if (name.contains('blood')) return 'Everyday blood health essentials';
  return '${category.totalCount} tests available';
}

class _HomeTestCard extends StatelessWidget {
  const _HomeTestCard({required this.test, required this.onTap});

  final MedicalTest test;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(test.category);

    return SizedBox(
      width: 162,
      child: Material(
        color: _DiscoveryPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: _DiscoveryPalette.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _DiscoveryPalette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MedicalTestArtwork(test: test, height: 86),
                const SizedBox(height: 9),
                Text(
                  test.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DiscoveryPalette.ink,
                    fontSize: 12.2,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  test.parameterCount == null
                      ? test.testTypeLabel
                      : '${test.parameterCount} parameters',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: style.accent,
                    fontSize: 9.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        test.priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _DiscoveryPalette.ink,
                          fontSize: 13.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      test.labVisitRequired
                          ? Icons.apartment_rounded
                          : Icons.home_work_outlined,
                      color: _DiscoveryPalette.textSoft,
                      size: 15,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCategoryMessage extends StatelessWidget {
  const _EmptyCategoryMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _DiscoveryPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DiscoveryPalette.border),
      ),
      child: const Text(
        'No tests available in this category yet.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _DiscoveryPalette.muted,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DiscoveryError extends StatelessWidget {
  const _DiscoveryError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _DiscoveryPalette.border),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: _DiscoveryPalette.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: _DiscoveryPalette.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tests could not be loaded',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _DiscoveryPalette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _DiscoveryPalette.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
            style: FilledButton.styleFrom(
              elevation: 0,
              backgroundColor: _DiscoveryPalette.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryEmpty extends StatelessWidget {
  const _DiscoveryEmpty({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _DiscoveryPalette.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.biotech_outlined,
            color: _DiscoveryPalette.primary,
            size: 34,
          ),
          const SizedBox(height: 10),
          const Text(
            'No tests available right now',
            style: TextStyle(
              color: _DiscoveryPalette.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _DiscoveryPalette.primary,
              side: const BorderSide(color: _DiscoveryPalette.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverySkeleton extends StatelessWidget {
  const _DiscoverySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SkeletonCategoryRail(),
        SizedBox(height: 22),
        _SkeletonModule(),
        SizedBox(height: 16),
        _SkeletonModule(),
      ],
    );
  }
}

class _SkeletonCategoryRail extends StatelessWidget {
  const _SkeletonCategoryRail();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < 4; index++) ...[
          if (index > 0) const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _DiscoveryPalette.skeleton,
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  width: 48,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _DiscoveryPalette.skeleton,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SkeletonModule extends StatelessWidget {
  const _SkeletonModule();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 304,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _DiscoveryPalette.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _DiscoveryPalette.skeleton,
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 15,
                      decoration: BoxDecoration(
                        color: _DiscoveryPalette.skeleton,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      width: 206,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _DiscoveryPalette.skeleton,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _DiscoveryPalette.skeleton,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: Row(
              children: [
                for (var index = 0; index < 2; index++) ...[
                  if (index > 0) const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _DiscoveryPalette.surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _DiscoveryPalette.border),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryPalette {
  const _DiscoveryPalette._();

  static const Color ink = Color(0xFF121528);
  static const Color body = Color(0xFF435067);
  static const Color muted = Color(0xFF71819A);
  static const Color textSoft = Color(0xFF91A1B7);
  static const Color primary = Color(0xFF2F67F5);
  static const Color primarySoft = Color(0xFFEAF2FF);
  static const Color surfaceSoft = Color(0xFFF8FAFD);
  static const Color border = Color(0xFFE1E8F1);
  static const Color skeleton = Color(0xFFE8EDF4);
}
