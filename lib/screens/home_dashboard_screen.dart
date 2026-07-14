import 'package:flutter/material.dart';

import '../models/index.dart';
import '../services/index.dart';
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
    super.key,
  });

  final VoidCallback onBookTest;
  final VoidCallback onViewReports;
  final VoidCallback onUploadPrescription;
  final VoidCallback onSearch;
  final VoidCallback onViewCategories;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final MedicalTestCatalogService _catalogService =
      MedicalTestCatalogService();

  late Future<AppUser?> _profileFuture;
  HomeMedicalTestFeed? _medicalTestFeed;
  Object? _medicalTestFeedError;
  bool _isMedicalTestFeedLoading = true;
  DateTime? _lastFeedLoadedAt;
  int _feedRequestGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profileFuture = _loadProfile();
    _loadMedicalTestFeed();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final loadedAt = _lastFeedLoadedAt;
    if (loadedAt == null ||
        DateTime.now().difference(loadedAt) > const Duration(minutes: 1)) {
      _loadMedicalTestFeed(showRefreshError: false);
    }
  }

  Future<AppUser?> _loadProfile() async {
    final userId = _authService.getCurrentUserId();
    if (userId == null) return null;
    return _authService.getUserProfile(userId);
  }

  Future<void> _loadMedicalTestFeed({bool showRefreshError = true}) async {
    final requestGeneration = ++_feedRequestGeneration;

    if (_medicalTestFeed == null &&
        !_isMedicalTestFeedLoading &&
        mounted) {
      setState(() {
        _isMedicalTestFeedLoading = true;
        _medicalTestFeedError = null;
      });
    }

    try {
      final feed = await _catalogService.fetchHomeFeed();
      if (!mounted || requestGeneration != _feedRequestGeneration) return;
      setState(() {
        _medicalTestFeed = feed;
        _medicalTestFeedError = null;
        _isMedicalTestFeedLoading = false;
        _lastFeedLoadedAt = DateTime.now();
      });
    } catch (error) {
      if (!mounted || requestGeneration != _feedRequestGeneration) return;
      final hasExistingFeed = _medicalTestFeed != null;
      setState(() {
        _medicalTestFeedError = error;
        _isMedicalTestFeedLoading = false;
      });

      if (hasExistingFeed && showRefreshError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not refresh tests. Showing the last list.'),
          ),
        );
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
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
          children: [
            _TopLocationRow(onNotificationTap: _openNotifications),
            const SizedBox(height: 18),
            FutureBuilder<AppUser?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                final firstName = _firstName(snapshot.data);

                return _GreetingHeader(firstName: firstName);
              },
            ),
            const SizedBox(height: 16),
            HomeSearchBar(onTap: widget.onSearch),
            const SizedBox(height: 16),
            HomeBanner(
              //onTapBanner: (_) => widget.onViewCategories(),
            ),
            const SizedBox(height: 16),
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
        ),
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

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final title = firstName.isEmpty ? 'Testified' : 'Hi $firstName';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _HomePalette.ink,
            fontSize: 26,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Book lab tests at home. Review everything before payment.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _HomePalette.muted,
            fontSize: 13,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(radius: 22),
      child: Column(
        children: [
          _PrimaryActionCard(
            title: 'Book a test',
            subtitle: 'Search lab tests for home sample collection.',
            icon: Icons.science_rounded,
            onTap: onBookTest,
          ),
          const SizedBox(height: 10),
          _PrimaryActionCard(
            title: 'Upload prescription',
            subtitle: 'We’ll prepare your test list before payment.',
            icon: Icons.description_rounded,
            onTap: onUploadPrescription,
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _HomePalette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _HomePalette.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: _HomePalette.primary, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomePalette.ink,
                        fontSize: 15.5,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomePalette.muted,
                        fontSize: 12.6,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: _HomePalette.softMuted,
                size: 22,
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
