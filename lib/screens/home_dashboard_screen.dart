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
        const SizedBox(height: 16),
        _PrescriptionBookingHero(onTap: widget.onUploadPrescription),
        const SizedBox(height: 12),
        _SecondaryCareActions(
          onBookTest: widget.onBookTest,
          onViewReports: widget.onViewReports,
        ),
        const SizedBox(height: 26),
        const _HomeSectionHeader(
          eyebrow: 'CARE, MADE SIMPLE',
          title: 'Built around your health routine',
          subtitle: 'Helpful services for every step of your lab journey.',
        ),
        const SizedBox(height: 13),
        HomeBanner(
          onExploreTests: widget.onViewCategories,
          onViewReports: widget.onViewReports,
        ),
        const SizedBox(height: 28),
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
          _SkeletonBox(height: 232, radius: 28),
          SizedBox(height: 16),
          _SkeletonBox(height: 254, radius: 28),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 104, radius: 20)),
              SizedBox(width: 11),
              Expanded(child: _SkeletonBox(height: 104, radius: 20)),
            ],
          ),
          SizedBox(height: 26),
          _SkeletonBox(width: 132, height: 12, radius: 6),
          SizedBox(height: 8),
          _SkeletonBox(width: 278, height: 23, radius: 8),
          SizedBox(height: 8),
          _SkeletonBox(width: 306, height: 14, radius: 7),
          SizedBox(height: 13),
          _SkeletonBox(height: 202, radius: 26),
          SizedBox(height: 28),
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
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F8FF), Color(0xFFEAF8F5)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDCEAE8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E164E63),
            blurRadius: 24,
            offset: Offset(0, 10),
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
                color: const Color(0xFF0D766D).withValues(alpha: .045),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopLocationRow(onNotificationTap: onNotificationTap),
              const SizedBox(height: 17),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _GreetingHeader(firstName: firstName),
              ),
              const SizedBox(height: 14),
              HomeSearchBar(onTap: onSearch),
            ],
          ),
        ],
      ),
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
            color: _HomePalette.ink,
            fontSize: 23.5,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tests, prescriptions and reports—kept in one calm place.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _HomePalette.muted,
            fontSize: 12.7,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PrescriptionBookingHero extends StatelessWidget {
  const _PrescriptionBookingHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Upload a prescription to prepare your lab test list',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF064D49), Color(0xFF08766C)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x29064D49),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                Positioned(
                  right: -58,
                  top: -72,
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .055),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: -74,
                  bottom: -128,
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      color: const Color(0xFF84E1D4).withValues(alpha: .08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7FFF7),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.assignment_turned_in_rounded,
                                  color: Color(0xFF075A54),
                                  size: 13,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'PRESCRIPTION ASSIST',
                                  style: TextStyle(
                                    color: Color(0xFF075A54),
                                    fontSize: 8.6,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xFFC9EFE9),
                            size: 17,
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload once.\nReview every test.',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21.5,
                                    height: 1.08,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.45,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'We prepare the test list. You approve before booking.',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Color(0xFFD3ECE8),
                                    fontSize: 11.7,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const _PrescriptionAssistIllustration(),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.fromLTRB(13, 0, 7, 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.upload_file_rounded,
                              color: Color(0xFF075F58),
                              size: 21,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Upload prescription',
                                style: TextStyle(
                                  color: Color(0xFF064D49),
                                  fontSize: 13.6,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            _PrescriptionArrow(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _PrescriptionJourney(),
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

class _PrescriptionArrow extends StatelessWidget {
  const _PrescriptionArrow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Color(0xFF08766C),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.arrow_forward_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

class _PrescriptionAssistIllustration extends StatelessWidget {
  const _PrescriptionAssistIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .09)),
            ),
          ),
          Transform.rotate(
            angle: -.055,
            child: Container(
              width: 70,
              height: 91,
              padding: const EdgeInsets.fromLTRB(10, 9, 9, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FFFD),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x29012F2C),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Rx',
                        style: TextStyle(
                          color: Color(0xFF07675F),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.medical_services_rounded,
                        color: Color(0xFF23A395),
                        size: 13,
                      ),
                    ],
                  ),
                  SizedBox(height: 9),
                  _PrescriptionLine(width: 42),
                  SizedBox(height: 6),
                  _PrescriptionLine(width: 49),
                  SizedBox(height: 9),
                  _PrescriptionCheckLine(width: 31),
                  SizedBox(height: 6),
                  _PrescriptionCheckLine(width: 37),
                ],
              ),
            ),
          ),
          Positioned(
            right: 1,
            bottom: 3,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFD4FFF1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF08766C),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionLine extends StatelessWidget {
  const _PrescriptionLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFD7E9E5),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _PrescriptionCheckLine extends StatelessWidget {
  const _PrescriptionCheckLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: Color(0xFFBCEADF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF08766C),
            size: 7,
          ),
        ),
        const SizedBox(width: 4),
        _PrescriptionLine(width: width),
      ],
    );
  }
}

class _PrescriptionJourney extends StatelessWidget {
  const _PrescriptionJourney();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .075),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _PrescriptionStage(
              icon: Icons.upload_file_rounded,
              label: 'Upload',
            ),
          ),
          _JourneyConnector(),
          Expanded(
            child: _PrescriptionStage(
              icon: Icons.fact_check_outlined,
              label: 'Reviewed',
            ),
          ),
          _JourneyConnector(),
          Expanded(
            child: _PrescriptionStage(
              icon: Icons.touch_app_rounded,
              label: 'You approve',
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionStage extends StatelessWidget {
  const _PrescriptionStage({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFFD3F2EC), size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE4F8F4),
              fontSize: 9.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _JourneyConnector extends StatelessWidget {
  const _JourneyConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: Colors.white.withValues(alpha: .26),
    );
  }
}

class _SecondaryCareActions extends StatelessWidget {
  const _SecondaryCareActions({
    required this.onBookTest,
    required this.onViewReports,
  });

  final VoidCallback onBookTest;
  final VoidCallback onViewReports;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CareActionCard(
            icon: Icons.biotech_rounded,
            title: 'Browse tests',
            subtitle: 'Search the catalogue',
            accent: const Color(0xFF1769E8),
            tint: const Color(0xFFEDF4FF),
            onTap: onBookTest,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _CareActionCard(
            icon: Icons.description_rounded,
            title: 'My reports',
            subtitle: 'View lab results',
            accent: const Color(0xFF08766C),
            tint: const Color(0xFFEAF8F5),
            onTap: onViewReports,
          ),
        ),
      ],
    );
  }
}

class _CareActionCard extends StatelessWidget {
  const _CareActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 104,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _HomePalette.border),
            boxShadow: _HomePalette.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 37,
                    height: 37,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    color: accent,
                    size: 18,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomePalette.ink,
                  fontSize: 14.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomePalette.muted,
                  fontSize: 10.6,
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
            color: Color(0xFF08766C),
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

  static const Color background = Color(0xFFF7FAFA);

  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE6EAF0);

  static const Color primary = Color(0xFF2563EB);

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: .025),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}
