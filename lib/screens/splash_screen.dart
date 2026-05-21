import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/index.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200), // Speed of expansion
    );

    // This handles your "0 to X,Y" expansion logic
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ), // Slight bounce at end
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward().whenComplete(() {
      // Hold the finished, crisp logo for 1 second before moving on
      Future.delayed(const Duration(milliseconds: 1000), _navigateNext);
    });
  }

  void _navigateNext() {
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    final nextRoute = user != null ? '/home' : '/language';
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        // This keeps everything mathematically centered
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: Alignment
                .center, // This ensures it expands outward from the middle
            child: SizedBox(
              width:
                  MediaQuery.of(context).size.width *
                  0.75, // Controls final size
              child: Image.asset(
                'assets/images/Testified_image.png',
                fit: BoxFit.contain, // Keeps the ratio constant while expanding
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ParticleModel {
  final double targetX;
  final double targetY;
  final Color color;

  ParticleModel({
    required this.targetX,
    required this.targetY,
    required this.color,
  });
}

class PixelPerfectPainter extends CustomPainter {
  final List<ParticleModel> particles;
  final double progress;

  PixelPerfectPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    for (var p in particles) {
      // Animation curve for the "burst"
      double t = Curves.easeOutExpo.transform(progress);

      // Calculate movement from center to exact pixel position
      double curX = centerX + (p.targetX - centerX) * t;
      double curY = centerY + (p.targetY - centerY) * t;

      paint.color = p.color.withValues(alpha: progress.clamp(0.0, 1.0));

      // Draw the exact pixel
      canvas.drawRect(Rect.fromLTWH(curX, curY, 2.0, 2.0), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
