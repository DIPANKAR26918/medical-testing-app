import 'package:flutter/material.dart';
import '../location_card.dart';
import 'home_constants.dart';

class AmbientHeader extends StatelessWidget {
  const AmbientHeader({
    required this.firstName,
    required this.hour,
    super.key,
  });

  final String firstName;
  final int hour;

  String get _salutation {
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  String get _emoji {
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  String get _greeting {
    final trimmedName = firstName.trim();
    if (trimmedName.isEmpty) {
      return _salutation;
    }
    return '$_salutation, $trimmedName';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Delivery Location',
          button: true,
          child: LocationCard(),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          label: 'Greeting: $_greeting',
          child: Row(
            children: [
              Flexible(
                child: Text(
                  _greeting,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: HomeColors.textPrimary,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: 'Subtitle: Book a diagnostic test at your doorstep',
          child: Text(
            'Book a diagnostic test at your doorstep',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: HomeColors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
