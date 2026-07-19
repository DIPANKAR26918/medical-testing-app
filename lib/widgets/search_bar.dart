import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/search_screen.dart';

class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar>
    with SingleTickerProviderStateMixin {
  static const List<String> _searchHints = [
    'Search tests, packages',
    'Search CBC, Thyroid, Vitamin D',
    'Search diabetes care tests',
    'Search full body checkups',
    'Search liver and kidney tests',
  ];

  late final AnimationController _hintController;
  Timer? _hintTimer;

  int _currentHintIndex = 0;
  int _nextHintIndex = 1;

  @override
  void initState() {
    super.initState();

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );

    _startHintRotation();
  }

  void _startHintRotation() {
    _hintTimer = Timer.periodic(
      const Duration(milliseconds: 3200),
      (_) => _animateToNextHint(),
    );
  }

  Future<void> _animateToNextHint() async {
    if (!mounted || _hintController.isAnimating) return;

    await _hintController.forward();

    if (!mounted) return;

    setState(() {
      _currentHintIndex = _nextHintIndex;
      _nextHintIndex = (_nextHintIndex + 1) % _searchHints.length;
    });

    _hintController.reset();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 950),
        reverseTransitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, secondaryAnimation) {
          return const SearchScreen();
        },
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search lab tests and health packages',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(17),
          splashColor: const Color(0xFF176B5B).withValues(alpha: 0.07),
          highlightColor: const Color(0xFF176B5B).withValues(alpha: 0.035),
          child: Ink(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEFC),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xFFD8E4DE)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0B1A463E),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF2F67F5),
                  size: 25,
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: SizedBox(
                    height: 24,
                    child: ClipRect(
                      child: AnimatedBuilder(
                        animation: _hintController,
                        builder: (context, child) {
                          final progress = Curves.easeInOutCubic.transform(
                            _hintController.value,
                          );

                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Transform.translate(
                                offset: Offset(0, -24 * progress),
                                child: Opacity(
                                  opacity: 1 - progress,
                                  child: _HintText(
                                    text: _searchHints[_currentHintIndex],
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(0, 24 * (1 - progress)),
                                child: Opacity(
                                  opacity: progress,
                                  child: _HintText(
                                    text: _searchHints[_nextHintIndex],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
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

class _HintText extends StatelessWidget {
  const _HintText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF5C6C66),
          fontSize: 14.2,
          height: 1.2,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.12,
        ),
      ),
    );
  }
}
