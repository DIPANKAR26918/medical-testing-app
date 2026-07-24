import 'dart:async';

import 'package:flutter/material.dart';

import '../models/medical_test.dart';
import '../services/medical_test_catalog_service.dart';
import '../utils/app_theme.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';
import 'direct_test_checkout_screen.dart';
import 'medical_test_detail_screen.dart';

class AllCategoriesPage extends StatefulWidget {
  const AllCategoriesPage({super.key});

  @override
  State<AllCategoriesPage> createState() => _AllCategoriesPageState();
}

class _AllCategoriesPageState extends State<AllCategoriesPage> {
  final MedicalTestCatalogService _catalogService = MedicalTestCatalogService();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, MedicalTest> _selectedTests = <String, MedicalTest>{};

  Timer? _searchDebounce;
  List<MedicalTestCategorySummary> _categories = const [];
  List<MedicalTest> _catalogTests = const [];
  List<MedicalTest> _searchResults = const [];
  String? _selectedCategory;
  Object? _error;
  bool _loading = true;
  bool _searching = false;
  int _requestToken = 0;

  String get _query => _searchController.text.trim();
  bool get _isRemoteSearch => _query.length >= 2;

  List<MedicalTest> get _visibleTests {
    if (_isRemoteSearch) return _searchResults;
    if (_query.isEmpty) return _catalogTests;

    final query = _query.toLowerCase();
    return _catalogTests.where((test) {
      return test.displayName.toLowerCase().contains(query) ||
          test.nameSheet.toLowerCase().contains(query) ||
          (test.testCode?.toLowerCase().contains(query) ?? false);
    }).toList(growable: false);
  }

  double get _selectedTotal => _selectedTests.values.fold<double>(
        0,
        (sum, test) => sum + (test.mrp ?? 0),
      );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadInitial();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final categories = await _catalogService.fetchCategories();
      final feed = await _catalogService.fetchHomeFeed(
        categoryLimit: 20,
        testsPerCategory: 8,
      );

      final uniqueTests = <String, MedicalTest>{};
      for (final category in feed.categories) {
        for (final test in category.tests) {
          uniqueTests[test.id] = test;
        }
      }

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _catalogTests = uniqueTests.values.toList(growable: false);
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();

    if (!_isRemoteSearch) {
      setState(() {
        _searching = false;
        _searchResults = const [];
      });
      return;
    }

    setState(() => _searching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 320), _runSearch);
  }

  Future<void> _runSearch() async {
    final query = _query;
    if (query.length < 2) return;

    final token = ++_requestToken;
    try {
      final results = await _catalogService.searchTests(
        query,
        category: _selectedCategory,
        limit: 40,
      );
      if (!mounted || token != _requestToken || query != _query) return;

      setState(() {
        _searchResults = results.map((result) => result.test).toList();
        _searching = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || token != _requestToken) return;
      setState(() {
        _searching = false;
        _error = error;
      });
    }
  }

  Future<void> _selectCategory(
    String? category, {
    bool force = false,
  }) async {
    if (!force && _selectedCategory == category && !_loading) return;

    _searchDebounce?.cancel();
    _requestToken++;
    _searchController.clear();
    setState(() {
      _selectedCategory = category;
      _loading = true;
      _searching = false;
      _searchResults = const [];
      _error = null;
    });

    try {
      final tests = category == null
          ? await _loadAllPreviewTests()
          : await _catalogService.fetchTestsByCategory(category);
      if (!mounted) return;

      setState(() {
        _catalogTests = tests;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<List<MedicalTest>> _loadAllPreviewTests() async {
    final feed = await _catalogService.fetchHomeFeed(
      categoryLimit: 20,
      testsPerCategory: 8,
    );
    final unique = <String, MedicalTest>{};
    for (final category in feed.categories) {
      for (final test in category.tests) {
        unique[test.id] = test;
      }
    }
    return unique.values.toList(growable: false);
  }

  void _toggleTest(MedicalTest test) {
    if (_selectedTests.containsKey(test.id)) {
      setState(() => _selectedTests.remove(test.id));
      return;
    }

    final eligibilityError = _eligibilityError(test);
    if (eligibilityError != null) {
      _showMessage(eligibilityError);
      return;
    }

    if (_selectedTests.length >= 30) {
      _showMessage('You can select up to 30 tests in one booking.');
      return;
    }

    final selectedMode = _selectedCollectionMode;
    final testMode = test.labVisitRequired
        ? _CollectionMode.labVisit
        : _CollectionMode.homeCollection;

    if (selectedMode != null && selectedMode != testMode) {
      _showMessage(
        'Home-collection and lab-visit tests need separate bookings.',
      );
      return;
    }

    setState(() => _selectedTests[test.id] = test);
  }

  _CollectionMode? get _selectedCollectionMode {
    if (_selectedTests.isEmpty) return null;
    return _selectedTests.values.first.labVisitRequired
        ? _CollectionMode.labVisit
        : _CollectionMode.homeCollection;
  }

  String? _eligibilityError(MedicalTest test) {
    if (test.mrp == null) {
      return 'This test needs price confirmation. Use prescription booking for now.';
    }
    if (!test.labVisitRequired && !test.homeCollectionAvailable) {
      return 'This test cannot be booked directly right now.';
    }
    return null;
  }

  void _openDetails(MedicalTest test) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedicalTestDetailScreen(test: test),
      ),
    );
  }

  void _reviewBooking() {
    if (_selectedTests.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DirectTestCheckoutScreen(
          tests: _selectedTests.values.toList(growable: false),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _refresh() async {
    if (_selectedCategory == null) {
      await _loadInitial();
    } else {
      await _selectCategory(_selectedCategory, force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleTests = _visibleTests;

    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(
        backgroundColor: _Palette.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text('Book lab tests'),
      ),
      body: RefreshIndicator(
        color: _Palette.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _IntroCard(
                  onUploadPrescription: () =>
                      Navigator.pushNamed(context, '/upload'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _SearchField(controller: _searchController),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 62,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 13, 16, 7),
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: _selectedCategory == null,
                      onTap: () => _selectCategory(null),
                    ),
                    for (final category in _categories) ...[
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: category.name,
                        selected: _selectedCategory == category.name,
                        onTap: () => _selectCategory(category.name),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              sliver: SliverToBoxAdapter(
                child: _ResultsHeader(
                  title: _isRemoteSearch
                      ? 'Search results'
                      : _selectedCategory ?? 'Recommended tests',
                  count: visibleTests.length,
                  searching: _searching,
                ),
              ),
            ),
            if (_loading)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverToBoxAdapter(child: _LoadingList()),
              )
            else if (_error != null && visibleTests.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                sliver: SliverToBoxAdapter(
                  child: _ErrorState(onRetry: _refresh),
                ),
              )
            else if (!_searching && visibleTests.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 120),
                sliver: SliverToBoxAdapter(child: _EmptyState()),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  _selectedTests.isEmpty ? 40 : 126,
                ),
                sliver: SliverList.separated(
                  itemCount: visibleTests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final test = visibleTests[index];
                    return _SelectableTestCard(
                      test: test,
                      selected: _selectedTests.containsKey(test.id),
                      enabled: _eligibilityError(test) == null,
                      onToggle: () => _toggleTest(test),
                      onDetails: () => _openDetails(test),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _selectedTests.isEmpty
          ? null
          : _SelectionBar(
              count: _selectedTests.length,
              total: _selectedTotal,
              mode: _selectedCollectionMode!,
              onReview: _reviewBooking,
            ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.onUploadPrescription});

  final VoidCallback onUploadPrescription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _Palette.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.science_outlined,
              color: _Palette.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select tests directly',
                  style: TextStyle(
                    color: _Palette.ink,
                    fontSize: 17,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose one or more tests, review the price and request your booking.',
                  style: TextStyle(
                    color: _Palette.muted,
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 9),
                TextButton.icon(
                  onPressed: onUploadPrescription,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: const Text('Have a prescription? Upload it'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search CBC, thyroid, vitamin D…',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              onPressed: controller.clear,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Clear search',
            );
          },
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _Palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _Palette.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _Palette.primary : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minWidth: 54),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _Palette.primary : _Palette.border,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : _Palette.muted,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.title,
    required this.count,
    required this.searching,
  });

  final String title;
  final int count;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _Palette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (searching)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Text(
            '$count available',
            style: const TextStyle(
              color: _Palette.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _SelectableTestCard extends StatelessWidget {
  const _SelectableTestCard({
    required this.test,
    required this.selected,
    required this.enabled,
    required this.onToggle,
    required this.onDetails,
  });

  final MedicalTest test;
  final bool selected;
  final bool enabled;
  final VoidCallback onToggle;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(test.category);

    return Semantics(
      button: true,
      selected: selected,
      label: '${selected ? 'Remove' : 'Select'} ${test.displayName}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? _Palette.primarySoft : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _Palette.primary : _Palette.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MedicalTestIconBadge(test: test, size: 48, useHero: false),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _Palette.ink,
                          fontSize: 14.5,
                          height: 1.25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        test.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: style.accent,
                          fontSize: 10.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 7,
                        runSpacing: 6,
                        children: [
                          _MetaChip(
                            icon: test.labVisitRequired
                                ? Icons.apartment_rounded
                                : Icons.home_work_outlined,
                            label: test.labVisitRequired
                                ? 'Lab visit'
                                : 'Home collection',
                          ),
                          _MetaChip(
                            icon: Icons.schedule_outlined,
                            label: test.reportLabel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              test.priceLabel,
                              style: const TextStyle(
                                color: _Palette.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: onDetails,
                            tooltip: 'View test details',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.info_outline_rounded,
                              color: _Palette.muted,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: selected
                                  ? _Palette.primary
                                  : enabled
                                      ? style.soft
                                      : const Color(0xFFF1F3F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              selected ? Icons.check_rounded : Icons.add_rounded,
                              color: selected
                                  ? Colors.white
                                  : enabled
                                      ? style.accent
                                      : const Color(0xFF98A2B3),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _Palette.muted),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _Palette.muted,
                fontSize: 10.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.total,
    required this.mode,
    required this.onReview,
  });

  final int count;
  final double total;
  final _CollectionMode mode;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _Palette.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 20,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count ${count == 1 ? 'test' : 'tests'} · ${_money(total)}',
                    style: const TextStyle(
                      color: _Palette.ink,
                      fontSize: 15,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode == _CollectionMode.labVisit
                        ? 'Lab visit booking'
                        : 'Home collection booking',
                    style: const TextStyle(
                      color: _Palette.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Palette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          height: 154,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF1F5),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.cloud_off_rounded,
      title: 'Tests could not load',
      subtitle: 'Check your connection and try again.',
      action: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const _StateCard(
      icon: Icons.search_off_rounded,
      title: 'No matching tests',
      subtitle: 'Try another test name or choose a different category.',
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: _Palette.muted, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _Palette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _Palette.muted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 10),
            action!,
          ],
        ],
      ),
    );
  }
}

String _money(double value) {
  final formatted = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return '₹$formatted';
}

enum _CollectionMode { homeCollection, labVisit }

class _Palette {
  const _Palette._();

  static const Color background = Color(0xFFF7F9FC);
  static const Color ink = Color(0xFF101828);
  static const Color muted = Color(0xFF667085);
  static const Color primary = Color(0xFF2563EB);
  static const Color primarySoft = Color(0xFFEEF4FF);
  static const Color border = Color(0xFFE2E8F0);
}
