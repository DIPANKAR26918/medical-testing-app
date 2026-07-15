import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../utils/app_route_observer.dart';
import '../widgets/location_card.dart';
import '../widgets/notification_button.dart';
import '../widgets/search_bar.dart';
import '../widgets/banners.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: [
        FutureBuilder<AppUser?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final firstName = _firstName(snapshot.data);

            return _HomeHeroPanel(
              firstName: firstName,
              onNotificationTap: _openNotifications,
              onSearch: widget.onSearch,
            );
          },
        ),
        const SizedBox(height: 18),
        HomeBanner(
          onBannerTap: widget.onViewCategories,
        ),
        const SizedBox(height: 18),
        _PrimaryCarePanel(
          onUploadPrescription: widget.onUploadPrescription,
          onBookTest: widget.onBookTest,
        ),
        const SizedBox(height: 16),
        _ReportsShortcut(onTap: widget.onViewReports),
        const SizedBox(height: 24),
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
      baseColor: const Color(0xFFE6EAF0),
      highlightColor: const Color(0xFFF8FAFC),
      period: const Duration(milliseconds: 1250),
      child: ListView(
        key: const ValueKey('home-skeleton-scroll'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: const [
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 48, radius: 16)),
              SizedBox(width: 10),
              _SkeletonBox(width: 48, height: 48, radius: 16),
            ],
          ),
          SizedBox(height: 20),
          _SkeletonBox(width: 176, height: 27, radius: 9),
          SizedBox(height: 8),
          _SkeletonBox(width: 286, height: 14, radius: 7),
          SizedBox(height: 18),
          _SkeletonBox(height: 52, radius: 17),
          SizedBox(height: 16),
          _SkeletonBox(height: 176, radius: 22),
          SizedBox(height: 16),
          _SkeletonBox(height: 164, radius: 22),
          SizedBox(height: 16),
          _SkeletonBox(height: 76, radius: 20),
          SizedBox(height: 26),
          Row(
            children: [
              _SkeletonBox(width: 96, height: 26, radius: 13),
              Spacer(),
              _SkeletonBox(width: 84, height: 38, radius: 12),
            ],
          ),
          SizedBox(height: 14),
          _SkeletonBox(width: 252, height: 24, radius: 8),
          SizedBox(height: 8),
          _SkeletonBox(width: 296, height: 14, radius: 7),
          SizedBox(height: 20),
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

class _TopLocationRow extends StatelessWidget {
  const _TopLocationRow({required this.onNotificationTap});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: LocationCard()),
        const SizedBox(width: 10),
        NotificationButton(unreadCount: 0, onTap: onNotificationTap),
      ],
    );
  }
}

class _HomeHeroPanel extends StatelessWidget {
  const _HomeHeroPanel({
    required this.firstName,
    required this.onNotificationTap,
    required this.onSearch,
  });

  final String firstName;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A4FCC), Color(0xFF2D7CF2)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2B1769E8),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: 30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopLocationRow(onNotificationTap: onNotificationTap),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _GreetingHeader(firstName: firstName),
              ),
              const SizedBox(height: 15),
              HomeSearchBar(onTap: onSearch),
              const SizedBox(height: 13),
              const _TrustStrip(),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _TrustItem(icon: Icons.verified_rounded, label: 'Verified labs'),
        ),
        _TrustDivider(),
        Expanded(
          child: _TrustItem(icon: Icons.home_rounded, label: 'Home collection'),
        ),
        _TrustDivider(),
        Expanded(
          child: _TrustItem(icon: Icons.lock_rounded, label: 'Private by design'),
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFFDDEAFF), size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFEAF2FF),
              fontSize: 8.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrustDivider extends StatelessWidget {
  const _TrustDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withValues(alpha: .22),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final title = firstName.isEmpty ? '$salutation 👋' : '$salutation, $firstName';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'What would you like to take care of today?',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color(0xFFDDEAFF),
            fontSize: 12.7,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PrimaryCarePanel extends StatelessWidget {
  const _PrimaryCarePanel({
    required this.onUploadPrescription,
    required this.onBookTest,
  });

  final VoidCallback onUploadPrescription;
  final VoidCallback onBookTest;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PrimaryActionCard(
            eyebrow: 'BOOK DIRECTLY',
            title: 'Choose a lab test',
            subtitle: 'Search the complete catalogue',
            icon: Icons.biotech_rounded,
            accent: const Color(0xFF1769E8),
            background: const Color(0xFFEAF2FF),
            onTap: onBookTest,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _PrimaryActionCard(
            eyebrow: 'NEED HELP?',
            title: 'Book via prescription',
            subtitle: 'Review the mapped tests first',
            icon: Icons.assignment_turned_in_rounded,
            accent: const Color(0xFF087A68),
            background: const Color(0xFFE5F8F3),
            onTap: onUploadPrescription,
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.background,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 166,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent.withValues(alpha: .13)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .82),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const Spacer(),
                  Container(
                    width: 29,
                    height: 29,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 8.8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .65,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomePalette.ink,
                  fontSize: 15.2,
                  height: 1.14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomePalette.muted,
                  fontSize: 10.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsShortcut extends StatelessWidget {
  const _ReportsShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: _surfaceDecoration(radius: 20, shadow: false),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _HomePalette.success.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: _HomePalette.success,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports',
                      style: TextStyle(
                        color: _HomePalette.ink,
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'View completed lab reports.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _HomePalette.muted,
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _HomePalette.softMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomePalette {
  const _HomePalette._();

  static const Color background = Color(0xFFFAFBFC);

  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color softMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE6EAF0);

  static const Color primary = Color(0xFF2563EB);
  static const Color success = Color(0xFF16A34A);

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: .025),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

BoxDecoration _surfaceDecoration({double radius = 20, bool shadow = true}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _HomePalette.border),
    boxShadow: shadow ? _HomePalette.cardShadow : null,
  );
}
