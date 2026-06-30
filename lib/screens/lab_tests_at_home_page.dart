import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart'; // Skeletonizer package
// import 'dart:convert'; // Uncomment if using real HTTP requests
// import 'package:http/http.dart' as http;

/// Data model for a lab test or package.
class LabTest {
  final String name;
  final String description;
  final int price;
  const LabTest({
    required this.name,
    required this.description,
    required this.price,
  });
  // Example factory if fetching from JSON:
  factory LabTest.fromJson(Map<String, dynamic> json) {
    return LabTest(
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
    );
  }
}

class LabTestsPage extends StatefulWidget {
  const LabTestsPage({super.key});
  @override
  State<LabTestsPage> createState() => _LabTestsPageState();
}

class _LabTestsPageState extends State<LabTestsPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<LabTest> _tests = [];

  // Animation controller and animations for staggered entry
  late AnimationController _controller;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    // Controller drives all animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _setupAnimations();
    _loadData(); // fetch or simulate fetching data
  }

  void _setupAnimations() {
    // Prepare staggered animations (6 slots, index 0-5).
    final itemCount = 6;
    _slideAnimations = List.generate(itemCount, (i) {
      final start = i * 0.1;
      final end = start + 0.5;
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
    _fadeAnimations = List.generate(itemCount, (i) {
      final start = i * 0.1;
      final end = start + 0.5;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
  }

  Future<void> _loadData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 3500));

    // TODO: Replace this with your real API call. For example:
    // final response = await http.get(Uri.parse('https://api.example.com/tests'));
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body) as List;
    //   setState(() {
    //     _tests = data.map((e) => LabTest.fromJson(e)).toList();
    //     _loading = false;
    //   });
    // }

    // For demo, assign example data:
    setState(() {
      _tests = const [
        LabTest(
          name: 'Complete Blood Count',
          description: 'Basic blood screening test',
          price: 499,
        ),
        LabTest(
          name: 'Full Body Checkup',
          description: 'Comprehensive wellness package',
          price: 2999,
        ),
        LabTest(
          name: 'Lipid Profile',
          description: 'Cholesterol and triglycerides test',
          price: 899,
        ),
        LabTest(
          name: 'Urine Routine',
          description: 'Basic urine analysis',
          price: 199,
        ),
      ];
      _loading = false;
    });
    // Start card entry animations
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Builds each test card (skeleton or real) with optional animations.
  Widget _buildTestCard(LabTest test, int index) {
    Widget card = Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              test.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              test.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${test.price}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Handle booking action
                  },
                  child: const Text('Book Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Apply staggered animation if data is loaded
    if (!_loading) {
      final slide =
          _slideAnimations[index.clamp(0, _slideAnimations.length - 1)];
      final fade = _fadeAnimations[index.clamp(0, _fadeAnimations.length - 1)];
      card = SlideTransition(
        position: slide,
        child: FadeTransition(opacity: fade, child: card),
      );
    }
    return card;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar: using a custom header in the body
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = _buildContent(context);
          // Constrain on wide screens for better readability.
          if (constraints.maxWidth > 600) {
            content = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: content,
              ),
            );
          }
          return content;
        },
      ),
    );
  }

  // Builds the main scrollable content (skeletonized or real).
  Widget _buildContent(BuildContext context) {
    // Provide fake data for layout during loading
    final displayTests = _loading
        ? List<LabTest>.filled(
            4,
            const LabTest(
              name: 'Premium Full Body Checkup (65 params)',
              description: 'Comprehensive package including all tests',
              price: 0,
            ),
          )
        : _tests;

    return Skeletonizer(
      enabled: _loading,
      enableSwitchAnimation: true,
      justifyMultiLineText: true,
      containersColor: Color(0xFFE0E0E0), // fade out skeleton when switching
      effect: const ShimmerEffect(
        baseColor: Color(0xFFD6D6D6), // OR use Color(0xFFE0E0E0)
        highlightColor: Color(0xFFF5F5F5), //OR use Color(0xFFF5F5F5)
        duration: Duration(milliseconds: 1500),
      ),

      child: SafeArea(
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),

          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------- Hero / Header Section --------
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Verified Service',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D8C92),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(height: 8),
                      Text(
                        'Lab Tests at Home',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your personalized health checkup starts here',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // -------- Category Chips --------
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      FilterChip(
                        label: const Text('All Tests'),
                        selected: true,
                        onSelected: (_) {},
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Popular'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Full Body'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Blood'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Urine'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // -------- Info Banner --------
                Card(
                  color: const Color(0xFFEFF6FF),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.local_shipping,
                      color: const Color(0xFF2563EB),
                    ),
                    title: const Text('Free Sample Collection'),
                    subtitle: const Text(
                      'We only charge the actual price of tests.',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // -------- Test Cards List --------
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: displayTests.length,
                  itemBuilder: (context, index) {
                    return _buildTestCard(displayTests[index], index);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
