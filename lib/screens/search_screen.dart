import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medical_test.dart';
import '../services/medical_test_catalog_service.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';
import 'medical_test_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _recentKey = 'medical_test_recent_searches_v2';

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final MedicalTestCatalogService _catalogService =
      MedicalTestCatalogService();

  Timer? _debounce;
  List<MedicalTestSearchResult> _results = const [];
  List<MedicalTestCategorySummary> _categories = const [];
  List<String> _recentSearches = const [];
  String? _selectedCategory;
  Object? _error;
  bool _loading = true;
  int _requestGeneration = 0;

  bool get _hasQuery => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList(_recentKey) ?? const <String>[];

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
    setState(() {});
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
    final query = _controller.text.trim();
    final phrase = query.isEmpty ? result.test.displayName : query;
    final next = <String>[
      phrase,
      ..._recentSearches.where(
        (item) => item.toLowerCase() != phrase.toLowerCase(),
      ),
    ].take(6).toList(growable: false);

    setState(() => _recentSearches = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, next);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedicalTestDetailScreen(test: result.test),
      ),
    );
  }

  Future<void> _clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
    if (mounted) setState(() => _recentSearches = const []);
  }

  void _clearQuery() {
    _debounce?.cancel();
    _controller.clear();
    _focusNode.requestFocus();
    _search();
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
    return Scaffold(
      backgroundColor: _SearchPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            _SearchHeader(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onQueryChanged,
              onClear: _clearQuery,
            ),
            if (_categories.isNotEmpty)
              _CategoryRail(
                categories: _categories,
                selected: _selectedCategory,
                onSelected: _selectCategory,
              ),
            Expanded(child: _buildBody()),
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

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 34),
      children: [
        if (!_hasQuery && _recentSearches.isNotEmpty) ...[
          _SectionHeading(
            title: 'Search again',
            action: 'Clear',
            onAction: _clearRecent,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches
                .map(
                  (item) => ActionChip(
                    avatar: const Icon(Icons.history_rounded, size: 17),
                    label: Text(item),
                    onPressed: () => _useSearchPhrase(item),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: _SearchPalette.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 24),
        ],
        _SectionHeading(
          title: _hasQuery ? '${_results.length} best matches' : 'Popular now',
          subtitle: _hasQuery
              ? 'Ranked by name, test code, category and health need'
              : 'Frequently booked tests with home collection',
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < _results.length; index++) ...[
          _SearchResultCard(
            result: _results[index],
            onTap: () => _openTest(_results[index]),
          ),
          if (index != _results.length - 1) const SizedBox(height: 10),
        ],
        if (!_hasQuery) ...[
          const SizedBox(height: 18),
          _PrescriptionSearchCard(
            onTap: () => Navigator.pushNamed(context, '/upload'),
          ),
        ],
      ],
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B4FD8), Color(0xFF2F7CF6)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                tooltip: 'Back',
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: .13),
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find the right test',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Search tests, symptoms or test codes',
                      style: TextStyle(
                        color: Color(0xFFDCEAFF),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x290A347B),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: _SearchPalette.primary,
                  size: 25,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    cursorColor: _SearchPalette.primary,
                    style: const TextStyle(
                      color: _SearchPalette.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Try “CBC”, “livr” or “weakness”',
                      hintStyle: TextStyle(
                        color: _SearchPalette.muted,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      onPressed: onClear,
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: _SearchPalette.muted,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<MedicalTestCategorySummary> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _SearchPalette.border)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: categories.take(9).length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = index == 0 ? null : categories[index - 1].name;
          final active = selected == category;
          return ChoiceChip(
            label: Text(category ?? 'For you'),
            selected: active,
            onSelected: (_) => onSelected(category),
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: _SearchPalette.primarySoft,
            side: BorderSide(
              color: active ? _SearchPalette.primary : _SearchPalette.border,
            ),
            labelStyle: TextStyle(
              color: active ? _SearchPalette.primary : _SearchPalette.text,
              fontSize: 12,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _SearchPalette.ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.result, required this.onTap});

  final MedicalTestSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final test = result.test;
    final style = medicalTestCategoryStyle(test.category);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _SearchPalette.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08152A4A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MedicalTestIconBadge(test: test, size: 50),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: style.soft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              result.matchReason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: style.accent,
                                fontSize: 10.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        if (test.isPopular) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: Color(0xFFF97316),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      test.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _SearchPalette.ink,
                        fontSize: 15.3,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (test.hasDifferentOfficialName) ...[
                      const SizedBox(height: 3),
                      Text(
                        test.nameSheet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _SearchPalette.muted,
                          fontSize: 11.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${test.category}  •  ${test.reportLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _SearchPalette.text,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          test.priceLabel,
                          style: const TextStyle(
                            color: _SearchPalette.ink,
                            fontSize: 14.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: _SearchPalette.muted,
                          size: 20,
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
    );
  }
}

class _PrescriptionSearchCard extends StatelessWidget {
  const _PrescriptionSearchCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF102A56),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: const Padding(
          padding: EdgeInsets.all(17),
          child: Row(
            children: [
              Icon(Icons.description_rounded, color: Color(0xFF93C5FD)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not sure which test?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Upload a prescription for a verified test list.',
                      style: TextStyle(
                        color: Color(0xFFCBDCF8),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: Colors.white),
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
        Container(
          width: 180,
          height: 20,
          decoration: _skeletonDecoration(8),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < 6; index++) ...[
          Container(height: 126, decoration: _skeletonDecoration(20)),
          const SizedBox(height: 10),
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
              query.isEmpty ? 'No tests in this category' : 'No close match found',
              style: const TextStyle(
                color: _SearchPalette.ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Try another spelling, a symptom, or upload your prescription.',
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

  static const background = Color(0xFFF6F8FC);
  static const ink = Color(0xFF101828);
  static const text = Color(0xFF475467);
  static const muted = Color(0xFF7C8AA3);
  static const border = Color(0xFFE3E8F1);
  static const primary = Color(0xFF1769E8);
  static const primarySoft = Color(0xFFEAF2FF);
}

BoxDecoration _skeletonDecoration(double radius) {
  return BoxDecoration(
    color: const Color(0xFFE8ECF2),
    borderRadius: BorderRadius.circular(radius),
  );
}
