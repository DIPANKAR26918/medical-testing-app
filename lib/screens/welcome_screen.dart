import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _getStarted(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    Navigator.of(
      context,
    ).pushReplacementNamed(user != null ? '/home' : '/language');
  }

  void _logIn(BuildContext context) {
    Navigator.of(context).pushNamed('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isShort = size.height < 720;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _WelcomeBackgroundPainter()),
            ),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width < 390 ? 24 : 32,
                  vertical: isShort ? 18 : 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: isShort ? 22 : 48),
                      const _BrandHeader(),
                      SizedBox(height: isShort ? 54 : 76),
                      const _IntroCopy(),
                      SizedBox(height: isShort ? 112 : 150),
                      _PrimaryButton(
                        label: 'Get Started',
                        onPressed: () => _getStarted(context),
                      ),
                      const SizedBox(height: 14),
                      _SecondaryButton(
                        label: 'Log In',
                        onPressed: () => _logIn(context),
                      ),
                      const SizedBox(height: 34),
                      const _PageDots(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: 122,
          height: 105,
          child: CustomPaint(painter: _LabHomeLogoPainter()),
        ),
        const SizedBox(height: 26),
        const Text(
          'TESTIFIED',
          style: TextStyle(
            color: Color(0xFF173B46),
            fontSize: 31,
            fontWeight: FontWeight.w600,
            letterSpacing: 10,
            height: 1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        const Text(
          'Tests you need, care you trust.',
          style: TextStyle(
            color: Color(0xFF10242B),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 220,
          height: 28,
          child: CustomPaint(painter: _DividerCharmPainter()),
        ),
      ],
    );
  }
}

class _IntroCopy extends StatelessWidget {
  const _IntroCopy();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Lab tests at home.\nCare beyond the clinic.',
          style: TextStyle(
            color: Color(0xFF0F2630),
            fontSize: 21,
            fontWeight: FontWeight.w700,
            height: 1.28,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 14),
        Text(
          'Affordable lab testing at home and\neasy scheduling for advanced scans\nat top labs.',
          style: TextStyle(
            color: Color(0xFF10242B),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.42,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF04727B),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF075C67),
          side: const BorderSide(color: Color(0xFF075C67), width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Dot(active: true),
        const SizedBox(width: 18),
        const _Dot(active: false),
        const SizedBox(width: 18),
        const _Dot(active: false),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFF04727B) : const Color(0xFFBDD8D7),
      ),
    );
  }
}

class _WelcomeBackgroundPainter extends CustomPainter {
  const _WelcomeBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()..color = const Color(0xFFE2FAF8);
    final wave = Path()
      ..moveTo(0, size.height * 0.50)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.66,
        size.width * 0.34,
        size.height * 0.75,
        size.width * 0.58,
        size.height * 0.79,
      )
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.82,
        size.width * 0.89,
        size.height * 0.84,
        size.width,
        size.height * 0.88,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(wave, wavePaint);

    final iconPaint = Paint()
      ..color = const Color(0xFF88CFCB).withValues(alpha: 0.28)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawPlane(
      canvas,
      Offset(size.width * 0.12, size.height * 0.66),
      iconPaint,
    );
    _drawTube(
      canvas,
      Offset(size.width * 0.27, size.height * 0.78),
      iconPaint,
      0.72,
    );
    _drawPulseHeart(
      canvas,
      Offset(size.width * 0.63, size.height * 0.77),
      iconPaint,
    );
    _drawShield(
      canvas,
      Offset(size.width * 0.84, size.height * 0.74),
      iconPaint,
    );

    final plusPaint = Paint()
      ..color = const Color(0xFF88CFCB).withValues(alpha: 0.22)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    _drawPlus(
      canvas,
      Offset(size.width * 0.47, size.height * 0.73),
      7,
      plusPaint,
    );
    _drawPlus(
      canvas,
      Offset(size.width * 0.60, size.height * 0.75),
      6,
      plusPaint,
    );
  }

  void _drawPlane(Canvas canvas, Offset o, Paint paint) {
    final path = Path()
      ..moveTo(o.dx - 58, o.dy + 8)
      ..lineTo(o.dx + 32, o.dy - 28)
      ..quadraticBezierTo(o.dx + 44, o.dy - 33, o.dx + 50, o.dy - 20)
      ..quadraticBezierTo(o.dx + 14, o.dy - 4, o.dx - 24, o.dy + 16)
      ..lineTo(o.dx - 52, o.dy + 4)
      ..moveTo(o.dx - 4, o.dy - 14)
      ..quadraticBezierTo(o.dx + 16, o.dy + 10, o.dx + 3, o.dy + 35);
    canvas.drawPath(path, paint);
  }

  void _drawTube(Canvas canvas, Offset o, Paint paint, double scale) {
    final rect = Rect.fromLTWH(
      o.dx - 18 * scale,
      o.dy - 34 * scale,
      36 * scale,
      74 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(15 * scale)),
      paint,
    );
    canvas.drawLine(
      Offset(o.dx - 18 * scale, o.dy - 16 * scale),
      Offset(o.dx + 18 * scale, o.dy - 16 * scale),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          o.dx - 22 * scale,
          o.dy - 45 * scale,
          44 * scale,
          10 * scale,
        ),
        Radius.circular(4 * scale),
      ),
      paint,
    );
    canvas.drawCircle(Offset(o.dx, o.dy - 58 * scale), 7 * scale, paint);
  }

  void _drawPulseHeart(Canvas canvas, Offset o, Paint paint) {
    final heart = Path()
      ..moveTo(o.dx, o.dy + 42)
      ..cubicTo(o.dx - 62, o.dy + 2, o.dx - 33, o.dy - 33, o.dx, o.dy - 13)
      ..cubicTo(o.dx + 33, o.dy - 33, o.dx + 62, o.dy + 2, o.dx, o.dy + 42);
    canvas.drawPath(heart, paint);
    final pulse = Path()
      ..moveTo(o.dx - 54, o.dy + 6)
      ..lineTo(o.dx - 22, o.dy + 6)
      ..lineTo(o.dx - 12, o.dy + 25)
      ..lineTo(o.dx + 2, o.dy - 12)
      ..lineTo(o.dx + 16, o.dy + 10)
      ..lineTo(o.dx + 56, o.dy + 10);
    canvas.drawPath(pulse, paint);
  }

  void _drawShield(Canvas canvas, Offset o, Paint paint) {
    final shield = Path()
      ..moveTo(o.dx, o.dy - 36)
      ..lineTo(o.dx + 32, o.dy - 24)
      ..lineTo(o.dx + 29, o.dy + 15)
      ..quadraticBezierTo(o.dx + 23, o.dy + 42, o.dx, o.dy + 54)
      ..quadraticBezierTo(o.dx - 23, o.dy + 42, o.dx - 29, o.dy + 15)
      ..lineTo(o.dx - 32, o.dy - 24)
      ..close();
    canvas.drawPath(shield, paint);
    final check = Path()
      ..moveTo(o.dx - 14, o.dy + 4)
      ..lineTo(o.dx - 3, o.dy + 16)
      ..lineTo(o.dx + 17, o.dy - 9);
    canvas.drawPath(check, paint..strokeWidth = 5);
    paint.strokeWidth = 3;
  }

  void _drawPlus(Canvas canvas, Offset o, double radius, Paint paint) {
    canvas.drawLine(
      Offset(o.dx - radius, o.dy),
      Offset(o.dx + radius, o.dy),
      paint,
    );
    canvas.drawLine(
      Offset(o.dx, o.dy - radius),
      Offset(o.dx, o.dy + radius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LabHomeLogoPainter extends CustomPainter {
  const _LabHomeLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF168883)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final roof = Path()
      ..moveTo(cx - 47, 47)
      ..lineTo(cx - 6, 7)
      ..moveTo(cx + 6, 7)
      ..lineTo(cx + 47, 47);
    canvas.drawPath(roof, paint);

    canvas.drawLine(Offset(cx - 16, 36), Offset(cx - 16, 92), paint);
    canvas.drawLine(Offset(cx + 16, 36), Offset(cx + 16, 92), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 15, 46, 30, 52),
        const Radius.circular(14),
      ),
      paint,
    );
    canvas.drawLine(Offset(cx - 9, 67), Offset(cx + 9, 67), paint);
    canvas.drawCircle(Offset(cx, 22), 6, paint);
    canvas.drawCircle(Offset(cx, 57), 2.4, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;

    final leftWall = Path()
      ..moveTo(cx - 37, 52)
      ..lineTo(cx - 37, 91)
      ..quadraticBezierTo(cx - 37, 99, cx - 29, 99)
      ..lineTo(cx - 20, 99);
    canvas.drawPath(leftWall, paint);

    final rightWall = Path()
      ..moveTo(cx + 37, 52)
      ..lineTo(cx + 37, 91)
      ..quadraticBezierTo(cx + 37, 99, cx + 29, 99)
      ..lineTo(cx + 20, 99);
    canvas.drawPath(rightWall, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DividerCharmPainter extends CustomPainter {
  const _DividerCharmPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFBFDCD9)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final tealPaint = Paint()
      ..color = const Color(0xFF8ABFBC)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2 + 1);
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(center.dx - 28, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx + 28, center.dy),
      Offset(size.width - 35, center.dy),
      linePaint,
    );

    final heart = Path()
      ..moveTo(center.dx, center.dy + 10)
      ..cubicTo(
        center.dx - 26,
        center.dy - 8,
        center.dx - 11,
        center.dy - 20,
        center.dx,
        center.dy - 8,
      )
      ..cubicTo(
        center.dx + 11,
        center.dy - 20,
        center.dx + 26,
        center.dy - 8,
        center.dx,
        center.dy + 10,
      );
    canvas.drawPath(heart, tealPaint);

    final sparklePaint = Paint()
      ..color = const Color(0xFF168883)
      ..style = PaintingStyle.fill;
    final sparkleCenter = Offset(size.width - 16, center.dy - 8);
    final sparkle = Path()
      ..moveTo(sparkleCenter.dx, sparkleCenter.dy - 9)
      ..quadraticBezierTo(
        sparkleCenter.dx + 3,
        sparkleCenter.dy - 2,
        sparkleCenter.dx + 10,
        sparkleCenter.dy,
      )
      ..quadraticBezierTo(
        sparkleCenter.dx + 3,
        sparkleCenter.dy + 2,
        sparkleCenter.dx,
        sparkleCenter.dy + 21,
      )
      ..quadraticBezierTo(
        sparkleCenter.dx - 3,
        sparkleCenter.dy + 2,
        sparkleCenter.dx - 10,
        sparkleCenter.dy,
      )
      ..quadraticBezierTo(
        sparkleCenter.dx - 3,
        sparkleCenter.dy - 2,
        sparkleCenter.dx,
        sparkleCenter.dy - 9,
      );
    canvas.drawPath(sparkle, sparklePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
