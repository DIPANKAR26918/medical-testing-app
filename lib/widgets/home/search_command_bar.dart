import 'dart:async';
import 'package:flutter/material.dart';
import '../../screens/search_screen.dart';
import 'home_constants.dart';

class SearchCommandBar extends StatefulWidget {
  const SearchCommandBar({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  State<SearchCommandBar> createState() => _SearchCommandBarState();
}

class _SearchCommandBarState extends State<SearchCommandBar> {
  final List<String> _hints = [
    'Search for CBC, Thyroid, Vitamin D...',
    'Search blood tests',
    'Search diabetes screening',
    'Search full body checkup',
    'Search liver function tests',
    'Search kidney profile'
  ];

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _hints.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleTap(BuildContext context) {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SearchScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Search for medical tests',
      hint: 'Double tap to open search screen',
      button: true,
      child: Material(
        color: HomeColors.surfaceAlt,
        borderRadius: BorderRadius.circular(28.0),
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(28.0),
          splashColor: HomeColors.primary.withValues(alpha: 0.08),
          highlightColor: HomeColors.primary.withValues(alpha: 0.04),
          child: Container(
            height: 56.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  spreadRadius: -2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 22.0,
                  color: HomeColors.primary,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: ClipRRect(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 700),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        final offsetAnimation = Tween<Offset>(
                          begin: child.key == ValueKey<int>(_currentIndex)
                              ? const Offset(0.0, 0.5)
                              : const Offset(0.0, -0.5),
                          end: Offset.zero,
                        ).animate(animation);

                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: Align(
                        key: ValueKey<int>(_currentIndex),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _hints[_currentIndex],
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w400,
                            color: HomeColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
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
