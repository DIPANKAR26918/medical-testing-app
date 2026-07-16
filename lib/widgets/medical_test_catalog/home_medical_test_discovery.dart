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
        _DiscoveryHeading(
          onAllCategoriesTap: onAllCategoriesTap,
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 360),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(0, .018),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
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

    return Column(
      key: ValueKey(currentFeed.feedId),
      children: [
        _CategoryQuickRail(
          categories: currentFeed.categories,
          onCategoryTap: onCategoryTap,
        ),
        const SizedBox(height: 24),
        for (var index = 0; index < currentFeed.categories.length; index++) ...[
          if (index > 0) const SizedBox(height: 24),
          _CategoryModule(
            category: currentFeed.categories[index],
            layoutIndex: index,
            onTestTap: onTestTap,
            onCategoryTap: onCategoryTap,
          ),
        ],
      ],
    );
  }
}

class _DiscoveryHeading extends StatelessWidget {
  const _DiscoveryHeading({
    required this.onAllCategoriesTap,
  });

  final VoidCallback onAllCategoriesTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tests for every health need',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 22,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.45,
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: onAllCategoriesTap,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: const Color(0xFF1D4ED8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Fresh categories and test picks on every visit.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12.6,
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
      height: 91,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 13),
        itemBuilder: (context, index) {
          final category = categories[index];
          final style = medicalTestCategoryStyle(category.name);

          return Semantics(
            button: true,
            label: 'Open ${category.name}',
            child: SizedBox(
              width: 67,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onCategoryTap(category.name),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, style.soft],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: style.accent.withValues(alpha: .12),
                          ),
                        ),
                        child: Icon(
                          style.icon,
                          color: style.accent,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF334155),
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
    required this.layoutIndex,
    required this.onTestTap,
    required this.onCategoryTap,
  });

  final HomeMedicalTestCategory category;
  final int layoutIndex;
  final ValueChanged<MedicalTest> onTestTap;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(category.name);
    final useGrid = layoutIndex % 3 == 2 && category.tests.length >= 4;

    return Container(
      height: useGrid ? 548 : 364,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.soft, style.tint],
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: style.accent.withValues(alpha: .12)),
        boxShadow: [
          BoxShadow(
            color: style.accent.withValues(alpha: .065),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -55,
            child: _DecorativeCircle(
              size: 145,
              color: style.accent.withValues(alpha: .06),
            ),
          ),
          Positioned(
            left: -46,
            bottom: -74,
            child: _DecorativeCircle(
              size: 142,
              color: Colors.white.withValues(alpha: .34),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 17, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(style.icon, color: style.accent, size: 15),
                              const SizedBox(width: 5),
                              Text(
                                'CURATED HEALTH PICKS',
                                style: TextStyle(
                                  color: style.accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .55,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 20,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.38,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _categoryModuleSubtitle(category),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: style.accent,
                      borderRadius: BorderRadius.circular(99),
                      child: InkWell(
                        onTap: () => onCategoryTap(category.name),
                        borderRadius: BorderRadius.circular(99),
                        child: const SizedBox(
                          width: 47,
                          height: 39,
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: useGrid
                    ? Container(
                        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .90),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .88),
                          ),
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 4,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 11,
                                mainAxisSpacing: 12,
                                childAspectRatio: .78,
                              ),
                          itemBuilder: (context, index) {
                            final test = category.tests[index];
                            return _MedicalTestGridTile(
                              test: test,
                              onTap: () => onTestTap(test),
                            );
                          },
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        itemCount: category.tests.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 13),
                        itemBuilder: (context, index) {
                          final test = category.tests[index];
                          return MedicalTestCompactCard(
                            test: test,
                            onTap: () => onTestTap(test),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _categoryModuleSubtitle(HomeMedicalTestCategory category) {
  final name = category.name.toLowerCase();
  if (name.contains('liver')) return 'Liver health, enzymes and proteins';
  if (name.contains('kidney') || name.contains('urine')) {
    return 'Kidney function and urine screening';
  }
  if (name.contains('heart')) return 'Cholesterol and heart-risk checks';
  if (name.contains('diabetes')) return 'Sugar control and diabetes checks';
  if (name.contains('thyroid')) return 'Thyroid function and hormone checks';
  if (name.contains('vitamin') || name.contains('mineral')) {
    return 'Weakness, vitamins and essential minerals';
  }
  if (name.contains('blood')) return 'Everyday blood health essentials';
  return '${category.totalCount} tests available for this health need';
}

class _MedicalTestGridTile extends StatelessWidget {
  const _MedicalTestGridTile({required this.test, required this.onTap});

  final MedicalTest test;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(test.category);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MedicalTestArtwork(test: test, height: 94),
              const SizedBox(height: 8),
              Text(
                test.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 11.8,
                  height: 1.20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                test.parameterCount == null
                    ? test.testTypeLabel
                    : '${test.parameterCount} markers',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: style.accent,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
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
                        color: Color(0xFF0F172A),
                        fontSize: 13.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    test.labVisitRequired
                        ? Icons.apartment_rounded
                        : Icons.home_work_outlined,
                    color: style.accent,
                    size: 15,
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

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tests could not be loaded',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Check your connection and try once more.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
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
        SizedBox(height: 24),
        _SkeletonModule(height: 364),
        SizedBox(height: 24),
        _SkeletonModule(height: 364),
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
          if (index > 0) const SizedBox(width: 13),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EDF3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  width: 45,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EDF3),
                    borderRadius: BorderRadius.circular(999),
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
  const _SkeletonModule({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 17, 15, 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 158,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EDF3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const Spacer(),
              Container(
                width: 46,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE3EA),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            width: 215,
            height: 11,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E7ED),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              children: [
                for (var index = 0; index < 2; index++) ...[
                  if (index > 0) const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 126,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .88),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1E6EC),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 82,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1E6EC),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
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
