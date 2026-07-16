import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../utils/app_route_observer.dart';
import '../widgets/banners.dart';
import '../widgets/home/home_top_experience.dart';
import '../widgets/medical_test_catalog/home_medical_test_discovery.dart';
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
    with WidgetsBindingObserver, RouteAware {
  AuthService? _authService;
  MedicalTestCatalogService? _catalogService;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profileFuture = _loadProfile();
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

    if (oldWidget.isVisible && !widget.isVisible) {
      _tabHiddenAt = _now();
      return;
    }

    if (!oldWidget.isVisible && widget.isVisible) {
      final hiddenAt = _tabHiddenAt;
      _tabHiddenAt = null;
      if (_refreshIsDue(hiddenAt)) {
        _loadMedicalTestFeed(
          showRefreshError: false,
          notifyLoading: false,
        );
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
      if (_refreshIsDue(hiddenAt) &&
          widget.isVisible &&
          !_isCoveredByRoute) {
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

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _HomePalette.background,
      child: RefreshIndicator(
        onRefresh: _refreshHome,
        color: _HomePalette.primary,
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
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
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
              onViewReports: widget.onViewReports,
            );
          },
        ),
        const SizedBox(height: 28),
        const _HomeSectionHeader(
          eyebrow: 'THOUGHTFUL CARE',
          title: 'Health support for every day',
          subtitle: 'Simple services for each step of your lab journey.',
        ),
        const SizedBox(height: 13),
        HomeBanner(
          onExploreTests: widget.onViewCategories,
          onViewReports: widget.onViewReports,
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
      baseColor: const Color(0xFFE5EBE7),
      highlightColor: const Color(0xFFF9FBF9),
      period: const Duration(milliseconds: 1250),
      child: ListView(
        key: const ValueKey('home-skeleton-scroll'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
        children: const [
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 52, radius: 16)),
              SizedBox(width: 10),
              _SkeletonBox(width: 52, height: 52, radius: 16),
            ],
          ),
          SizedBox(height: 18),
          _SkeletonBox(width: 214, height: 27, radius: 8),
          SizedBox(height: 8),
          _SkeletonBox(width: 284, height: 13, radius: 7),
          SizedBox(height: 15),
          _SkeletonBox(height: 54, radius: 17),
          SizedBox(height: 18),
          _SkeletonBox(height: 237, radius: 28),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 86, radius: 20)),
              SizedBox(width: 11),
              Expanded(child: _SkeletonBox(height: 86, radius: 20)),
            ],
          ),
          SizedBox(height: 28),
          _SkeletonBox(width: 132, height: 12, radius: 6),
          SizedBox(height: 8),
          _SkeletonBox(width: 278, height: 23, radius: 8),
          SizedBox(height: 8),
          _SkeletonBox(width: 306, height: 14, radius: 7),
          SizedBox(height: 13),
          _SkeletonBox(height: 196, radius: 26),
          SizedBox(height: 30),
          _SkeletonCategoryModule(),
          SizedBox(height: 24),
          _SkeletonCategoryModule(),
        ],
      ),
    );
  }
}

class _SkeletonCategoryModule extends StatelessWidget {
  const _SkeletonCategoryModule();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SkeletonBox(width: 34, height: 34, radius: 11),
            SizedBox(width: 10),
            _SkeletonBox(width: 138, height: 18, radius: 8),
            Spacer(),
            _SkeletonBox(width: 54, height: 14, radius: 7),
          ],
        ),
        SizedBox(height: 10),
        _SkeletonBox(height: 238, radius: 26),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.height,
    required this.radius,
    this.width,
  });

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

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: _HomePalette.primary,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: .85,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: _HomePalette.ink,
            fontSize: 21,
            height: 1.12,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: _HomePalette.muted,
            fontSize: 12.2,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HomePalette {
  const _HomePalette._();

  static const Color background = Color(0xFFF8FAF7);
  static const Color ink = Color(0xFF172521);
  static const Color muted = Color(0xFF66756F);
  static const Color primary = Color(0xFF176B5B);
}
