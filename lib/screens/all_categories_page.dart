import 'package:flutter/material.dart';

import '../models/medical_test.dart';
import '../services/medical_test_catalog_service.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';
import 'category_tests_screen.dart';

class AllCategoriesPage extends StatefulWidget {
  const AllCategoriesPage({super.key});

  @override
  State<AllCategoriesPage> createState() => _AllCategoriesPageState();
}

class _AllCategoriesPageState extends State<AllCategoriesPage> {
  final MedicalTestCatalogService _catalogService = MedicalTestCatalogService();
  final TextEditingController _searchController = TextEditingController();

  List<MedicalTestCategorySummary> _categories = const [];
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCategories();
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

  Future<void> _loadCategories() async {
    if (_categories.isEmpty && !_isLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final categories = await _catalogService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
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

  List<MedicalTestCategorySummary> get _visibleCategories {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _categories;

    return _categories
        .where((category) => category.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  void _openCategory(MedicalTestCategorySummary category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryTestsScreen(
          category: category.name,
          initialCount: category.testCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleCategories = _visibleCategories;
    final totalTests = _categories.fold<int>(
      0,
      (total, category) => total + category.testCount,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        title: const Text('Explore tests'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCategories,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnCount = constraints.maxWidth >= 720 ? 3 : 2;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _CatalogueHeader(
                  categoryCount: _categories.length,
                  testCount: totalTests,
                  searchController: _searchController,
                ),
                const SizedBox(height: 18),
                if (_isLoading)
                  _CategoryGridSkeleton(columnCount: columnCount)
                else if (_error != null && _categories.isEmpty)
                  _CategoriesError(onRetry: _loadCategories)
                else if (visibleCategories.isEmpty)
                  const _NoCategoryMatch()
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleCategories.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.18,
                    ),
                    itemBuilder: (context, index) {
                      final category = visibleCategories[index];
                      return _CategoryTile(
                        category: category,
                        onTap: () => _openCategory(category),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CatalogueHeader extends StatelessWidget {
  const _CatalogueHeader({
    required this.categoryCount,
    required this.testCount,
    required this.searchController,
  });

  final int categoryCount;
  final int testCount;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FBFF), Color(0xFFEFF6FF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDCE7F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find the right lab test',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 21,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            categoryCount == 0
                ? 'Loading the medical-test catalogue…'
                : '$testCount tests across $categoryCount categories',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search categories',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: searchController,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    onPressed: searchController.clear,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Clear search',
                  );
                },
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: .90),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final MedicalTestCategorySummary category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(category.name);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: style.gradient,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: style.accent.withValues(alpha: .10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 41,
                    height: 41,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .76),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(style.icon, color: style.accent, size: 21),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: style.accent,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13.5,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${category.testCount} tests',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGridSkeleton extends StatelessWidget {
  const _CategoryGridSkeleton({required this.columnCount});

  final int columnCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (_, _) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3F7),
            borderRadius: BorderRadius.circular(22),
          ),
        );
      },
    );
  }
}

class _CategoriesError extends StatelessWidget {
  const _CategoriesError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFF64748B),
            size: 32,
          ),
          const SizedBox(height: 10),
          const Text(
            'Could not load categories',
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

class _NoCategoryMatch extends StatelessWidget {
  const _NoCategoryMatch();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: Color(0xFF94A3B8), size: 34),
          SizedBox(height: 10),
          Text(
            'No category matches your search.',
            style: TextStyle(
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
