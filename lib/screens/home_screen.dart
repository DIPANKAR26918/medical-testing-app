import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

import '../data/categories_data.dart';
import '../models/index.dart';
import '../services/index.dart';
import 'all_categories_page.dart';
import 'lab_tests_at_home_page.dart';
import '../widgets/dual_service_cards.dart';
import '../widgets/search_bar.dart';
import '../widgets/home_header.dart';
import '../widgets/banners.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedHomeTab = 0;

  static const Color _bgTop = Color.fromARGB(255, 1, 131, 134);
  static const Color _bgMid = Color(0xFFEAF8FF);
  static const Color _bgBottom = Color(0xFFFFFFFF);
  static const Color _teal = Color(0xFF0E8C93);
  static const Color _deepBlue = Color(0xFF0F2A44);
  static const Color _orange = Color(0xFFF97316);
  // static const Color _ice = Color(0xFFEAF7F8);
  //static const Color _mutedText = Color(0xFF5B6673);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String? _currentUserId() => _authService.getCurrentUserId();

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _openAllCategories() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AllCategoriesPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _openOrdersTab() {
    _onNavTap(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgMid, _bgBottom],
            stops: [0.0, 0.34, 0.64],
          ),
        ),
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            children: [
              _buildHomeTab(),
              _buildSimpleTab(
                title: 'Bookings',
                subtitle:
                    'Track appointments, home collections, and upcoming visits.',
                icon: Icons.calendar_month_rounded,
                accent: _teal,
              ),
              _buildSimpleTab(
                title: 'Reports',
                subtitle:
                    'View, share, and manage your lab reports from one place.',
                icon: Icons.description_rounded,
                accent: _orange,
              ),
              _buildProfileTab(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab() {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 104),
      children: [
        _buildMarketplaceHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            children: [
              const HomeBanner(),
              const SizedBox(height: 18),
              _buildTestCollectionsGrid(),
              const SizedBox(height: 18),
              const DualServiceCards(),
              const SizedBox(height: 14),
              _buildProofStrip(),
              const SizedBox(height: 14),
              _buildQuickActionsRow(),
              const SizedBox(height: 12),
              _buildPrescriptionShortcut(),
              const SizedBox(height: 12),
              _buildPartnerLabsBanner(),
              const SizedBox(height: 18),
              _buildCategoriesSection(),
              const SizedBox(height: 18),
              _buildOrdersSection(),
              const SizedBox(height: 14),
              _buildProofStrip(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarketplaceHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgTop, _bgMid],
        ),
      ),
      child: Column(
        children: [
          _buildTopServiceShortcuts(),
          const SizedBox(height: 16),
          const HomeHeader(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: HomeSearchBar()),
              const SizedBox(width: 10),
              _HeaderIconButton(
                icon: Icons.qr_code_scanner_rounded,
                onTap: _openAllCategories,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildMedicalTabRail(),
        ],
      ),
    );
  }

  Widget _buildTopServiceShortcuts() {
    final shortcuts = [
      _HomeShortcut(
        title: 'Lab Tests',
        icon: Icons.science_rounded,
        background: const Color(0xFFFFE35B),
        foreground: _deepBlue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LabTestsPage()),
        ),
      ),
      _HomeShortcut(
        title: 'Packages',
        icon: Icons.health_and_safety_rounded,
        background: Colors.white,
        foreground: const Color(0xFF0E7490),
        onTap: _openAllCategories,
      ),
      _HomeShortcut(
        title: 'Upload Rx',
        icon: Icons.upload_file_rounded,
        background: Colors.white,
        foreground: _orange,
        onTap: () {},
      ),
      _HomeShortcut(
        title: 'Reports',
        icon: Icons.description_rounded,
        background: Colors.white,
        foreground: const Color(0xFF2563EB),
        onTap: () => _onNavTap(2),
      ),
    ];

    return Row(
      children: [
        for (var index = 0; index < shortcuts.length; index++) ...[
          Expanded(child: _ShortcutTile(shortcut: shortcuts[index])),
          if (index != shortcuts.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildMedicalTabRail() {
    const tabs = [
      _HomeTabData('For You', Icons.home_rounded),
      _HomeTabData('Lab Tests', Icons.biotech_rounded),
      _HomeTabData('Packages', Icons.inventory_2_rounded),
      _HomeTabData('Upload Rx', Icons.note_alt_rounded),
      _HomeTabData('Reports', Icons.fact_check_rounded),
      _HomeTabData('Scans', Icons.monitor_heart_rounded),
    ];

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = _selectedHomeTab == index;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _selectedHomeTab = index),
            child: SizedBox(
              width: 76,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    tab.icon,
                    size: 29,
                    color: isSelected ? _deepBlue : const Color(0xFF364152),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: isSelected ? _deepBlue : const Color(0xFF364152),
                    ),
                  ),
                  const SizedBox(height: 7),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: isSelected ? 58 : 0,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTestCollectionsGrid() {
    final collections = [
      _CollectionItem(
        label: 'Thunder deals',
        icon: Icons.bolt_rounded,
        color: const Color(0xFFDC2626),
      ),
      _CollectionItem(
        label: 'Full body',
        icon: Icons.accessibility_new_rounded,
        color: const Color(0xFF0E7490),
      ),
      _CollectionItem(
        label: 'CBC',
        icon: Icons.bloodtype_rounded,
        color: const Color(0xFFE11D48),
      ),
      _CollectionItem(
        label: 'Diabetes',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFFF97316),
      ),
      _CollectionItem(
        label: 'Thyroid',
        icon: Icons.local_hospital_rounded,
        color: const Color(0xFF4F46E5),
      ),
      _CollectionItem(
        label: 'Heart',
        icon: Icons.favorite_rounded,
        color: const Color(0xFFDB2777),
      ),
      _CollectionItem(
        label: 'Vitamins',
        icon: Icons.medication_rounded,
        color: const Color(0xFFCA8A04),
      ),
      _CollectionItem(
        label: 'Home visit',
        icon: Icons.home_work_rounded,
        color: const Color(0xFF16A34A),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular health picks',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: _deepBlue,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 172,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              mainAxisExtent: 82,
            ),
            itemCount: collections.length,
            itemBuilder: (context, index) => _CollectionTile(
              item: collections[index],
              onTap: _openAllCategories,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProofStrip() {
    return Row(
      children: const [
        Expanded(
          child: _MiniTrustCard(
            icon: Icons.verified_rounded,
            title: 'NABL verified',
            subtitle: 'Reliable labs only',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MiniTrustCard(
            icon: Icons.timer_rounded,
            title: 'Fast slot',
            subtitle: 'Pick a 60 min window',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MiniTrustCard(
            icon: Icons.lock_rounded,
            title: 'Private by default',
            subtitle: 'Secure reports and data',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: Icons.search_rounded,
            title: 'Search tests',
            subtitle: 'Find fast',
            color: const Color(0xFF2563EB),
            onTap: _openAllCategories,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.upload_file_rounded,
            title: 'Upload Rx',
            subtitle: 'Get help',
            color: _teal,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.receipt_long_rounded,
            title: 'Track order',
            subtitle: 'Live status',
            color: _orange,
            onTap: _openOrdersTab,
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionShortcut() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: .05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.note_alt_rounded, color: _teal),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload prescription',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: _deepBlue,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Not sure which tests to book? Let us map it for you.',
                  style: TextStyle(
                    fontSize: 12.7,
                    color: Colors.black54,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: _orange,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerLabsBanner() {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD9E7FF)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need MRI, CT Scan or X-Ray?',
                    style: TextStyle(
                      fontSize: 15.2,
                      fontWeight: FontWeight.w900,
                      color: _deepBlue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Find trusted partner labs and save up to 20%.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black54,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 17,
              color: Color(0xFF2563EB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final popularCategories = categories.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Popular Categories',
          actionText: 'View all',
          onTap: _openAllCategories,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: popularCategories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = popularCategories[index];
              return _CategoryTile(category: category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Your Recent Orders',
          actionText: '',
          onTap: null,
        ),
        const SizedBox(height: 12),
        _buildLiveOrdersList(),
      ],
    );
  }

  Widget _buildLiveOrdersList() {
    final userId = _currentUserId();

    if (userId == null || userId.isEmpty) {
      return _emptyStateCard(
        title: 'Log in to see your orders',
        subtitle: 'Track collections, reports, and past bookings here.',
        icon: Icons.lock_outline_rounded,
      );
    }

    return StreamBuilder<List<Order>>(
      stream: _firestoreService.getUserOrders(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return _emptyStateCard(
            title: 'No recent orders yet',
            subtitle: 'Book your first test and keep everything in one place.',
            icon: Icons.receipt_long_rounded,
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withValues(alpha: .05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .03),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: _teal),
                ),
                title: Text(
                  'Order #${order.orderId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _deepBlue,
                  ),
                ),
                subtitle: Text(
                  'Status: ${order.status}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: _teal),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/order-details',
                  arguments: order,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyStateCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: .05)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: _teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.2,
                    fontWeight: FontWeight.w900,
                    color: _deepBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.7,
                    color: Colors.grey.shade600,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black.withValues(alpha: .05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: accent, size: 32),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _deepBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: .65),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _openAllCategories,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black.withValues(alpha: .05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _deepBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your account and settings.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: .65),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    await _authService.signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/auth');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deepBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _teal,
        unselectedItemColor: Colors.grey.shade500,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeShortcut {
  final String title;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _HomeShortcut({
    required this.title,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });
}

class _ShortcutTile extends StatelessWidget {
  final _HomeShortcut shortcut;

  const _ShortcutTile({required this.shortcut});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: shortcut.onTap,
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: shortcut.background,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(shortcut.icon, color: shortcut.foreground, size: 28),
            const SizedBox(height: 5),
            Text(
              shortcut.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: shortcut.foreground,
                fontSize: 12.8,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .52)),
        ),
        child: Icon(icon, color: const Color(0xFF4B5563), size: 29),
      ),
    );
  }
}

class _HomeTabData {
  final String label;
  final IconData icon;

  const _HomeTabData(this.label, this.icon);
}

class _CollectionItem {
  final String label;
  final IconData icon;
  final Color color;

  const _CollectionItem({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _CollectionTile extends StatelessWidget {
  final _CollectionItem item;
  final VoidCallback onTap;

  const _CollectionTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.color, size: 28),
          ),
          const SizedBox(height: 7),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTrustCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MiniTrustCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: .05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF0E8C93).withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF0E8C93)),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.4,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F2A44),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.2,
              color: Colors.black.withValues(alpha: .55),
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 96,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: .05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .03),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2A44),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.8,
                  color: Colors.black.withValues(alpha: .55),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F2A44),
            ),
          ),
        ),
        if (onTap != null && actionText.isNotEmpty)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0E8C93),
              padding: EdgeInsets.zero,
            ),
            child: Text(
              actionText,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Map<String, dynamic> category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: category['color'] as Color,
            shadows: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 18,
                cornerSmoothing: 0.6,
              ),
            ),
          ),
          child: Icon(
            category['icon'] as IconData,
            color: category['iconColor'] as Color,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 78,
          child: Text(
            category['name'] as String,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}
