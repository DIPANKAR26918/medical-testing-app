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
        const SizedBox(height: 17),
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
      children: [
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
          children: [
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: HomeColors.primarySoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: HomeColors.primary, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'FRESH PICKS',
                    style: TextStyle(
                      color: HomeColors.primaryDark,
                      fontSize: 9.4,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .55,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: onAllCategoriesTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: HomeColors.primary,
                side: const BorderSide(color: Color(0xFFD4E1F7)),
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'All tests',
                    style: TextStyle(fontSize: 11.2, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Explore tests by health need',
          style: TextStyle(
            color: HomeColors.textPrimary,
            fontSize: 22,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: -.42,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'A fresh mix appears on every visit. Pull down anytime to refresh.',
          style: TextStyle(
            color: HomeColors.textSecondary,
            fontSize: 11.7,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: style.accent.withValues(alpha: .12)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -56,
            top: -70,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: style.accent.withValues(alpha: .045),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(style.icon, color: style.accent, size: 23),
                      ),
                      const SizedBox(width: 12),
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
                                fontSize: 17.2,
                                height: 1.12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _categorySubtitle(category),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: HomeColors.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: style.accent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => onCategoryTap(category.name),
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 42,
                            height: 42,
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
                const SizedBox(height: 16),
                SizedBox(
                  height: 236,
                  child: category.tests.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: _EmptyCategoryMessage(),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(right: 16),
                          itemCount: category.tests.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 11),
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
    return '${category.totalCount} kidney and urine tests';
  }
  if (name.contains('heart')) return '${category.totalCount} heart-health tests';
  if (name.contains('diabetes')) return '${category.totalCount} blood sugar tests';
  if (name.contains('thyroid')) return '${category.totalCount} thyroid tests';
  if (name.contains('vitamin') || name.contains('mineral')) {
    return '${category.totalCount} vitamin and mineral tests';
  }
  return '${category.totalCount} available tests';
}

class _HomeTestCard extends StatelessWidget {
  const _HomeTestCard({required this.test, required this.onTap});

  final MedicalTest test;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(test.category);

    return SizedBox(
      width: 204,
      child: Semantics(
        button: true,
        label: '${test.displayName}, ${test.priceLabel}',
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(21),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: HomeColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06111B30),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MedicalTestIconBadge(test: test, size: 46),
                      const Spacer(),
                      if (test.isPopular)
                        _TestBadge(
                          label: 'Popular',
                          color: style.accent,
                          background: style.soft,
                        )
                      else if (test.parameterCount != null)
                        _TestBadge(
                          label: '${test.parameterCount} markers',
                          color: HomeColors.textSecondary,
                          background: HomeColors.surfaceSoft,
                        ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    test.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HomeColors.textPrimary,
                      fontSize: 13.2,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  _TestFact(icon: Icons.science_outlined, label: test.sampleLabel),
                  const SizedBox(height: 7),
                  _TestFact(icon: Icons.schedule_rounded, label: test.reportLabel),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          test.priceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: HomeColors.textPrimary,
                            fontSize: 14.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: style.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TestBadge extends StatelessWidget {
  const _TestBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 84),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 8.6, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TestFact extends StatelessWidget {
  const _TestFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: HomeColors.textMuted, size: 14),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: HomeColors.textSecondary,
              fontSize: 9.8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(21),
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
        _SkeletonModule(),
        SizedBox(height: 16),
        _SkeletonModule(),
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
      height: 332,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: HomeColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDF4),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 12),
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
                      width: 186,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EDF4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8EDF4),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _SkeletonTestCard()),
                SizedBox(width: 11),
                Expanded(child: _SkeletonTestCard()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonTestCard extends StatelessWidget {
  const _SkeletonTestCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: HomeColors.border),
      ),
    );
  }
}
