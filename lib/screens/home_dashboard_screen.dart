import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../utils/app_route_observer.dart';
import '../utils/app_time.dart';
import '../widgets/home/active_booking_strip.dart';
import '../widgets/home/ambient_header.dart';
import '../widgets/home/categories_section.dart';
import '../widgets/home/dual_action_strip.dart';
import '../widgets/home/home_constants.dart';
import '../widgets/home/how_it_works_strip.dart';
import '../widgets/home/popular_tests_editorial.dart';
import '../widgets/home/promo_banner_carousel.dart';
import '../widgets/home/search_command_bar.dart';
import '../widgets/home/trust_signals_strip.dart';
import 'category_tests_screen.dart';
import 'medical_test_detail_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    required this.onBookTest,
    required this.onViewReports,
    required this.onUploadPrescription,
    required this.onSearch,
    required this.onViewCategories,
    this.isVisible = true,
    this.feedRefreshAfter = const Duration(seconds: 30),
    this.homeFeedLoader,
    this.profileLoader,
    this.now,
    super.key,
  });

  final VoidCallback onBookTest;
  final VoidCallback onViewReports;
  final VoidCallback onUploadPrescription;
  final VoidCallback onSearch;
  final VoidCallback onViewCategories;
  final bool isVisible;
  final Duration feedRefreshAfter;
  final Future<HomeMedicalTestFeed> Function()? homeFeedLoader;
  final Future<AppUser?> Function()? profileLoader;
  final DateTime Function()? now;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  AuthService? _authService;
  MedicalTestCatalogService? _catalogService;
  FirestoreService? _firestoreService;

  late Future<AppUser?> _profileFuture;
  HomeMedicalTestFeed? _medicalTestFeed;
  Object? _medicalTestFeedError;
  bool _isMedicalTestFeedLoading = true;
  bool _isMedicalTestFeedRequestInFlight = false;
  bool _isCoveredByRoute = false;
  DateTime? _appHiddenAt;
  DateTime? _routeHiddenAt;
  DateTime? _tabHiddenAt;
  PageRoute<dynamic>? _pageRoute;
  int _feedRequestGeneration = 0;

  // Active orders state
  List<Order> _activeOrders = [];

  // Entrance animation
  AnimationController? _entranceController;
  bool _hasAnimatedEntrance = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profileFuture = _loadProfile();

    if (!widget.isVisible) {
      _tabHiddenAt = _now();
    }

    _loadMedicalTestFeed(notifyLoading: false);
    _loadActiveOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route is! PageRoute<dynamic> || route == _pageRoute) return;

    final previousRoute = _pageRoute;
    if (previousRoute != null) {
      appRouteObserver.unsubscribe(this);
    }

    _pageRoute = route;
    appRouteObserver.subscribe(this, route);
  }

  @override
  void didUpdateWidget(covariant HomeDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isVisible && !widget.isVisible) {
      _tabHiddenAt = _now();
      return;
    }

    if (!oldWidget.isVisible && widget.isVisible) {
      final hiddenAt = _tabHiddenAt;
      _tabHiddenAt = null;

      if (_refreshIsDue(hiddenAt)) {
        _loadMedicalTestFeed(showRefreshError: false, notifyLoading: false);
        _loadActiveOrders();
      }
    }
  }

  @override
  void dispose() {
    _entranceController?.dispose();
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final hiddenAt = _appHiddenAt;
      _appHiddenAt = null;

      if (_refreshIsDue(hiddenAt) && widget.isVisible && !_isCoveredByRoute) {
        _loadMedicalTestFeed(showRefreshError: false);
        _loadActiveOrders();
      }
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _appHiddenAt ??= _now();
    }
  }

  @override
  void didPushNext() {
    _isCoveredByRoute = true;
    _routeHiddenAt = _now();
  }

  @override
  void didPopNext() {
    final hiddenAt = _routeHiddenAt;
    _isCoveredByRoute = false;
    _routeHiddenAt = null;

    if (_refreshIsDue(hiddenAt) && widget.isVisible) {
      _loadMedicalTestFeed(showRefreshError: false);
      _loadActiveOrders();
    }
  }

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  int _displayHour() {
    final customNow = widget.now;
    return customNow == null ? AppTime.currentKolkataHour() : customNow().hour;
  }

  bool _refreshIsDue(DateTime? hiddenAt) {
    return hiddenAt != null &&
        !_now().isBefore(hiddenAt.add(widget.feedRefreshAfter));
  }

  Future<AppUser?> _loadProfile() async {
    final customLoader = widget.profileLoader;
    if (customLoader != null) return customLoader();

    final authService = _authService ??= AuthService();
    final userId = authService.getCurrentUserId();
    if (userId == null) return null;

    return authService.getUserProfile(userId);
  }

  Future<void> _loadActiveOrders() async {
    try {
      final authService = _authService ??= AuthService();
      final userId = authService.getCurrentUserId();
      if (userId == null) return;

      final service = _firestoreService ??= FirestoreService();
      final orders = await service.getUserOrders(userId).first;

      if (!mounted) return;

      // Filter to active statuses only
      final activeStatuses = {
        'uploaded',
        'confirmed',
        'assigned',
        'collected',
        'testing',
        'payment_pending',
      };

      final active = orders
          .where((o) => activeStatuses.contains(o.status))
          .take(5)
          .toList();

      setState(() => _activeOrders = active);
    } catch (_) {
      // Silently fail — active orders are a nice-to-have, not critical
    }
  }

  void _animateEntrance() {
    if (_hasAnimatedEntrance) return;
    _hasAnimatedEntrance = true;
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  Future<void> _loadMedicalTestFeed({
    bool showRefreshError = true,
    bool notifyLoading = true,
  }) async {
    if (_isMedicalTestFeedRequestInFlight) return;

    _isMedicalTestFeedRequestInFlight = true;
    final requestGeneration = ++_feedRequestGeneration;
    final previousFeed = _medicalTestFeed;

    void markLoading() {
      _medicalTestFeed = null;
      _medicalTestFeedError = null;
      _isMedicalTestFeedLoading = true;
    }

    if (notifyLoading && mounted) {
      setState(markLoading);
    } else {
      markLoading();
    }

    try {
      final customLoader = widget.homeFeedLoader;
      final feed = customLoader != null
          ? await customLoader()
          : await (_catalogService ??= MedicalTestCatalogService())
                .fetchHomeFeed();

      if (!mounted || requestGeneration != _feedRequestGeneration) return;

      setState(() {
        _medicalTestFeed = feed;
        _medicalTestFeedError = null;
        _isMedicalTestFeedLoading = false;
      });
      _animateEntrance();
    } catch (error) {
      if (!mounted || requestGeneration != _feedRequestGeneration) return;

      setState(() {
        _medicalTestFeed = previousFeed;
        _medicalTestFeedError = error;
        _isMedicalTestFeedLoading = false;
      });

      if (previousFeed != null && showRefreshError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not refresh tests. Showing the last list.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (requestGeneration == _feedRequestGeneration) {
        _isMedicalTestFeedRequestInFlight = false;
      }
    }
  }

  Future<void> _refreshHome() async {
    setState(() => _profileFuture = _loadProfile());
    await Future.wait([
      _loadMedicalTestFeed(),
      _loadActiveOrders(),
    ]);
  }

  void _openMedicalTest(MedicalTest test) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedicalTestDetailScreen(test: test),
      ),
    );
  }

  void _openMedicalTestCategory(String category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryTestsScreen(category: category),
      ),
    );
  }

  void _openOrderDetails(Order order) {
    Navigator.of(context).pushNamed(
      '/order-details',
      arguments: order.orderId,
    );
  }

  String _firstName(AppUser? profile) {
    final name = profile?.name.trim();

    if (name == null ||
        name.isEmpty ||
        name.toLowerCase() == 'testified user') {
      return '';
    }

    return name.split(RegExp(r'\s+')).first;
  }

  /// Wraps a child in a staggered fade+slide animation.
  /// [delay] is 0.0-1.0 representing when in the entrance animation this zone starts.
  Widget _staggerChild(Widget child, {required double delay}) {
    final controller = _entranceController;
    if (controller == null || !_hasAnimatedEntrance) return child;

    final begin = delay;
    final end = (delay + 0.35).clamp(0.0, 1.0);

    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: curvedAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - curvedAnimation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Collects all popular tests from the feed into a flat list.
  List<MedicalTest> _popularTests() {
    final feed = _medicalTestFeed;
    if (feed == null) return [];

    final all = <MedicalTest>[];
    for (final category in feed.categories) {
      for (final test in category.tests) {
        if (test.isPopular && !all.any((t) => t.id == test.id)) {
          all.add(test);
        }
      }
    }

    // If not enough popular tests, add first tests from each category
    if (all.length < 5) {
      for (final category in feed.categories) {
        for (final test in category.tests) {
          if (!all.any((t) => t.id == test.id)) {
            all.add(test);
            if (all.length >= 5) break;
          }
        }
        if (all.length >= 5) break;
      }
    }

    return all;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HomeColors.background,
      child: RefreshIndicator(
        onRefresh: _refreshHome,
        color: HomeColors.primary,
        backgroundColor: Colors.white,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _isMedicalTestFeedLoading
              ? const _HomeDashboardSkeleton(
                  key: ValueKey('home-full-skeleton'),
                )
              : _buildHomeContent(),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final popularTests = _popularTests();

    return ListView(
      key: const ValueKey('home-content'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.zero,
      children: [
        // ─── Zone 1: Ambient Header ──────────────────────────────────
        _staggerChild(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: FutureBuilder<AppUser?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                return AmbientHeader(
                  firstName: _firstName(snapshot.data),
                  hour: _displayHour(),
                );
              },
            ),
          ),
          delay: 0.0,
        ),

        const SizedBox(height: 20),

        // ─── Zone 2: Search Command Bar ──────────────────────────────
        _staggerChild(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SearchCommandBar(onTap: widget.onSearch),
          ),
          delay: 0.08,
        ),

        const SizedBox(height: 24),

        // ─── Zone 3: Dual Action Strip ───────────────────────────────
        _staggerChild(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DualActionStrip(
              onUploadPrescription: widget.onUploadPrescription,
              onBookTest: widget.onBookTest,
            ),
          ),
          delay: 0.15,
        ),

        const SizedBox(height: 28),

        // ─── Zone 4: Active Booking Pulse (conditional) ──────────────
        if (_activeOrders.isNotEmpty) ...[
          _staggerChild(
            ActiveBookingStrip(
              orders: _activeOrders,
              onOrderTap: _openOrderDetails,
            ),
            delay: 0.22,
          ),
          const SizedBox(height: 28),
        ],

        // ─── Zone 5: Promo Banner Carousel ───────────────────────────
        _staggerChild(
          PromoBannerCarousel(
            onBannerTap: (_) => widget.onViewCategories(),
          ),
          delay: 0.28,
        ),

        const SizedBox(height: 28),

        // ─── Zone 6: Category Discovery ──────────────────────────────
        _staggerChild(
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: CategoriesSection(
              onViewAll: widget.onViewCategories,
              onCategoryTap: _openMedicalTestCategory,
            ),
          ),
          delay: 0.38,
        ),

        const SizedBox(height: 24),

        // ─── Zone 7: Popular Tests Editorial ─────────────────────────
        _staggerChild(
          PopularTestsEditorial(
            tests: popularTests,
            onTestTap: _openMedicalTest,
            onSeeAll: widget.onViewCategories,
          ),
          delay: 0.50,
        ),

        const SizedBox(height: 24),

        // ─── Zone 8: How It Works ────────────────────────────────────
        _staggerChild(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const HowItWorksStrip(),
          ),
          delay: 0.62,
        ),

        const SizedBox(height: 28),

        // ─── Zone 9: Trust Signals ───────────────────────────────────
        _staggerChild(
          const TrustSignalsStrip(),
          delay: 0.72,
        ),

        // Bottom padding for nav bar clearance
        const SizedBox(height: 100),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton loading state
// ─────────────────────────────────────────────────────────────────────────────

class _HomeDashboardSkeleton extends StatelessWidget {
  const _HomeDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFECEFF1),
      highlightColor: const Color(0xFFFAFAFA),
      period: const Duration(milliseconds: 1400),
      child: ListView(
        key: const ValueKey('home-skeleton-scroll'),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: const [
          // Zone 1: Location chip
          Align(
            alignment: Alignment.centerLeft,
            child: _SkeletonBox(width: 200, height: 52, radius: 16),
          ),
          SizedBox(height: 16),
          // Greeting line
          _SkeletonBox(width: 240, height: 24, radius: 6),
          SizedBox(height: 8),
          _SkeletonBox(width: 280, height: 14, radius: 4),

          SizedBox(height: 20),
          // Zone 2: Search bar
          _SkeletonBox(height: 56, radius: 28),

          SizedBox(height: 24),
          // Zone 3: Dual action tiles
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 140, radius: 14)),
              SizedBox(width: 12),
              Expanded(child: _SkeletonBox(height: 140, radius: 14)),
            ],
          ),

          SizedBox(height: 28),
          // Zone 5: Banner
          _SkeletonBox(height: 180, radius: 14),

          SizedBox(height: 28),
          // Zone 6: Category section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SkeletonBox(width: 190, height: 16, radius: 4),
              _SkeletonBox(width: 60, height: 14, radius: 4),
            ],
          ),
          SizedBox(height: 16),
          // Category chips with labels
          Row(
            children: [
              _SkeletonChip(),
              SizedBox(width: 16),
              _SkeletonChip(),
              SizedBox(width: 16),
              _SkeletonChip(),
              SizedBox(width: 16),
              _SkeletonChip(),
              SizedBox(width: 16),
              _SkeletonChip(),
            ],
          ),

          SizedBox(height: 28),
          // Zone 7: Popular tests section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SkeletonBox(width: 130, height: 16, radius: 4),
              _SkeletonBox(width: 60, height: 14, radius: 4),
            ],
          ),
          SizedBox(height: 16),
          // Test row skeletons
          _SkeletonTestRow(),
          SizedBox(height: 16),
          _SkeletonTestRow(),
          SizedBox(height: 16),
          _SkeletonTestRow(),
        ],
      ),
    );
  }
}

/// Skeleton for a category chip (circle + label below).
class _SkeletonChip extends StatelessWidget {
  const _SkeletonChip();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SkeletonBox(width: 56, height: 56, radius: 28),
        SizedBox(height: 8),
        _SkeletonBox(width: 48, height: 10, radius: 3),
      ],
    );
  }
}

/// Skeleton for a popular test row (icon + text lines + button).
class _SkeletonTestRow extends StatelessWidget {
  const _SkeletonTestRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SkeletonBox(width: 40, height: 40, radius: 10),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(height: 16, radius: 4),
              SizedBox(height: 6),
              _SkeletonBox(width: 160, height: 12, radius: 3),
            ],
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _SkeletonBox(width: 50, height: 16, radius: 4),
            SizedBox(height: 6),
            _SkeletonBox(width: 60, height: 30, radius: 8),
          ],
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, required this.radius, this.width});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
