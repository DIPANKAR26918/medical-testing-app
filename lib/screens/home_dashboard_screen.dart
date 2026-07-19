import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../utils/app_route_observer.dart';
import '../widgets/banners.dart';
import '../widgets/home/home_booking_progress.dart';
import '../widgets/home/home_constants.dart';
import '../widgets/home/home_top_experience.dart';
import '../widgets/medical_test_catalog/home_medical_test_discovery.dart';
import 'category_tests_screen.dart';
import 'medical_test_detail_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    required this.onBookTest,
    required this.onViewBookings,
    required this.onViewReports,
    required this.onUploadPrescription,
    required this.onSearch,
    required this.onViewCategories,
    this.isVisible = true,
    this.feedRefreshAfter = const Duration(seconds: 30),
    this.homeFeedLoader,
    this.profileLoader,
    this.ordersLoader,
    this.now,
    super.key,
  });

  final VoidCallback onBookTest;
  final VoidCallback onViewBookings;
  final VoidCallback onViewReports;
  final VoidCallback onUploadPrescription;
  final VoidCallback onSearch;
  final VoidCallback onViewCategories;
  final bool isVisible;
  final Duration feedRefreshAfter;
  final Future<HomeMedicalTestFeed> Function()? homeFeedLoader;
  final Future<AppUser?> Function()? profileLoader;
  final Stream<List<Order>> Function()? ordersLoader;
  final DateTime Function()? now;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with WidgetsBindingObserver, RouteAware {
  AuthService? _authService;
  FirestoreService? _firestoreService;
  MedicalTestCatalogService? _catalogService;

  late Future<AppUser?> _profileFuture;
  late Stream<List<Order>> _ordersStream;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profileFuture = _loadProfile();
    _ordersStream = _createOrdersStream();

    if (!widget.isVisible) {
      _tabHiddenAt = _now();
    }

    _loadMedicalTestFeed(notifyLoading: false);
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

    if (oldWidget.ordersLoader != widget.ordersLoader) {
      _ordersStream = _createOrdersStream();
    }

    if (oldWidget.isVisible && !widget.isVisible) {
      _tabHiddenAt = _now();
      return;
    }

    if (!oldWidget.isVisible && widget.isVisible) {
      final hiddenAt = _tabHiddenAt;
      _tabHiddenAt = null;

      if (_refreshIsDue(hiddenAt)) {
        _loadMedicalTestFeed(showRefreshError: false, notifyLoading: false);
      }
    }
  }

  @override
  void dispose() {
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
    }
  }

  DateTime _now() => widget.now?.call() ?? DateTime.now();

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

  Stream<List<Order>> _createOrdersStream() {
    final customLoader = widget.ordersLoader;
    if (customLoader != null) return customLoader();

    try {
      final authService = _authService ??= AuthService();
      final userId = authService.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        return Stream<List<Order>>.value(const <Order>[]);
      }

      return (_firestoreService ??= FirestoreService()).getUserOrders(userId);
    } catch (_) {
      // Widget tests and signed-out transitions can briefly run before the
      // Supabase singleton is available. The home remains useful without an
      // active-order card and reconnects on the next authenticated rebuild.
      return Stream<List<Order>>.value(const <Order>[]);
    }
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
    await _loadMedicalTestFeed();
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

  void _openNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications will open here'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 900),
      ),
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

  Order? _latestActiveOrder(List<Order> orders) {
    for (final order in orders) {
      final status = order.status
          .trim()
          .toLowerCase()
          .replaceAll('-', '_')
          .replaceAll(' ', '_');
      final isPast = status == 'completed' ||
          status == 'done' ||
          status == 'report_delivered' ||
          status == 'cancelled' ||
          status == 'canceled';
      if (!isPast) return order;
    }
    return null;
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
    return ListView(
      key: const ValueKey('home-content'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: [
        FutureBuilder<AppUser?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            return HomeTopExperience(
              firstName: _firstName(snapshot.data),
              hour: _now().hour,
              onNotificationTap: _openNotifications,
              onSearch: widget.onSearch,
              onUploadPrescription: widget.onUploadPrescription,
              onBrowseTests: widget.onBookTest,
              onViewBookings: widget.onViewBookings,
              onViewReports: widget.onViewReports,
            );
          },
        ),
        const SizedBox(height: 28),
        StreamBuilder<List<Order>>(
          stream: _ordersStream,
          builder: (context, snapshot) {
            final orders = snapshot.data ?? const <Order>[];
            return HomeBookingProgress(
              order: _latestActiveOrder(orders),
              isLoading:
                  snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData,
              onOpenBookings: widget.onViewBookings,
              onUploadPrescription: widget.onUploadPrescription,
            );
          },
        ),
        const SizedBox(height: 28),
        HomeBanner(
          onExploreTests: widget.onViewCategories,
        ),
        const SizedBox(height: 30),
        HomeMedicalTestDiscovery(
          feed: _medicalTestFeed,
          isLoading: _isMedicalTestFeedLoading,
          error: _medicalTestFeedError,
          onRetry: () => _loadMedicalTestFeed(),
          onTestTap: _openMedicalTest,
          onCategoryTap: _openMedicalTestCategory,
          onAllCategoriesTap: widget.onViewCategories,
        ),
      ],
    );
  }
}

class _HomeDashboardSkeleton extends StatelessWidget {
  const _HomeDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE7ECF3),
      highlightColor: const Color(0xFFF8FAFD),
      period: const Duration(milliseconds: 1250),
      child: ListView(
        key: const ValueKey('home-skeleton-scroll'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: const [
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 52, radius: 16)),
              SizedBox(width: 10),
              _SkeletonBox(width: 52, height: 52, radius: 16),
            ],
          ),
          SizedBox(height: 22),
          _SkeletonBox(width: 245, height: 28, radius: 8),
          SizedBox(height: 9),
          _SkeletonBox(width: 300, height: 14, radius: 7),
          SizedBox(height: 18),
          _SkeletonBox(height: 54, radius: 17),
          SizedBox(height: 16),
          _SkeletonBox(height: 274, radius: 26),
          SizedBox(height: 14),
          _SkeletonBox(height: 102, radius: 23),
          SizedBox(height: 28),
          _SkeletonBox(width: 176, height: 22, radius: 8),
          SizedBox(height: 13),
          _SkeletonBox(height: 176, radius: 24),
          SizedBox(height: 28),
          _SkeletonBox(height: 182, radius: 24),
          SizedBox(height: 30),
          _SkeletonBox(width: 252, height: 22, radius: 8),
          SizedBox(height: 9),
          _SkeletonBox(width: 318, height: 12, radius: 7),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 82, radius: 17)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBox(height: 82, radius: 17)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBox(height: 82, radius: 17)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBox(height: 82, radius: 17)),
            ],
          ),
          SizedBox(height: 22),
          _SkeletonBox(height: 434, radius: 24),
          SizedBox(height: 16),
          _SkeletonBox(height: 434, radius: 24),
        ],
      ),
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
