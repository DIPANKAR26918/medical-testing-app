import 'package:flutter/material.dart';

import '../models/medical_test.dart';
import '../services/medical_test_catalog_service.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';
import 'medical_test_detail_screen.dart';

class CategoryTestsScreen extends StatefulWidget {
  const CategoryTestsScreen({
    required this.category,
    this.initialCount,
    super.key,
  });

  final String category;
  final int? initialCount;

  @override
  State<CategoryTestsScreen> createState() => _CategoryTestsScreenState();
}

class _CategoryTestsScreenState extends State<CategoryTestsScreen> {
  final MedicalTestCatalogService _catalogService = MedicalTestCatalogService();
  final TextEditingController _searchController = TextEditingController();

  List<MedicalTest> _tests = const [];
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTests();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTests() async {
    if (_tests.isEmpty && !_isLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final tests = await _catalogService.fetchTestsByCategory(widget.category);
      if (!mounted) return;
      setState(() {
        _tests = tests;
        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  List<MedicalTest> get _visibleTests {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _tests;

    return _tests
        .where((test) {
          return test.displayName.toLowerCase().contains(query) ||
              test.nameSheet.toLowerCase().contains(query) ||
              (test.testCode?.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false);
  }

  void _openTest(MedicalTest test) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedicalTestDetailScreen(test: test),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(widget.category);
    final visibleTests = _visibleTests;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        title: const Text('Medical tests'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTests,
        color: style.accent,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _CategoryHeader(
                  category: widget.category,
                  count: _tests.isEmpty ? widget.initialCount : _tests.length,
                  style: style,
                  searchController: _searchController,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            if (_isLoading)
              const SliverToBoxAdapter(child: _CategoryLoading())
            else if (_error != null && _tests.isEmpty)
              SliverToBoxAdapter(child: _CategoryError(onRetry: _loadTests))
            else if (visibleTests.isEmpty)
              SliverToBoxAdapter(
                child: _CategoryEmpty(
                  hasSearch: _searchController.text.trim().isNotEmpty,
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text(
                        '${visibleTests.length} tests for you',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: style.soft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Verified catalogue',
                          style: TextStyle(
                            color: style.accent,
                            fontSize: 9.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 205,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: .62,
                      ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final test = visibleTests[index];
                      return MedicalTestMarketplaceGridCard(
                        test: test,
                        onTap: () => _openTest(test),
                      );
                    },
                    childCount: visibleTests.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.category,
    required this.count,
    required this.style,
    required this.searchController,
  });

  final String category;
  final int? count;
  final MedicalTestCategoryStyle style;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradient,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: style.accent.withValues(alpha: .12)),
        boxShadow: [
          BoxShadow(
            color: style.accent.withValues(alpha: .065),
            blurRadius: 26,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -58,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: style.accent.withValues(alpha: .055),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: style.accent.withValues(alpha: .12),
                        ),
                      ),
                      child: Icon(style.icon, color: style.accent, size: 27),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 21,
                              height: 1.14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.38,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            count == null
                                ? 'Loading tests…'
                                : '$count tests available',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .76),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            color: style.accent,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: style.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search in $category',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: searchController,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return IconButton(
                          onPressed: searchController.clear,
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Clear search',
                        );
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .92),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: style.accent.withValues(alpha: .10),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: style.accent,
                        width: 1.4,
                      ),
                    ),
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

class _CategoryLoading extends StatelessWidget {
  const _CategoryLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 205,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: .62,
        ),
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEDF1F5),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _CategoryError extends StatelessWidget {
  const _CategoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 38),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFF64748B),
            size: 30,
          ),
          const SizedBox(height: 10),
          const Text(
            'Could not load these tests',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _CategoryEmpty extends StatelessWidget {
  const _CategoryEmpty({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: Color(0xFF94A3B8),
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            hasSearch
                ? 'No test matches your search.'
                : 'No active tests are available in this category.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
