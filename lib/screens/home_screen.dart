import 'package:flutter/material.dart';

import 'bookings_screen.dart';
import 'complete_profile_screen.dart';
import 'home_dashboard_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import '../services/index.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final AuthService _authService = AuthService();
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfProfileMissing();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _openAllCategories() {
    Navigator.pushNamed(context, '/all-categories');
  }

  void _openSearch() {
    Navigator.pushNamed(context, '/search');
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/auth');
  }

  Future<void> _redirectIfProfileMissing() async {
    final user = _authService.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/auth');
      return;
    }

    final profile = await _authService.getUserProfile(user.id);

    if (!mounted || profile != null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompleteProfileScreen(
          phoneNumber: user.phone,
          email: user.email,
          initialName: _nameFromUserMetadata(),
        ),
      ),
    );
  }

  String? _nameFromUserMetadata() {
    final metadata = _authService.currentUser?.userMetadata ?? {};
    final name =
        metadata['full_name'] ?? metadata['name'] ?? metadata['given_name'];
    final text = name?.toString().trim();
    return text == null || text.isEmpty ? null : text;
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
            colors: [Color(0xFFEAF7F7), Color(0xFFF7FAFC)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            children: [
              HomeDashboardScreen(
                onBookTest: () => _onNavTap(1),
                onViewReports: () => _onNavTap(2),
                onUploadPrescription: () => Navigator.pushNamed(
                  context,
                  '/upload',
                ),
                onSearch: _openSearch,
                onViewCategories: _openAllCategories,
              ),
              BookingsScreen(onBookNewTest: _openAllCategories),
              ReportsScreen(
                onUploadPrescription: () => Navigator.pushNamed(
                  context,
                  '/upload',
                ),
              ),
              ProfileScreen(onLogout: _logout),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _MedicalBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _MedicalBottomNav extends StatelessWidget {
  const _MedicalBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.event_available_rounded, Icons.event_available_outlined, 'Bookings'),
    (Icons.assignment_rounded, Icons.assignment_outlined, 'Reports'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: _NavButton(
                selected: currentIndex == i,
                selectedIcon: _items[i].$1,
                icon: _items[i].$2,
                label: _items[i].$3,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.selected,
    required this.selectedIcon,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData selectedIcon;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F6F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              size: 22,
              color: selected ? const Color(0xFF087E86) : const Color(0xFF718096),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    selected ? const Color(0xFF075E63) : const Color(0xFF718096),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
