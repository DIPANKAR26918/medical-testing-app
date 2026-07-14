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
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
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
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _CategoryHeader(
              category: widget.category,
              count: _tests.isEmpty ? widget.initialCount : _tests.length,
              style: style,
              searchController: _searchController,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const _CategoryLoading()
            else if (_error != null && _tests.isEmpty)
              _CategoryError(onRetry: _loadTests)
            else if (visibleTests.isEmpty)
              _CategoryEmpty(
                hasSearch: _searchController.text.trim().isNotEmpty,
              )
            else
              for (var index = 0; index < visibleTests.length; index++) ...[
                if (index > 0) const SizedBox(height: 10),
                MedicalTestListCard(
                  test: visibleTests[index],
                  onTap: () => _openTest(visibleTests[index]),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradient,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: style.accent.withValues(alpha: .10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .74),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(style.icon, color: style.accent, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count == null
                          ? 'Loading tests…'
                          : '$count tests available',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search in $category',
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
              fillColor: Colors.white.withValues(alpha: .88),
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
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
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
