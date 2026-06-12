// Import Flutter and related packages
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart'; // The shimmer loader package
// import 'package:http/http.dart' as http; // Uncomment for real API calls

// Data model for a lab test or package
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
  // Loading state and data list
  bool _loading = true;
  List<LabTest> _tests = [];

  // Animation controller for card entrance
  late AnimationController _controller;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Prepare animations (will be based on max items)
    _setupAnimations();
    // Start data fetching
    _loadData();
  }

  // Create staggered animations for up to 6 items
  void _setupAnimations() {
    final itemCount = 6;
    _slideAnimations = List.generate(itemCount, (i) {
      // Each animation interval is offset by 0.1 (100ms) per item
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

  // Simulate data loading (replace with real API call)
  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulated network delay

    // In production, use http package:
    // final response = await http.get(Uri.parse('https://api.example.com/tests'));
    // if (response.statusCode == 200) {
    //   final List jsonData = jsonDecode(response.body);
    //   setState(() {
    //     _tests = jsonData.map((e) => LabTest.fromJson(e)).toList();
    //     _loading = false;
    //   });
    // }

    // For demo, assign fake data
    setState(() {
      _tests = [
        const LabTest(
          name: 'Complete Blood Count',
          description: 'Basic health screening blood test',
          price: 499,
        ),
        const LabTest(
          name: 'Full Body Checkup',
          description: 'Comprehensive health checkup package',
          price: 2999,
        ),
        const LabTest(
          name: 'Lipid Profile',
          description: 'Cholesterol and triglycerides test',
          price: 899,
        ),
        const LabTest(
          name: 'Urine Routine',
          description: 'Basic urine analysis',
          price: 199,
        ),
      ];
      _loading = false;
    });
    // After data is set, start the entrance animations
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Build each test card; reused for both loading (placeholder data) and real data
  Widget _buildTestCard(LabTest test, int index) {
    // If still loading, we apply skeleton text via Skeletonizer automatically.
    // We only wrap in Slide/Fade if data is loaded.
    Widget card = Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              test.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              test.description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${test.price}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle booking action
                  },
                  child: const Text('Book Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Wrap in entrance animations if not loading
    if (!_loading) {
      card = SlideTransition(
        position: _slideAnimations[index.clamp(0, _slideAnimations.length - 1)],
        child: FadeTransition(
          opacity: _fadeAnimations[index.clamp(0, _fadeAnimations.length - 1)],
          child: card,
        ),
      );
    }
    return card;
  }

  @override
  Widget build(BuildContext context) {
    // Determine content width for responsiveness
    return Scaffold(
      appBar: AppBar(title: const Text('Lab Tests at Home')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Center content on wide screens
          Widget content = _buildContent();
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

  // Builds the main scrollable content (skeleton or real)
  Widget _buildContent() {
    // Use a list of placeholder items if loading, to shape the skeleton
    final displayTests = _loading
        ? List<LabTest>.filled(
            5,
            const LabTest(
              name: 'Test Name',
              description: 'Test description',
              price: 0,
            ),
          )
        : _tests;

    return Skeletonizer(
      enabled: _loading,
      enableSwitchAnimation: true, // Fade between skeleton and real UI
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spacing/padding if needed
            const SizedBox(height: 16),
            // Category chips (horizontal scroll)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FilterChip(
                    label: const Text('All Tests'),
                    onSelected: (_) {},
                    selected: true,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Popular'),
                    onSelected: (_) {},
                    selected: false,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Full Body'),
                    onSelected: (_) {},
                    selected: false,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Blood'),
                    onSelected: (_) {},
                    selected: false,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Urine'),
                    onSelected: (_) {},
                    selected: false,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Special'),
                    onSelected: (_) {},
                    selected: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Banner card
            Card(
              color: Colors.blue.shade50,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(Icons.local_shipping, color: Colors.blue),
                title: const Text('Free Sample Collection'),
                subtitle: const Text(
                  'We charge only the actual price of tests',
                ),
              ),
            ),

            // Test cards list
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: displayTests.length,
              itemBuilder: (context, index) {
                // Each card (skeleton or real) with possible animation
                return _buildTestCard(displayTests[index], index);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
