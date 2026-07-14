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
          isRefreshing: isLoading && feed != null,
          onRefresh: onRetry,
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
    if (isLoading && currentFeed == null) {
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
        for (var index = 0; index < currentFeed.categories.length; index++) ...[
          if (index > 0) const SizedBox(height: 24),
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
  const _DiscoveryHeading({
    required this.isRefreshing,
    required this.onRefresh,
    required this.onAllCategoriesTap,
  });

  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onAllCategoriesTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF2563EB),
                    size: 14,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'FRESH PICKS',
                    style: TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontSize: 10,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _HeaderIconButton(
              tooltip: 'Refresh test recommendations',
              onTap: isRefreshing ? null : onRefresh,
              child: isRefreshing
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onAllCategoriesTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: const Color(0xFF1D4ED8),
                side: const BorderSide(color: Color(0xFFD7E3F5)),
                backgroundColor: Colors.white,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('All tests'),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Explore tests by health need',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            height: 1.12,
            fontWeight: FontWeight.w900,
            letterSpacing: -.45,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'A new mix appears on every visit. Pull down anytime to refresh.',
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDE5EF)),
            ),
            child: child,
          ),
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: style.soft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(style.icon, color: style.accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16.5,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => onCategoryTap(category.name),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: style.accent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View ${category.totalCount}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 238,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: style.gradient,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: style.accent.withValues(alpha: .12)),
            boxShadow: [
              BoxShadow(
                color: style.accent.withValues(alpha: .055),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -38,
                top: -46,
                child: _DecorativeCircle(
                  size: 132,
                  color: style.accent.withValues(alpha: .055),
                ),
              ),
              Positioned(
                left: -35,
                bottom: -62,
                child: _DecorativeCircle(
                  size: 120,
                  color: Colors.white.withValues(alpha: .30),
                ),
              ),
              ListView.separated(
                padding: const EdgeInsets.all(14),
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: category.tests.length,
                separatorBuilder: (_, _) => const SizedBox(width: 11),
                itemBuilder: (context, index) {
                  final test = category.tests[index];
                  return MedicalTestCompactCard(
                    test: test,
                    onTap: () => onTestTap(test),
                  );
                },
              ),
            ],
          ),
        ),
      ],
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
        _SkeletonModule(),
        SizedBox(height: 24),
        _SkeletonModule(),
      ],
    );
  }
}

class _SkeletonModule extends StatelessWidget {
  const _SkeletonModule();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EDF3),
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 132,
              height: 17,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EDF3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 238,
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F8),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              for (var index = 0; index < 2; index++) ...[
                if (index > 0) const SizedBox(width: 11),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(21),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
