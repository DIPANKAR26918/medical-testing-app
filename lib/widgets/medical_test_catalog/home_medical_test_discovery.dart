import 'package:flutter/material.dart';

import '../../models/medical_test.dart';
import '../home/home_constants.dart';
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
        const SizedBox(height: 15),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
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
                'Explore tests by health need',
                style: TextStyle(
                  color: HomeColors.textPrimary,
                  fontSize: 20,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.35,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAllCategoriesTap,
              style: TextButton.styleFrom(
                foregroundColor: HomeColors.primary,
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'All tests',
                    style: TextStyle(fontSize: 12.2, fontWeight: FontWeight.w800),
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
          'Fresh recommendations from Testified’s live medical catalogue.',
          style: TextStyle(
            color: HomeColors.textSecondary,
            fontSize: 12.2,
            height: 1.38,
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
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = categories[index];
          final style = medicalTestCategoryStyle(category.name);

          return SizedBox(
            width: 76,
            child: Semantics(
              button: true,
              label: 'Open ${category.name}',
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(17),
                child: InkWell(
                  onTap: () => onCategoryTap(category.name),
                  borderRadius: BorderRadius.circular(17),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: style.soft,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: style.accent.withValues(alpha: .11),
                            ),
                          ),
                          child: Icon(style.icon, color: style.accent, size: 24),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          category.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: HomeColors.textPrimary,
                            fontSize: 9.5,
                            height: 1.12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: style.accent.withValues(alpha: .10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: style.soft,
                  borderRadius: BorderRadius.circular(14),
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
                        color: HomeColors.textPrimary,
                        fontSize: 16.5,
                        height: 1.15,
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
                        color: HomeColors.textSecondary,
                        fontSize: 10.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => onCategoryTap(category.name),
                style: TextButton.styleFrom(
                  foregroundColor: style.accent,
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See all',
                      style: TextStyle(fontSize: 10.8, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, size: 15),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (category.tests.isEmpty)
            const _EmptyCategoryMessage()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: category.tests.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 174,
              ),
              itemBuilder: (context, index) {
                final test = category.tests[index];
                return _HomeTestCard(test: test, onTap: () => onTestTap(test));
              },
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
  if (name.contains('thyroid')) return 'Thyroid and hormone checks';
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

    return Semantics(
      button: true,
      label: '${test.displayName}, ${test.priceLabel}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HomeColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05111B30),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MedicalTestIconBadge(test: test, size: 38),
                    const Spacer(),
                    if (test.isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: style.soft,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'Popular',
                          style: TextStyle(
                            color: style.accent,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  test.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeColors.textPrimary,
                    fontSize: 11.8,
                    height: 1.18,
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
                  style: const TextStyle(
                    color: HomeColors.textMuted,
                    fontSize: 9.4,
                    fontWeight: FontWeight.w600,
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
                          color: HomeColors.textPrimary,
                          fontSize: 12.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: HomeColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: HomeColors.primary,
                        size: 14,
                      ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.border),
      ),
      child: const Text(
        'No tests available in this category yet.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: HomeColors.textMuted,
          fontSize: 11.5,
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
    return _DiscoveryMessageCard(
      icon: Icons.cloud_off_outlined,
      title: 'Tests could not be loaded',
      message: 'Check your connection and try again.',
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}

class _DiscoveryEmpty extends StatelessWidget {
  const _DiscoveryEmpty({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _DiscoveryMessageCard(
      icon: Icons.biotech_outlined,
      title: 'No tests available right now',
      message: 'The catalogue is being updated. Please try again shortly.',
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}

class _DiscoveryMessageCard extends StatelessWidget {
  const _DiscoveryMessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: HomeColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: HomeColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: HomeColors.primary, size: 25),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: HomeColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: HomeColors.textSecondary,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              elevation: 0,
              backgroundColor: HomeColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(actionLabel),
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
          if (index > 0) const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDF4),
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  width: 46,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDF4),
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
      height: 434,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HomeColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDF4),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 136,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EDF4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      width: 192,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EDF4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: HomeColors.border),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
