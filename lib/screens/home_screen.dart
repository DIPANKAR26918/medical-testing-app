import 'dart:async';
import 'package:flutter/services.dart';

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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
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
    unawaited(DeviceFeedbackService.navigationSelection());
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
      backgroundColor: Colors.white,
      extendBody: true,
      extendBodyBehindAppBar: true,
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
              isVisible: _currentIndex == 0,
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
        height: 72,
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 20,
              offset: Offset(0, -4),
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
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: _NavPalette.primary.withValues(alpha: 0.06),
          highlightColor: Colors.transparent,
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: selected ? 56 : 24,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected
                        ? _NavPalette.primary.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 22,
                    color: selected ? _NavPalette.primary : _NavPalette.muted,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    color: selected ? _NavPalette.primary : _NavPalette.muted,
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
  static const Color background = Colors.white;
  static const Color border = Color(0xFFF0F1F3);
  static const Color primary = Color(0xFF0D9B8C);  // brand teal, not blue
  static const Color muted = Color(0xFF9AA0A6);
}
