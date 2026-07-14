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
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        title: const Text('Test catalogue'),
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
                parent: ClampingScrollPhysics(),
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
                      childAspectRatio: .96,
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123B83), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x242563EB),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -48,
            top: -62,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .075),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.biotech_rounded,
                      color: Color(0xFFBFDBFE),
                      size: 18,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'TESTIFIED CATALOGUE',
                      style: TextStyle(
                        color: Color(0xFFDBEAFE),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Find the right lab test',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.45,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    categoryCount == 0
                        ? 'Loading the medical-test catalogue…'
                        : '$testCount tests  •  $categoryCount categories',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search health categories',
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
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFBFDBFE),
                        width: 1.5,
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final MedicalTestCategorySummary category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(category.name);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE3E9F1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B0F172A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, style.soft],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: style.accent.withValues(alpha: .10),
                      ),
                    ),
                    child: Icon(style.icon, color: style.accent, size: 22),
                  ),
                  const Spacer(),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: style.soft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                      color: style.accent,
                    ),
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
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.1,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    '${category.testCount} tests',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (category.popularCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${category.popularCount} popular',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: style.accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 3,
                width: 32,
                decoration: BoxDecoration(
                  color: style.accent,
                  borderRadius: BorderRadius.circular(999),
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
        childAspectRatio: .96,
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
