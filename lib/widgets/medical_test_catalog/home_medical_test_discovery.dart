import 'package:flutter/material.dart';

import '../../models/medical_test.dart';
import '../../utils/test_pricing.dart';
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
          if (index > 0) const SizedBox(height: 18),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tests by health need',
                style: TextStyle(
                  color: HomeColors.textPrimary,
                  fontSize: 22,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.42,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Compare collection, report time and price at a glance.',
                style: TextStyle(
                  color: HomeColors.textSecondary,
                  fontSize: 11.6,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onAllCategoriesTap,
          style: TextButton.styleFrom(
            foregroundColor: HomeColors.primary,
            backgroundColor: HomeColors.primarySoft,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
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
      name.contains('sugar') ||
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
    final palette = _homeCategoryPalette(category.name);
    final visibleTests = category.tests.take(4).toList(growable: false);

    return Container(
      key: ValueKey('home-category-module-${category.name}'),
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.start, palette.end],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: .075),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          const BoxShadow(
            color: Color(0x08111B30),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryHeader(
            category: category,
            palette: palette,
            onTap: () => onCategoryTap(category.name),
          ),
          const SizedBox(height: 15),
          Container(
            key: ValueKey('home-category-tray-${category.name}'),
            width: double.infinity,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .78),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: .88),
                width: 1.2,
              ),
            ),
            child: visibleTests.isEmpty
                ? const _EmptyCategoryMessage()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final cardHeight = constraints.maxWidth < 400
                          ? 228.0
                          : 214.0;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visibleTests.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              mainAxisExtent: cardHeight,
                            ),
                        itemBuilder: (context, index) {
                          final test = visibleTests[index];
                          return _HomeTestCard(
                            test: test,
                            palette: palette,
                            onTap: () => onTestTap(test),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.category,
    required this.palette,
    required this.onTap,
  });

  final HomeMedicalTestCategory category;
  final _HomeCategoryPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: .08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(9),
          child: MedicalCategoryIllustration(
            category: category.name,
            color: palette.accent,
          ),
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
                  fontSize: 18.2,
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
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: 'View all ${category.name} tests',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                height: 40,
                padding: const EdgeInsets.fromLTRB(11, 0, 8, 0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        color: palette.accent,
                        fontSize: 10.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _categorySubtitle(HomeMedicalTestCategory category) {
  final name = category.name.toLowerCase();
  final count = category.totalCount;

  if (name.contains('diabetes') || name.contains('sugar')) {
    return '$count glucose and HbA1c tests';
  }
  if (name.contains('blood')) return '$count blood tests and CBC panels';
  if (name.contains('kidney') || name.contains('urine')) {
    return '$count kidney and urine tests';
  }
  if (name.contains('liver')) return '$count liver function tests';
  if (name.contains('heart')) return '$count heart-health tests';
  if (name.contains('immunity')) return '$count immunity and protein tests';
  if (name.contains('allergy')) return '$count allergy screening tests';
  if (name.contains('thyroid')) return '$count thyroid tests';
  if (name.contains('vitamin') || name.contains('mineral')) {
    return '$count vitamin and mineral tests';
  }
  return '$count available tests';
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
    return Semantics(
      button: true,
      label:
          '${test.displayName}, ${test.collectionLabel}, report ${test.reportLabel}, '
          '${test.priceSemanticsLabel}',
      child: Material(
        key: ValueKey('home-test-card-${test.id}'),
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          overlayColor: WidgetStatePropertyAll(
            palette.accent.withValues(alpha: .06),
          ),
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: palette.border.withValues(alpha: .64),
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.accent.withValues(alpha: .055),
                  blurRadius: 15,
                  offset: const Offset(0, 7),
                ),
                const BoxShadow(
                  color: Color(0x06111B30),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TestVisual(test: test, palette: palette),
                const SizedBox(height: 9),
                Text(
                  test.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeColors.textPrimary,
                    fontSize: 12.6,
                    height: 1.22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.08,
                  ),
                ),
                const SizedBox(height: 6),
                _CompactFact(
                  icon: Icons.schedule_rounded,
                  label: test.reportLabel,
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _HomeTestPrice(test: test)),
                    const SizedBox(width: 6),
                    Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: palette.accent.withValues(alpha: .18),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 17,
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


class _TestVisual extends StatelessWidget {
  const _TestVisual({required this.test, required this.palette});

  final MedicalTest test;
  final _HomeCategoryPalette palette;

  @override
  Widget build(BuildContext context) {
    final markerCount = test.parameterCount;
    final badgeLabel = test.isPopular
        ? 'Popular'
        : markerCount != null && markerCount > 0
        ? '$markerCount markers'
        : test.testTypeLabel;
    final collectionLabel = test.labVisitRequired
        ? 'Lab visit'
        : test.homeCollectionAvailable
        ? 'At home'
        : 'Check first';
    final collectionIcon = test.labVisitRequired
        ? Icons.location_on_outlined
        : test.homeCollectionAvailable
        ? Icons.home_outlined
        : Icons.info_outline_rounded;

    final iconTile = Material(
      color: Colors.transparent,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: palette.accent.withValues(alpha: .11),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(9),
        child: MedicalCategoryIllustration(
          category: test.category,
          color: palette.accent,
        ),
      ),
    );

    return Container(
      key: ValueKey('home-test-visual-${test.id}'),
      height: 86,
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: palette.border.withValues(alpha: .78)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 8,
            top: 14,
            child: test.id.isEmpty
                ? iconTile
                : Hero(tag: medicalTestHeroTag(test), child: iconTile),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: _VisualLabel(
              label: badgeLabel,
              foreground: palette.accent,
              border: palette.border,
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: _VisualLabel(
              icon: collectionIcon,
              label: collectionLabel,
              foreground: HomeColors.textSecondary,
              iconColor: palette.accent,
              border: palette.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualLabel extends StatelessWidget {
  const _VisualLabel({
    required this.label,
    required this.foreground,
    required this.border,
    this.icon,
    this.iconColor,
  });

  final IconData? icon;
  final String label;
  final Color foreground;
  final Color? iconColor;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 82),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? foreground, size: 11),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 8.6,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTestPrice extends StatelessWidget {
  const _HomeTestPrice({required this.test});

  final MedicalTest test;

  @override
  Widget build(BuildContext context) {
    final mrp = test.mrp;
    final offer = test.sellingPrice;
    final hasOffer = mrp != null && offer != null && offer < mrp;

    if (!hasOffer) {
      return Text(
        test.priceLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: HomeColors.textPrimary,
          fontSize: 14.5,
          height: 1.1,
          fontWeight: FontWeight.w900,
          letterSpacing: -.12,
        ),
      );
    }

    return Semantics(
      label:
          '${test.priceSemanticsLabel}, ${TestPricing.discountPercent} percent off',
      child: ExcludeSemantics(
        child: Wrap(
          key: ValueKey('home-test-price-${test.id}'),
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 5,
          runSpacing: 2,
          children: [
            Text(
              test.priceLabel,
              maxLines: 1,
              style: const TextStyle(
                color: HomeColors.textPrimary,
                fontSize: 14.6,
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: -.12,
              ),
            ),
            Text(
              test.mrpLabel,
              maxLines: 1,
              style: const TextStyle(
                color: HomeColors.textMuted,
                fontSize: 8.7,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.lineThrough,
                decorationColor: HomeColors.textMuted,
                decorationThickness: 1.35,
              ),
            ),
            const Text(
              '${TestPricing.discountPercent}% off',
              maxLines: 1,
              style: TextStyle(
                color: Color(0xFF15803D),
                fontSize: 8.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactFact extends StatelessWidget {
  const _CompactFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: HomeColors.textMuted, size: 12.5),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: HomeColors.textSecondary,
              fontSize: 9.4,
              height: 1.2,
              fontWeight: FontWeight.w600,
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
        borderRadius: BorderRadius.circular(17),
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
      children: [_SkeletonModule(), SizedBox(height: 18), _SkeletonModule()],
    );
  }
}

class _SkeletonModule extends StatelessWidget {
  const _SkeletonModule();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
            height: 48,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDF4),
                    borderRadius: BorderRadius.circular(15),
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
                        width: 174,
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
                  width: 78,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDF4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE4EAF1)),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 214,
              ),
              itemBuilder: (_, _) => const _SkeletonTestCard(),
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
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFDCE5EF)),
      ),
    );
  }
}
