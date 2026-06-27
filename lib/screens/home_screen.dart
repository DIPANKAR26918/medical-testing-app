import 'package:flutter/material.dart';

import '../services/index.dart';
import 'all_categories_page.dart';
import '../widgets/banners.dart';
import '../widgets/dual_service_cards.dart';
import '../widgets/home/home_app_bar.dart';
import '../widgets/home/home_search_section.dart';
import '../widgets/home/medical_tab_rail.dart';
import '../widgets/home/popular_health_grid.dart';
import '../widgets/home/trust_strip.dart';
import '../widgets/home/quick_actions_row.dart';
import '../widgets/home/prescription_shortcut.dart';
import '../widgets/home/partner_labs_banner.dart';
import '../widgets/home/categories_section.dart';
import '../widgets/home/recent_orders_section.dart';
import '../widgets/home/social_proof_banner.dart';
import '../widgets/home/home_constants.dart';

// ─────────────────────────────────────────────────────────────────────
// MainNavigationScreen — root shell with bottom nav + page view
// ─────────────────────────────────────────────────────────────────────

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final AuthService _authService = AuthService();
  int _selectedHomeTab = 0;

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

  void _openOrdersTab() => _onNavTap(1);

  // ───────────────────────────────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [HomeColors.bgTop, HomeColors.bgMid, HomeColors.bgBottom],
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
                accent: HomeColors.teal,
              ),
              _buildSimpleTab(
                title: 'Reports',
                subtitle:
                    'View, share, and manage your lab reports from one place.',
                icon: Icons.description_rounded,
                accent: HomeColors.orange,
              ),
              _buildProfileTab(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // Home Tab — composed from extracted widgets
  // ───────────────────────────────────────────────────────────────────

  Widget _buildHomeTab() {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: HomeSpacing.listPadding,
      children: [
        // ── Header zone (gradient background) ───────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [HomeColors.bgTop, HomeColors.bgMid],
            ),
          ),
          child: Column(
            children: [
              const HomeAppBar(),
              HomeSearchSection(onScanTap: _openAllCategories),
              const SizedBox(height: 14),
              MedicalTabRail(
                selectedIndex: _selectedHomeTab,
                onTabChanged: (i) => setState(() => _selectedHomeTab = i),
              ),
            ],
          ),
        ),

        // ── Content zone ────────────────────────────────────────────
        Padding(
          padding: HomeSpacing.contentPadding,
          child: Column(
            children: [
              const HomeBanner(),
              const SizedBox(height: 18),
              PopularHealthGrid(onItemTap: _openAllCategories),
              const SizedBox(height: 18),
              const DualServiceCards(),
              const SizedBox(height: 14),
              const SocialProofBanner(),
              const SizedBox(height: 14),
              const TrustStrip(),
              const SizedBox(height: 14),
              QuickActionsRow(
                onSearchTap: _openAllCategories,
                onUploadTap: () => Navigator.pushNamed(context, '/upload'),
                onTrackTap: _openOrdersTab,
              ),
              const SizedBox(height: 12),
              PrescriptionShortcut(
                onTap: () => Navigator.pushNamed(context, '/upload'),
              ),
              const SizedBox(height: 12),
              const PartnerLabsBanner(),
              const SizedBox(height: 18),
              CategoriesSection(onViewAll: _openAllCategories),
              const SizedBox(height: 18),
              RecentOrdersSection(userId: _currentUserId()),
              const SizedBox(height: 14),
              const TrustStrip(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // Placeholder tabs (Bookings / Reports)
  // ───────────────────────────────────────────────────────────────────

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
            border: Border.all(color: HomeColors.border),
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
                  color: HomeColors.deepBlue,
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

  // ───────────────────────────────────────────────────────────────────
  // Profile tab
  // ───────────────────────────────────────────────────────────────────

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: HomeColors.border),
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
                  color: HomeColors.deepBlue,
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
                    backgroundColor: HomeColors.deepBlue,
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

  // ───────────────────────────────────────────────────────────────────
  // Bottom navigation
  // ───────────────────────────────────────────────────────────────────

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
        selectedItemColor: HomeColors.teal,
        unselectedItemColor: Colors.grey.shade500,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
