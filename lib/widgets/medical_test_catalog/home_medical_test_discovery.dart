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
                  Icon(
                    Icons.biotech_outlined,
                    color: HomeColors.primary,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'LAB TEST CATALOGUE',
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
                    style: TextStyle(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w800,
                    ),
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
          'Compare sample requirements, report timing and price before booking.',
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

class _HomeCategoryPalette {
  const _HomeCategoryPalette({
    required this.start,
    required this.end,
    required this.border,
    required this.accent,
    required this.soft,
  });

  final Color start;
  final Color end;
  final Color border;
  final Color accent;
  final Color soft;
}

const _lavenderPalette = _HomeCategoryPalette(
  start: Color(0xFFE7E2FF),
  end: Color(0xFFF5F3FF),
  border: Color(0xFFD6D0F3),
  accent: Color(0xFF5B5BD6),
  soft: Color(0xFFF8F7FF),
);

const _powderBluePalette = _HomeCategoryPalette(
  start: Color(0xFFD5E7F5),
  end: Color(0xFFEEF6FB),
  border: Color(0xFFC5DCEA),
  accent: Color(0xFF2563EB),
  soft: Color(0xFFF5F9FD),
);

const _mintPalette = _HomeCategoryPalette(
  start: Color(0xFFD5F3E9),
  end: Color(0xFFEFFBF7),
  border: Color(0xFFC2E5DA),
  accent: Color(0xFF0F766E),
  soft: Color(0xFFF4FBF9),
);

_HomeCategoryPalette _homeCategoryPalette(String category) {
  final name = category.toLowerCase();

  if (name.contains('thyroid') ||
      name.contains('hormone') ||
      name.contains('fertility') ||
      name.contains('vitamin') ||
      name.contains('mineral') ||
      name.contains('bone') ||
      name.contains('genetic') ||
      name.contains('women') ||
      name.contains('pregnancy')) {
    return _lavenderPalette;
  }

  if (name.contains('kidney') ||
      name.contains('urine') ||
      name.contains('liver') ||
      name.contains('digestive') ||
      name.contains('infection') ||
      name.contains('stool') ||
      name.contains('immunity') ||
      name.contains('autoimmune') ||
      name.contains('allergy') ||
      name.contains('sexual')) {
    return _mintPalette;
  }

  if (name.contains('blood') ||
      name.contains('heart') ||
      name.contains('diabetes') ||
      name.contains('respiratory') ||
      name.contains('cancer') ||
      name.contains('drug') ||
      name.contains('men')) {
    return _powderBluePalette;
  }

  final paletteIndex =
      category.runes.fold<int>(0, (total, rune) => total + rune) % 3;
  return switch (paletteIndex) {
    0 => _powderBluePalette,
    1 => _mintPalette,
    _ => _lavenderPalette,
  };
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
    final categoryStyle = medicalTestCategoryStyle(category.name);
    final palette = _homeCategoryPalette(category.name);

    return Container(
      key: ValueKey('home-category-module-${category.name}'),
      height: 408,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.start, palette.end],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07111B30),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .78),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.border),
                    ),
                    child: Icon(
                      categoryStyle.icon,
                      color: palette.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: HomeColors.textPrimary,
                            fontSize: 18,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.28,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _categorySubtitle(category),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: HomeColors.textSecondary,
                            fontSize: 11.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.white.withValues(alpha: .82),
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      onTap: () => onCategoryTap(category.name),
                      borderRadius: BorderRadius.circular(13),
                      child: Ink(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .82),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'See tests',
                              style: TextStyle(
                                color: palette.accent,
                                fontSize: 10.8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: palette.accent,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                key: ValueKey('home-category-tray-${category.name}'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .96),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE4EAF1)),
                ),
                child: category.tests.isEmpty
                    ? const _EmptyCategoryMessage()
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: category.tests.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 13),
                        itemBuilder: (context, index) {
                          final test = category.tests[index];
                          return _HomeTestCard(
                            test: test,
                            palette: palette,
                            onTap: () => onTestTap(test),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
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
  if (name.contains('heart')) {
    return '${category.totalCount} heart-health tests';
  }
  if (name.contains('diabetes')) {
    return '${category.totalCount} blood sugar tests';
  }
  if (name.contains('thyroid')) return '${category.totalCount} thyroid tests';
  if (name.contains('vitamin') || name.contains('mineral')) {
    return '${category.totalCount} vitamin and mineral tests';
  }
  return '${category.totalCount} available tests';
}

class _HomeTestCard extends StatelessWidget {
  const _HomeTestCard({
    required this.test,
    required this.palette,
    required this.onTap,
  });

  final MedicalTest test;
  final _HomeCategoryPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('home-test-card-${test.id}'),
      width: 238,
      child: Semantics(
        button: true,
        label: '${test.displayName}, ${test.priceLabel}',
        child: Material(
          color: palette.soft,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.soft,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: palette.border.withValues(alpha: .78),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _HomeTestIconBadge(test: test, palette: palette),
                      const Spacer(),
                      if (test.isPopular)
                        _TestBadge(
                          label: 'Common',
                          color: palette.accent,
                          background: Colors.white.withValues(alpha: .82),
                        )
                      else if (test.parameterCount != null)
                        _TestBadge(
                          label: '${test.parameterCount} markers',
                          color: HomeColors.textSecondary,
                          background: Colors.white.withValues(alpha: .82),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    test.displayName,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HomeColors.textPrimary,
                      fontSize: 14.2,
                      height: 1.24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.12,
                    ),
                  ),
                  const Spacer(),
                  _TestFact(
                    icon: Icons.science_outlined,
                    label: test.sampleLabel,
                  ),
                  const SizedBox(height: 9),
                  _TestFact(
                    icon: Icons.schedule_rounded,
                    label: test.reportLabel,
                  ),
                  const SizedBox(height: 13),
                  Container(
                    height: 1,
                    color: palette.border.withValues(alpha: .72),
                  ),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.15,
                          ),
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .86),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.border),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: palette.accent,
                          size: 18,
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

class _HomeTestIconBadge extends StatelessWidget {
  const _HomeTestIconBadge({required this.test, required this.palette});

  final MedicalTest test;
  final _HomeCategoryPalette palette;

  @override
  Widget build(BuildContext context) {
    final categoryStyle = medicalTestCategoryStyle(test.category);
    final badge = Material(
      color: Colors.transparent,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .84),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: Icon(categoryStyle.icon, color: palette.accent, size: 24),
      ),
    );

    if (test.id.isEmpty) return badge;
    return Hero(tag: medicalTestHeroTag(test), child: badge);
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
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9.2,
          fontWeight: FontWeight.w800,
        ),
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
        Icon(icon, color: HomeColors.textMuted, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: HomeColors.textSecondary,
              fontSize: 10.8,
              height: 1.2,
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
      children: [_SkeletonModule(), SizedBox(height: 16), _SkeletonModule()],
    );
  }
}

class _SkeletonModule extends StatelessWidget {
  const _SkeletonModule();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 408,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE7EEF6), Color(0xFFF4F7FB)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE6F0)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDF4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                  width: 82,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDF4),
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE4EAF1)),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 2,
                separatorBuilder: (_, _) => const SizedBox(width: 13),
                itemBuilder: (_, _) =>
                    const SizedBox(width: 238, child: _SkeletonTestCard()),
              ),
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
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE5EF)),
      ),
    );
  }
}
