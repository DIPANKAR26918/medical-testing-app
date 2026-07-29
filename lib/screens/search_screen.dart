import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medical_test.dart';
import '../models/recent_test_search.dart';
import '../services/medical_test_catalog_service.dart';
import '../services/test_view_history_service.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';
import 'medical_test_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({this.catalogService, super.key});

  final MedicalTestSearchRepository? catalogService;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // v3 stores selected test records. The old key contained raw typed fragments,
  // so it is intentionally not migrated.
  static const _recentKey = medicalTestRecentSearchesStorageKey;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final MedicalTestSearchRepository _catalogService;

  Timer? _debounce;
  List<MedicalTestSearchResult> _results = const [];
  List<MedicalTestCategorySummary> _categories = const [];
  List<RecentTestSearch> _recentSearches = const [];
  String? _selectedCategory;
  Object? _error;
  bool _loading = true;
  int _requestGeneration = 0;

  bool get _hasQuery => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _catalogService = widget.catalogService ?? MedicalTestCatalogService();
    _bootstrap();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = decodeRecentTestSearches(
      prefs.getStringList(_recentKey) ?? const <String>[],
    );
    await prefs.remove(legacyMedicalTestRecentSearchesStorageKey);

    try {
      final values = await Future.wait<dynamic>([
        _catalogService.fetchCategories(),
        _catalogService.searchTests('', limit: 12),
      ]);
      if (!mounted) return;
      setState(() {
        _recentSearches = recent;
        _categories = values[0] as List<MedicalTestCategorySummary>;
        _results = values[1] as List<MedicalTestSearchResult>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _recentSearches = recent;
        _error = error;
        _loading = false;
      });
    }
  }

  void _onQueryChanged(String value) {
    _requestGeneration++;
    setState(() {
      if (value.trim().isNotEmpty) _selectedCategory = null;
      _loading = true;
      _error = null;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), _search);
  }

  Future<void> _search() async {
    final generation = ++_requestGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await _catalogService.searchTests(
        _controller.text,
        category: _selectedCategory,
        limit: _hasQuery ? 40 : 12,
      );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _selectCategory(String? category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
    _search();
  }

  void _useSearchPhrase(String value) {
    _controller
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    _onQueryChanged(value);
  }

  Future<void> _openTest(MedicalTestSearchResult result) async {
    unawaited(
      TestViewHistoryService.shared.recordInteraction(
        result.test,
        TestInteractionType.searchOpen,
      ),
    );
    final next = recordRecentTestSelection(_recentSearches, result.test);

    setState(() => _recentSearches = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recentKey,
      next.map((item) => item.toStorageValue()).toList(growable: false),
    );

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedicalTestDetailScreen(test: result.test),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _SearchPalette.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _SearchPalette.surface,
        body: Column(
          children: [
            _SearchHeader(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onQueryChanged,
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const _SearchSkeleton();
    if (_error != null && _results.isEmpty) {
      return _SearchError(onRetry: _search);
    }

    if (_results.isEmpty) {
      return _EmptySearchState(
        query: _controller.text.trim(),
        onUpload: () => Navigator.pushNamed(context, '/upload'),
      );
    }

    if (_hasQuery) {
      return ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 28),
        itemCount: _results.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          indent: 72,
          color: _SearchPalette.border,
        ),
        itemBuilder: (context, index) {
          final result = _results[index];
          return _SearchSuggestionRow(
            result: result,
            onTap: () => _openTest(result),
            onUseSuggestion: () => _useSearchPhrase(result.test.displayName),
          );
        },
      );
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        if (_recentSearches.isNotEmpty) ...[
          _SearchSection(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeading(title: 'Recent searches'),
                const SizedBox(height: 14),
                _RecentSearchStrip(
                  searches: _recentSearches,
                  onTap: (item) => _useSearchPhrase(item.name),
                ),
              ],
            ),
          ),
          const _SearchSectionDivider(),
        ],
        if (_categories.isNotEmpty) ...[
          _SearchSection(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeading(title: 'Browse by category'),
                const SizedBox(height: 14),
                _CategoryGrid(
                  categories: _categories,
                  selected: _selectedCategory,
                  onSelected: _selectCategory,
                ),
              ],
            ),
          ),
          const _SearchSectionDivider(),
        ],
        _SearchSection(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading(
                title: _selectedCategory ?? 'Popular tests',
                subtitle: _selectedCategory == null
                    ? 'Frequently booked tests with home collection'
                    : 'Available tests in this category',
              ),
              const SizedBox(height: 14),
              _PopularTestGrid(
                results: _results,
                onTap: _openTest,
              ),
              const SizedBox(height: 22),
              _PrescriptionSearchCard(
                onTap: () => Navigator.pushNamed(context, '/upload'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);

    return Container(
      key: const ValueKey('medical-test-search-header'),
      padding: EdgeInsets.fromLTRB(
        safePadding.left + 8,
        safePadding.top + 10,
        safePadding.right + 14,
        15,
      ),
      decoration: const BoxDecoration(
        color: _SearchPalette.header,
        border: Border(bottom: BorderSide(color: _SearchPalette.headerBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            tooltip: 'Back',
            color: _SearchPalette.ink,
            iconSize: 28,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: focusNode.requestFocus,
              child: Container(
                key: const ValueKey('medical-test-search-surface'),
                height: 56,
                padding: const EdgeInsets.only(left: 16, right: 17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _SearchPalette.searchBorder,
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x337DAAF0),
                      blurRadius: 8,
                      spreadRadius: .6,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: _SearchPalette.muted,
                      size: 26,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('medical-test-search-field'),
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: onChanged,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                        cursorColor: _SearchPalette.primary,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        style: const TextStyle(
                          color: _SearchPalette.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search tests or test codes',
                          hintStyle: TextStyle(
                            color: _SearchPalette.muted,
                            fontWeight: FontWeight.w500,
                          ),
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSection extends StatelessWidget {
  const _SearchSection({
    required this.child,
    required this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _SearchPalette.surface,
      child: Padding(padding: padding, child: child),
    );
  }
}

class _SearchSectionDivider extends StatelessWidget {
  const _SearchSectionDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 10,
      child: ColoredBox(color: _SearchPalette.background),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<MedicalTestCategorySummary> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = categories.take(5).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index <= visibleCategories.length; index++)
              SizedBox(
                width: tileWidth,
                child: _CategoryTile(
                  category: index == 0
                      ? null
                      : visibleCategories[index - 1].name,
                  selected:
                      selected ==
                      (index == 0
                          ? null
                          : visibleCategories[index - 1].name),
                  onTap: onSelected,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final String? category;
  final bool selected;
  final ValueChanged<String?> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _SearchPalette.primarySoft : _SearchPalette.tile,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () => onTap(category),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? _SearchPalette.searchBorder
                  : _SearchPalette.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : _SearchPalette.primarySoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: category == null
                    ? const Icon(
                        Icons.biotech_rounded,
                        color: _SearchPalette.primary,
                        size: 21,
                      )
                    : MedicalCategoryIllustration(
                        category: category!,
                        color: _SearchPalette.primary,
                      ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  category ?? 'All tests',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? _SearchPalette.primary
                        : _SearchPalette.ink,
                    fontSize: 12.4,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _SearchPalette.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              color: _SearchPalette.muted,
              fontSize: 12.2,
              height: 1.35,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}

class _RecentSearchStrip extends StatelessWidget {
  const _RecentSearchStrip({
    required this.searches,
    required this.onTap,
  });

  final List<RecentTestSearch> searches;
  final ValueChanged<RecentTestSearch> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: searches.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final search = searches[index];
          return SizedBox(
            width: 88,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(search),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _SearchPalette.tile,
                          shape: BoxShape.circle,
                          border: Border.all(color: _SearchPalette.border),
                        ),
                        child: MedicalCategoryIllustration(
                          category: search.category,
                          color: _SearchPalette.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        search.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _SearchPalette.ink,
                          fontSize: 11.4,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _SearchSuggestionRow extends StatelessWidget {
  const _SearchSuggestionRow({
    required this.result,
    required this.onTap,
    this.onUseSuggestion,
  });

  final MedicalTestSearchResult result;
  final VoidCallback onTap;
  final VoidCallback? onUseSuggestion;

  @override
  Widget build(BuildContext context) {
    final test = result.test;

    return Material(
      color: _SearchPalette.surface,
      child: InkWell(
        key: ValueKey('search-result-${test.id}'),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 74),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _SearchPalette.primarySoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: MedicalCategoryIllustration(
                    category: test.category,
                    color: _SearchPalette.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        test.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _SearchPalette.ink,
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        test.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _SearchPalette.primary,
                          fontSize: 11.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (onUseSuggestion != null)
                  IconButton(
                    onPressed: onUseSuggestion,
                    tooltip: 'Use ${test.displayName}',
                    color: _SearchPalette.muted,
                    icon: const Icon(Icons.north_west_rounded, size: 24),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: _SearchPalette.muted,
                      size: 24,
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

class _PopularTestGrid extends StatelessWidget {
  const _PopularTestGrid({
    required this.results,
    required this.onTap,
  });

  final List<MedicalTestSearchResult> results;
  final ValueChanged<MedicalTestSearchResult> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 154,
      ),
      itemBuilder: (context, index) {
        final result = results[index];
        return _PopularTestCard(
          result: result,
          onTap: () => onTap(result),
        );
      },
    );
  }
}

class _PopularTestCard extends StatelessWidget {
  const _PopularTestCard({
    required this.result,
    required this.onTap,
  });

  final MedicalTestSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final test = result.test;

    return Material(
      color: _SearchPalette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey('popular-test-${test.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _SearchPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _SearchPalette.primarySoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: MedicalCategoryIllustration(
                  category: test.category,
                  color: _SearchPalette.primary,
                ),
              ),
              const Spacer(),
              Text(
                test.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _SearchPalette.ink,
                  fontSize: 13,
                  height: 1.18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                test.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _SearchPalette.primary,
                  fontSize: 10.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrescriptionSearchCard extends StatelessWidget {
  const _PrescriptionSearchCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _SearchPalette.primarySoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _SearchPalette.searchBorder),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: _SearchPalette.primary,
                    size: 21,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not sure which test?',
                      style: TextStyle(
                        color: _SearchPalette.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Upload a prescription for a verified test list.',
                      style: TextStyle(
                        color: _SearchPalette.text,
                        fontSize: 11.8,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: _SearchPalette.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var index = 0; index < 6; index++) ...[
          Container(height: 78, decoration: _skeletonDecoration(14)),
          const SizedBox(height: 1),
        ],
      ],
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: _SearchPalette.muted,
              size: 48,
            ),
            const SizedBox(height: 14),
            const Text(
              'Search is temporarily unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _SearchPalette.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query, required this.onUpload});

  final String query;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: _SearchPalette.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: _SearchPalette.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              query.isEmpty
                  ? 'No tests in this category'
                  : 'No test found for “$query”',
              style: const TextStyle(
                color: _SearchPalette.ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Try the test’s full name or code, or upload your prescription.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _SearchPalette.muted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload prescription'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchPalette {
  const _SearchPalette._();

  static const background = Color(0xFFF4F6FA);
  static const surface = Colors.white;
  static const tile = Color(0xFFF8FAFD);
  static const header = Color(0xFFD9E8FF);
  static const headerBorder = Color(0xFFC7DCF9);
  static const ink = Color(0xFF101828);
  static const text = Color(0xFF475467);
  static const muted = Color(0xFF7C8AA3);
  static const border = Color(0xFFE3E8F1);
  static const primary = Color(0xFF1769E8);
  static const primarySoft = Color(0xFFEAF2FF);
  static const searchBorder = Color(0xFF91B9F3);
}

BoxDecoration _skeletonDecoration(double radius) {
  return BoxDecoration(
    color: const Color(0xFFE8ECF2),
    borderRadius: BorderRadius.circular(radius),
  );
}
