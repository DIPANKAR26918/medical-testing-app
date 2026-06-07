import 'package:flutter/material.dart';
import '../services/index.dart'; // Assuming your services are here
import '../models/index.dart'; // Assuming Order/User models are here

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // 1. Functional State Variables
  int _currentIndex = 0;
  late PageController _pageController;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

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

  // 2. Real Navigation Logic (No "flicker" pushReplacement)
  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep the beautiful UI, but make the body dynamic
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Colors.white],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          // 3. PageView allows for smooth swiping between functional sections
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            children: [
              _buildHomeTab(), // The Dashboard
              const Center(child: Text("Bookings Page")),
              const Center(child: Text("Reports Page")),
              _buildProfileTab(), // Real Profile Logic
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCategoriesSection() {
    // Data for the categories
    final categories = [
      {
        'name': 'Blood Tests',
        'icon': Icons.opacity,
        'color': Colors.red.shade50,
      },
      {
        'name': 'Health Packages',
        'icon': Icons.medical_services_outlined,
        'color': Colors.green.shade50,
      },
      {
        'name': 'Heart Care',
        'icon': Icons.favorite_outline,
        'color': Colors.pink.shade50,
      },
      {
        'name': 'Diabetes Care',
        'icon': Icons.bloodtype_outlined,
        'color': Colors.orange.shade50,
      },
      {
        'name': 'Thyroid Tests',
        'icon': Icons.science_outlined,
        'color': Colors.blue.shade50,
      },
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Popular Categories",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: () {}, child: const Text("View All")),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: categories[index]['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      categories[index]['icon'] as IconData,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    categories[index]['name'] as String,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 1: FUNCTIONAL DASHBOARD ---

  // --- DATA BINDING: LIVE ORDERS ---
  Widget _buildLiveOrdersList() {
    return StreamBuilder<List<Order>>(
      stream: _firestoreService.getUserOrders(_authService.getUserId() ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text("No recent orders found.");
        }

        return ListView.builder(
          shrinkWrap: true, // Crucial for use inside SingleChildScrollView
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final order = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text("Order #${order.orderId}"),
                subtitle: Text("Status: ${order.status}"),
                trailing: const Icon(Icons.chevron_right),
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

  // --- TAB 4: PROFILE & LOGOUT ---
  Widget _buildProfileTab() {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          await _authService.signOut();
          if (mounted) Navigator.pushReplacementNamed(context, '/auth');
        },
        child: const Text("Logout"),
      ),
    );
  }

  // UI Components (Kept from your 2nd version but modularized)
  Widget _buildHeroText(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hi, $name 👋",
          style: const TextStyle(fontSize: 18, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        const Text(
          "Your health,\nour priority.",
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onNavTap,
      selectedItemColor: Colors.teal.shade700,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: "Bookings",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description),
          label: "Reports",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }

  // ... ( _buildTopBar, _buildSearchBar, and _serviceCard helpers here)
  // --- TOP BAR WITH LOCATION & NOTIFICATION ---
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.location_on_outlined, size: 20, color: Colors.black54),
            SizedBox(width: 4),
            Text("Pundibari, Coochbehar", style: TextStyle(fontSize: 16)),
            Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          ],
        ),
        const Icon(Icons.notifications_none_outlined, size: 28),
      ],
    );
  }

  // --- CUSTOM SEARCH BAR ---
  Widget _buildSearchBar() {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.search, color: Colors.grey),
          SizedBox(width: 12),
          Text(
            "Search for tests, packages & more",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // --- DUAL SERVICE CARDS ---
  Widget _buildDualServiceCards() {
    return Row(
      children: [
        _serviceCard(
          "Lab Tests\nat Home",
          "Book tests and get\nsample collection\nat your doorstep.",
          const Color(0xFFF1F8E9),
          Colors.teal.shade400,
          Icons.home_work_outlined,
        ),
        const SizedBox(width: 16),
        _serviceCard(
          "Book Tests at\nPartner Labs",
          "Schedule advanced\ntests & scans at\ntrusted labs.",
          const Color(0xFFE3F2FD),
          Colors.blue.shade400,
          Icons.calendar_month_outlined,
        ),
      ],
    );
  }

  // --- REUSABLE SERVICE CARD HELPER ---
  Widget _serviceCard(
    String title,
    String desc,
    Color bg,
    Color accent,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        height: 210, // Slightly taller for better spacing
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 36),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: TextStyle(
                fontSize: 11,
                color: Colors.black.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const Spacer(),
            CircleAvatar(
              radius: 16,
              backgroundColor: accent,
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 32),
          _buildHeroText("Guest"),
          const SizedBox(height: 28),
          _buildSearchBar(),
          const SizedBox(height: 32),
          _buildDualServiceCards(),
          const SizedBox(height: 32), // Added spacing
          _buildCategoriesSection(), // <--- NEW SECTION ADDED HERE
          const SizedBox(height: 40),
          const Text(
            "Your Recent Orders",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildLiveOrdersList(),
        ],
      ),
    );
  }
}
