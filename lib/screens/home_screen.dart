import 'package:flutter/material.dart';

import 'bookings_screen.dart';
import 'complete_profile_screen.dart';
import 'home_dashboard_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import '../services/index.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({this.initialIndex = 0, super.key});

  final int initialIndex;

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
    _currentIndex = widget.initialIndex.clamp(0, 3).toInt();
    _pageController = PageController(initialPage: _currentIndex);

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
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _openAllCategories() {
    Navigator.pushNamed(context, '/all-categories');
  }

  void _openSearch() {
    Navigator.pushNamed(context, '/search');
  }

  void _openUploadPrescription() {
    Navigator.pushNamed(context, '/upload');
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
      backgroundColor: _NavPalette.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
            }
          },
          children: [
            HomeDashboardScreen(
              onBookTest: _openAllCategories,
              onViewReports: () => _onNavTap(2),
              onUploadPrescription: _openUploadPrescription,
              onSearch: _openSearch,
              onViewCategories: _openAllCategories,
            ),
            BookingsScreen(
              onBookNewTest: _openAllCategories,
              onUploadPrescription: _openUploadPrescription,
            ),
            ReportsScreen(
              onUploadPrescription: _openUploadPrescription,
              onBookTest: _openAllCategories,
            ),
            ProfileScreen(onLogout: _logout),
          ],
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
  const _MedicalBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(
      selectedIcon: Icons.home_rounded,
      icon: Icons.home_outlined,
      label: 'Home',
    ),
    _NavItem(
      selectedIcon: Icons.calendar_month_rounded,
      icon: Icons.calendar_month_outlined,
      label: 'Bookings',
    ),
    _NavItem(
      selectedIcon: Icons.description_rounded,
      icon: Icons.description_outlined,
      label: 'Reports',
    ),
    _NavItem(
      selectedIcon: Icons.person_rounded,
      icon: Icons.person_outline_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _NavPalette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _NavButton(
                  item: _items[i],
                  selected: currentIndex == i,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _NavPalette.primary : _NavPalette.muted;

    return Material(
      color: selected ? _NavPalette.selectedFill : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 21,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.selectedIcon,
    required this.icon,
    required this.label,
  });

  final IconData selectedIcon;
  final IconData icon;
  final String label;
}

class _NavPalette {
  const _NavPalette._();

  static const Color background = Color(0xFFFAFBFC);
  static const Color border = Color(0xFFE6EAF0);
  static const Color primary = Color(0xFF2563EB);
  static const Color muted = Color(0xFF64748B);
  static const Color selectedFill = Color(0xFFEFF6FF);
}
