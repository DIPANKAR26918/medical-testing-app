import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../utils/index.dart';
import '../widgets/index.dart';

/// Home screen showing user's orders and upload button
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FirestoreService _firestoreService;
  late AuthService _authService;
  late String _userId;
  final int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _authService = AuthService();
    _userId = _authService.getUserId() ?? '';
  }

  /// Navigate to upload prescription screen
  void _navigateToUpload() {
    Navigator.of(context).pushNamed('/upload').then((_) {
      // Refresh the screen after returning from upload
      setState(() {});
    });
  }

  /// Navigate to order details screen
  void _navigateToOrderDetails(Order order) {
    Navigator.of(context).pushNamed('/order-details', arguments: order);
  }

  /// Handle bottom navigation taps
  void _onNavTap(int index) {
    switch (index) {
      case 0:
        // Already on home screen
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/upload');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/test-status');
        break;
    }
  }

  /// Handle logout
  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.logout),
        content: Text(AppStrings.logoutPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/auth');
              }
            },
            child: Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(AppStrings.home),
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _handleLogout,
                child: Text(AppStrings.logout),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Order>>(
        stream: _firestoreService.getUserOrders(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppLoadingWidget(message: AppStrings.loading);
          }

          if (snapshot.hasError) {
            return AppErrorWidget(
              message: '${AppStrings.error}: ${snapshot.error}',
              onRetry: () => setState(() {}),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return AppEmptyWidget(
              message: AppStrings.noOrders,
              icon: Icons.inbox,
              onAction: _navigateToUpload,
              actionLabel: AppStrings.uploadPrescription,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh the stream
              setState(() {});
            },
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return OrderCard(
                  order: orders[index],
                  onTap: () => _navigateToOrderDetails(orders[index]),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToUpload,
        backgroundColor: const Color.fromARGB(255, 39, 191, 225),
        child: const Icon(Icons.add_a_photo),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
