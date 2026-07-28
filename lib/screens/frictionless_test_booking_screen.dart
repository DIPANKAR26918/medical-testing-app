import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/location_data.dart';
import '../models/medical_test.dart';
import '../models/order.dart';
import '../services/direct_booking_service.dart';
import '../services/location_service.dart';
import '../services/medical_test_catalog_service.dart';
import '../utils/app_theme.dart';
import '../utils/location_display_formatter.dart';
import '../widgets/location_selector_sheet_v5.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';
import 'direct_booking_success_screen.dart';
import 'medical_test_detail_screen.dart';

class FrictionlessTestBookingScreen extends StatefulWidget {
  const FrictionlessTestBookingScreen({super.key});

  @override
  State<FrictionlessTestBookingScreen> createState() =>
      _FrictionlessTestBookingScreenState();
}

class _FrictionlessTestBookingScreenState
    extends State<FrictionlessTestBookingScreen> {
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
    return _catalogTests
        .where((test) {
          return test.displayName.toLowerCase().contains(query) ||
              test.nameSheet.toLowerCase().contains(query) ||
              (test.testCode?.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false);
  }

  double get _selectedMrpTotal => _selectedTests.values.totalMrp;

  double get _selectedTotal => _selectedTests.values.totalSellingPrice;

  _CollectionMode? get _selectedMode {
    if (_selectedTests.isEmpty) return null;
    return _selectedTests.values.first.labVisitRequired
        ? _CollectionMode.labVisit
        : _CollectionMode.homeCollection;
  }

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
      final results = await Future.wait<dynamic>([
        _catalogService.fetchCategories(),
        _catalogService.fetchHomeFeed(categoryLimit: 20, testsPerCategory: 10),
      ]);

      final categories = results[0] as List<MedicalTestCategorySummary>;
      final feed = results[1] as HomeMedicalTestFeed;
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
    _searchDebounce = Timer(const Duration(milliseconds: 280), _runSearch);
  }

  Future<void> _runSearch() async {
    final query = _query;
    if (query.length < 2) return;

    final token = ++_requestToken;
    try {
      final results = await _catalogService.searchTests(
        query,
        category: _selectedCategory,
        limit: 50,
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

  Future<void> _selectCategory(String? category) async {
    if (_selectedCategory == category && !_loading) return;

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
      testsPerCategory: 10,
    );
    final unique = <String, MedicalTest>{};
    for (final category in feed.categories) {
      for (final test in category.tests) {
        unique[test.id] = test;
      }
    }
    return unique.values.toList(growable: false);
  }

  String? _eligibilityError(MedicalTest test) {
    if (test.mrp == null) {
      return 'This test needs price confirmation. Upload a prescription for it.';
    }
    if (!test.labVisitRequired && !test.homeCollectionAvailable) {
      return 'This test is not available for direct booking right now.';
    }
    return null;
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
      _showMessage('You can book up to 30 tests at once.');
      return;
    }

    final mode = test.labVisitRequired
        ? _CollectionMode.labVisit
        : _CollectionMode.homeCollection;
    if (_selectedMode != null && _selectedMode != mode) {
      _showMessage(
        'Home-collection and lab-visit tests need separate bookings.',
      );
      return;
    }

    setState(() => _selectedTests[test.id] = test);
  }

  void _openDetails(MedicalTest test) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedicalTestDetailScreen(test: test),
      ),
    );
  }

  Future<void> _reviewAndBook() async {
    if (_selectedTests.isEmpty) return;

    final bookedOrder = await showModalBottomSheet<Order>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FastBookingReviewSheet(
        tests: _selectedTests.values.toList(growable: false),
      ),
    );

    if (!mounted || bookedOrder == null) return;
    final bookedTests = _selectedTests.values.toList(growable: false);
    setState(() => _selectedTests.clear());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => DirectBookingSuccessScreen(
          order: bookedOrder,
          tests: bookedTests,
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    if (_selectedCategory == null) {
      await _loadInitial();
    } else {
      final category = _selectedCategory;
      setState(() => _loading = true);
      try {
        final tests = await _catalogService.fetchTestsByCategory(category!);
        if (!mounted) return;
        setState(() {
          _catalogTests = tests;
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
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
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
        title: const Text('Book tests'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/upload'),
            child: const Text('Upload prescription'),
          ),
          const SizedBox(width: 6),
        ],
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
                child: _SearchField(controller: _searchController),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              sliver: SliverToBoxAdapter(
                child: _ResultHeading(
                  title: _isRemoteSearch
                      ? 'Search results'
                      : _selectedCategory ?? 'Recommended',
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
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                sliver: SliverToBoxAdapter(
                  child: _StateCard(
                    icon: Icons.cloud_off_rounded,
                    title: 'Tests could not load',
                    subtitle: 'Check your connection and try again.',
                    action: TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ),
                ),
              )
            else if (!_searching && visibleTests.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 120),
                sliver: SliverToBoxAdapter(
                  child: _StateCard(
                    icon: Icons.search_off_rounded,
                    title: 'No matching tests',
                    subtitle:
                        'Try another name or choose a different category.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  _selectedTests.isEmpty ? 36 : 118,
                ),
                sliver: SliverList.separated(
                  itemCount: visibleTests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final test = visibleTests[index];
                    return _FastTestCard(
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
          : _FastCartBar(
              count: _selectedTests.length,
              mrpTotal: _selectedMrpTotal,
              total: _selectedTotal,
              mode: _selectedMode!,
              onContinue: _reviewAndBook,
            ),
    );
  }
}

class _FastBookingReviewSheet extends StatefulWidget {
  const _FastBookingReviewSheet({required this.tests});

  final List<MedicalTest> tests;

  @override
  State<_FastBookingReviewSheet> createState() =>
      _FastBookingReviewSheetState();
}

class _FastBookingReviewSheetState extends State<_FastBookingReviewSheet> {
  final DirectBookingService _bookingService = DirectBookingService();
  final LocationService _locationService = LocationService();

  LocationData? _address;
  bool _loadingAddress = true;
  bool _submitting = false;

  bool get _requiresLabVisit =>
      widget.tests.every((test) => test.labVisitRequired);

  double get _mrpTotal => widget.tests.totalMrp;

  double get _total => widget.tests.totalSellingPrice;

  bool get _addressUnavailable =>
      _address?.serviceabilityStatus == 'unavailable';

  bool get _canSubmit {
    if (_submitting || widget.tests.isEmpty) return false;
    if (_requiresLabVisit) return true;
    return !_loadingAddress &&
        _address?.id?.trim().isNotEmpty == true &&
        !_addressUnavailable;
  }

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    if (_requiresLabVisit) {
      if (mounted) setState(() => _loadingAddress = false);
      return;
    }

    try {
      final address = await _locationService.loadSavedLocation();
      if (!mounted) return;
      setState(() {
        _address = address;
        _loadingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAddress = false);
    }
  }

  Future<void> _chooseAddress() async {
    if (_submitting) return;

    final selected = await showModalBottomSheet<LocationData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationSelectorSheet(currentLocation: _address),
    );

    if (!mounted || selected == null) return;
    setState(() => _address = selected);
  }

  Future<void> _submit() async {
    if (!_requiresLabVisit &&
        (_address == null || _address?.id?.trim().isEmpty == true)) {
      await _chooseAddress();
      return;
    }
    if (!_canSubmit) return;

    setState(() => _submitting = true);
    try {
      final bookedOrder = await _bookingService.createBooking(
        tests: widget.tests,
        collectionAddressId: _requiresLabVisit ? null : _address?.id,
      );
      if (!mounted) return;

      await HapticFeedback.mediumImpact();
      if (!mounted) return;

      if (!mounted) return;
      Navigator.of(context).pop(bookedOrder);
    } on DirectBookingException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage('Booking could not be created. Please retry.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final address = _address;

    return FractionallySizedBox(
      heightFactor: .9,
      child: Material(
        color: _Palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Scaffold(
          backgroundColor: _Palette.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: _Palette.background,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            title: const Text('Confirm booking'),
            actions: [
              IconButton(
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            children: [
              _CompactTestList(tests: widget.tests),
              const SizedBox(height: 12),
              if (_requiresLabVisit)
                const _LabVisitReviewCard()
              else
                _ReviewAddressCard(
                  loading: _loadingAddress,
                  address: address,
                  onChange: _chooseAddress,
                ),
              const SizedBox(height: 12),
              const _TrustCard(),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _Palette.border)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 18,
                    offset: Offset(0, -7),
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
                        DiscountedPrice(
                          mrp: _mrpTotal,
                          sellingPrice: _total,
                          showMrpLabel: false,
                          mrpFontSize: 9.8,
                          priceFontSize: 18,
                          priceColor: _Palette.ink,
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Total',
                          style: TextStyle(
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
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : !_requiresLabVisit &&
                                (address == null || _addressUnavailable)
                          ? _chooseAddress
                          : _canSubmit
                          ? _submit
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD7DEE9),
                        disabledForegroundColor: const Color(0xFF8793A6),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              !_requiresLabVisit && address == null
                                  ? 'Add address'
                                  : 'Confirm booking',
                            ),
                    ),
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

// Kept temporarily for source compatibility with older deep links while the
// full-screen DirectBookingSuccessScreen owns the active success hand-off.
// ignore: unused_element
class _BookingSuccessCelebration extends StatefulWidget {
  const _BookingSuccessCelebration({
    required this.requiresLabVisit,
    required this.testCount,
    required this.mrpTotal,
    required this.total,
    required this.onViewBooking,
  });

  final bool requiresLabVisit;
  final int testCount;
  final double mrpTotal;
  final double total;
  final VoidCallback onViewBooking;

  @override
  State<_BookingSuccessCelebration> createState() =>
      _BookingSuccessCelebrationState();
}

class _BookingSuccessCelebrationState extends State<_BookingSuccessCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _cardScale;
  late final Animation<double> _halo;
  late final Animation<double> _check;
  late final Animation<double> _content;
  late final Animation<double> _action;
  late final Animation<double> _confetti;
  bool _reducedMotionApplied = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    );
    _cardOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .18, curve: Curves.easeOut),
    );
    _cardScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .28, curve: Curves.easeOutBack),
    );
    _halo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.06, .52, curve: Curves.easeOutCubic),
    );
    _check = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.16, .5, curve: Curves.elasticOut),
    );
    _content = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.38, .68, curve: Curves.easeOutCubic),
    );
    _action = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.58, .88, curve: Curves.easeOutBack),
    );
    _confetti = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.12, .72, curve: Curves.easeOut),
    );

    _controller.forward();
    unawaited(_playRewardHaptics());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_reducedMotionApplied && MediaQuery.disableAnimationsOf(context)) {
      _reducedMotionApplied = true;
      _controller.value = 1;
    }
  }

  Future<void> _playRewardHaptics() async {
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    await HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionLabel = widget.requiresLabVisit
        ? 'Lab visit'
        : 'Home collection';
    final nextStep = widget.requiresLabVisit
        ? 'We’re checking the lab and visit instructions.'
        : 'We’re checking the collection slot for your address.';

    return Semantics(
      liveRegion: true,
      label: 'Booking request sent successfully',
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final contentOpacity = _content.value
                        .clamp(0.0, 1.0)
                        .toDouble();
                    final actionOpacity = _action.value
                        .clamp(0.0, 1.0)
                        .toDouble();

                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _CelebrationParticlesPainter(
                                progress: _confetti.value,
                              ),
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: _cardOpacity.value
                              .clamp(0.0, 1.0)
                              .toDouble(),
                          child: Transform.scale(
                            scale: .88 + (.12 * _cardScale.value),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                24,
                                22,
                                20,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCFCFF),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .92),
                                  width: 1.4,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x380F172A),
                                    blurRadius: 42,
                                    offset: Offset(0, 20),
                                  ),
                                  BoxShadow(
                                    color: Color(0x142563EB),
                                    blurRadius: 28,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 150,
                                    height: 142,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Transform.scale(
                                          scale: .68 + (.62 * _halo.value),
                                          child: Opacity(
                                            opacity: (1 - _halo.value)
                                                .clamp(0.0, 1.0)
                                                .toDouble(),
                                            child: Container(
                                              width: 132,
                                              height: 132,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF2FA56F,
                                                  ).withValues(alpha: .34),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Transform.scale(
                                          scale: .76 + (.24 * _halo.value),
                                          child: Container(
                                            width: 106,
                                            height: 106,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFFE7FBF1),
                                                  Color(0xFFDDF7FF),
                                                ],
                                              ),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 5,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x262FA56F),
                                                  blurRadius: 24,
                                                  offset: Offset(0, 10),
                                                ),
                                              ],
                                            ),
                                            child: Transform.scale(
                                              scale: _check.value,
                                              child: const Icon(
                                                Icons.check_rounded,
                                                color: Color(0xFF17865A),
                                                size: 58,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: Offset(
                                      0,
                                      12 * (1 - _content.value),
                                    ),
                                    child: Opacity(
                                      opacity: contentOpacity,
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 11,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEAF7F0),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.verified_rounded,
                                                  size: 15,
                                                  color: Color(0xFF17865A),
                                                ),
                                                SizedBox(width: 5),
                                                Text(
                                                  'REQUEST RECEIVED',
                                                  style: TextStyle(
                                                    color: Color(0xFF16734F),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: .55,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          const Text(
                                            'Booking request sent!',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _Palette.ink,
                                              fontSize: 24,
                                              height: 1.12,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -.35,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            nextStep,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: _Palette.muted,
                                              fontSize: 13.5,
                                              height: 1.45,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF2F6FF),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              border: Border.all(
                                                color: const Color(0xFFDCE7FF),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          13,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    widget.requiresLabVisit
                                                        ? Icons
                                                              .apartment_rounded
                                                        : Icons
                                                              .home_work_outlined,
                                                    color: _Palette.primary,
                                                    size: 21,
                                                  ),
                                                ),
                                                const SizedBox(width: 11),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${widget.testCount} ${widget.testCount == 1 ? 'test' : 'tests'} · $collectionLabel',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: _Palette.ink,
                                                          fontSize: 12.5,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      const Text(
                                                        'Updates will appear in Bookings',
                                                        style: TextStyle(
                                                          color: _Palette.muted,
                                                          fontSize: 10.8,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                SizedBox(
                                                  width: 106,
                                                  child: DiscountedPrice(
                                                    mrp: widget.mrpTotal,
                                                    sellingPrice: widget.total,
                                                    showMrpLabel: false,
                                                    mrpFontSize: 9.2,
                                                    priceFontSize: 15,
                                                    priceColor: _Palette.ink,
                                                    alignment:
                                                        WrapAlignment.end,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Transform.translate(
                                    offset: Offset(0, 12 * (1 - _action.value)),
                                    child: Transform.scale(
                                      scale: .94 + (.06 * _action.value),
                                      child: Opacity(
                                        opacity: actionOpacity,
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              height: 52,
                                              child: ElevatedButton.icon(
                                                onPressed: widget.onViewBooking,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      _Palette.primary,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  textStyle: const TextStyle(
                                                    fontFamily:
                                                        AppTheme.fontFamily,
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons.track_changes_rounded,
                                                  size: 19,
                                                ),
                                                label: const Text(
                                                  'Track booking',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 11),
                                            const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.lock_outline_rounded,
                                                  size: 14,
                                                  color: _Palette.muted,
                                                ),
                                                SizedBox(width: 5),
                                                Text(
                                                  'Your medical details remain private',
                                                  style: TextStyle(
                                                    color: _Palette.muted,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationParticlesPainter extends CustomPainter {
  const _CelebrationParticlesPainter({required this.progress});

  final double progress;

  static const List<Color> _colors = [
    Color(0xFF2563EB),
    Color(0xFF2FA56F),
    Color(0xFFF5B942),
    Color(0xFF7C5CE7),
    Color(0xFF38A9C7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final burst = Curves.easeOutCubic.transform(
      progress.clamp(0.0, 1.0).toDouble(),
    );
    final fade = progress <= .62
        ? 1.0
        : (1 - ((progress - .62) / .38)).clamp(0.0, 1.0).toDouble();
    final origin = Offset(size.width / 2, 88);
    const count = 22;

    for (var index = 0; index < count; index++) {
      final angle = -math.pi * .92 + (index / (count - 1)) * math.pi * 1.84;
      final distance = 64.0 + ((index % 6) * 13.0);
      final drift = (index.isEven ? 1 : -1) * 7.0 * progress;
      final drop = 36.0 * progress * progress;
      final position = Offset(
        origin.dx + math.cos(angle) * distance * burst + drift,
        origin.dy + math.sin(angle) * distance * burst + drop,
      );
      final color = _colors[index % _colors.length].withValues(
        alpha: fade * (.7 + ((index % 3) * .1)),
      );
      final paint = Paint()..color = color;
      final sizeValue = 4.0 + (index % 4);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle + progress * (index.isEven ? 3.8 : -3.8));
      if (index % 3 == 0) {
        canvas.drawCircle(Offset.zero, sizeValue * .58, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: sizeValue,
              height: sizeValue * 1.8,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
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

class _ResultHeading extends StatelessWidget {
  const _ResultHeading({required this.title, required this.searching});

  final String title;
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
            width: 17,
            height: 17,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _FastTestCard extends StatelessWidget {
  const _FastTestCard({
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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onToggle : onDetails,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? _Palette.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _Palette.primary : _Palette.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MedicalTestIconBadge(test: test, size: 46, useHero: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (test.isPopular)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Text(
                          'POPULAR',
                          style: TextStyle(
                            color: Color(0xFF237A52),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .45,
                          ),
                        ),
                      ),
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
                    Row(
                      children: [
                        Icon(
                          test.labVisitRequired
                              ? Icons.apartment_rounded
                              : Icons.home_work_outlined,
                          size: 14,
                          color: _Palette.muted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            test.labVisitRequired
                                ? 'Lab visit'
                                : 'Home collection',
                            style: const TextStyle(
                              color: _Palette.muted,
                              fontSize: 11.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.schedule_outlined,
                          size: 14,
                          color: _Palette.muted,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            test.reportLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _Palette.muted,
                              fontSize: 11.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Expanded(
                          child: MedicalTestPrice(
                            test: test,
                            showMrpLabel: false,
                            mrpFontSize: 9.4,
                            priceFontSize: 15.5,
                            priceColor: _Palette.ink,
                          ),
                        ),
                        IconButton(
                          onPressed: onDetails,
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Test details',
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: _Palette.muted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 170),
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? _Palette.primary
                                : enabled
                                ? Colors.white
                                : const Color(0xFFF1F3F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? _Palette.primary
                                  : enabled
                                  ? _Palette.primary
                                  : const Color(0xFFD0D5DD),
                            ),
                          ),
                          child: Text(
                            selected
                                ? 'Added'
                                : enabled
                                ? 'Add'
                                : 'Details',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : enabled
                                  ? _Palette.primary
                                  : _Palette.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
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
    );
  }
}

class _FastCartBar extends StatelessWidget {
  const _FastCartBar({
    required this.count,
    required this.mrpTotal,
    required this.total,
    required this.mode,
    required this.onContinue,
  });

  final int count;
  final double mrpTotal;
  final double total;
  final _CollectionMode mode;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
                  DiscountedPrice(
                    mrp: mrpTotal,
                    sellingPrice: total,
                    showMrpLabel: false,
                    mrpFontSize: 9.4,
                    priceFontSize: 15.5,
                    priceColor: _Palette.ink,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$count ${count == 1 ? 'test' : 'tests'} · '
                    '${mode == _CollectionMode.labVisit ? 'Lab visit' : 'Home collection'}',
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
                onPressed: onContinue,
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
                child: const Text('Review & book'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({
    required this.count,
    required this.mrpTotal,
    required this.total,
    required this.requiresLabVisit,
  });

  final int count;
  final double mrpTotal;
  final double total;
  final bool requiresLabVisit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _Palette.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE8FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              requiresLabVisit
                  ? Icons.apartment_rounded
                  : Icons.home_work_outlined,
              color: _Palette.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'test' : 'tests'}',
                  style: const TextStyle(
                    color: _Palette.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  requiresLabVisit ? 'Lab visit' : 'Home sample collection',
                  style: const TextStyle(
                    color: _Palette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 116,
            child: DiscountedPrice(
              mrp: mrpTotal,
              sellingPrice: total,
              showMrpLabel: false,
              mrpFontSize: 10,
              priceFontSize: 18,
              priceColor: _Palette.ink,
              alignment: WrapAlignment.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactTestList extends StatelessWidget {
  const _CompactTestList({required this.tests});

  final List<MedicalTest> tests;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _Palette.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCADBFF), width: 1.2),
      ),
      child: Column(
        children: [
          for (var index = 0; index < tests.length; index++) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  MedicalTestIconBadge(
                    test: tests[index],
                    size: 54,
                    useHero: false,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tests[index].displayName,
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
                          tests[index].collectionLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _Palette.muted,
                            fontSize: 11.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 102),
                    child: MedicalTestPrice(
                      test: tests[index],
                      showMrpLabel: false,
                      mrpFontSize: 9,
                      priceFontSize: 13,
                      priceColor: _Palette.ink,
                      alignment: WrapAlignment.end,
                    ),
                  ),
                ],
              ),
            ),
            if (index != tests.length - 1)
              const Divider(height: 1, color: Color(0xFFD7E3FA)),
          ],
        ],
      ),
    );
  }
}

class _ReviewAddressCard extends StatelessWidget {
  const _ReviewAddressCard({
    required this.loading,
    required this.address,
    required this.onChange,
  });

  final bool loading;
  final LocationData? address;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final unavailable = address?.serviceabilityStatus == 'unavailable';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unavailable ? const Color(0xFFF1C6CC) : _Palette.border,
        ),
      ),
      child: loading
          ? const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'Loading saved address',
                  style: TextStyle(
                    color: _Palette.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _Palette.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: _Palette.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Collection address',
                        style: TextStyle(
                          color: _Palette.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        address != null &&
                                locationReadableAddress(address).isNotEmpty
                            ? locationReadableAddress(address)
                            : 'Add an address for home collection.',
                        style: TextStyle(
                          color: unavailable
                              ? const Color(0xFFB4233C)
                              : _Palette.muted,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (address != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          address!.serviceabilityLabel,
                          style: TextStyle(
                            color: unavailable
                                ? const Color(0xFFB4233C)
                                : const Color(0xFF237A52),
                            fontSize: 11.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onChange,
                  child: Text(address == null ? 'Add' : 'Change'),
                ),
              ],
            ),
    );
  }
}

class _LabVisitReviewCard extends StatelessWidget {
  const _LabVisitReviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.apartment_rounded, color: _Palette.primary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lab visit required',
                  style: TextStyle(
                    color: _Palette.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'The available lab and visit instructions will be confirmed after your request.',
                  style: TextStyle(
                    color: _Palette.muted,
                    fontSize: 12,
                    height: 1.4,
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

class _TrustCard extends StatelessWidget {
  const _TrustCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 18,
            color: _Palette.primary,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Collection and report updates will appear in Bookings.',
              style: TextStyle(
                color: _Palette.muted,
                fontSize: 11.8,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
        5,
        (index) => Container(
          height: 142,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF1F5),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
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
          if (action != null) ...[const SizedBox(height: 10), action!],
        ],
      ),
    );
  }
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
  static const Color divider = Color(0xFFEDF1F6);
}
