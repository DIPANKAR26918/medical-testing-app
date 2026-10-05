import 'package:flutter/material.dart';
import 'home_constants.dart';

class HowItWorksStrip extends StatelessWidget {
  const HowItWorksStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: HomeColors.surfaceTeal,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: HomeColors.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'How It Works',
            header: true,
            child: Text(
              'How It Works',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: HomeColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildStep(
                  '1',
                  'Book Online',
                  'Choose your test',
                ),
              ),
              _buildArrow(),
              Expanded(
                child: _buildStep(
                  '2',
                  'We Visit',
                  'Sample at your door',
                ),
              ),
              _buildArrow(),
              Expanded(
                child: _buildStep(
                  '3',
                  'Get Report',
                  'Results in 24-48hrs',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String desc) {
    return Semantics(
      label: 'Step $number: $title. $desc',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HomeColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: HomeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: HomeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrow() {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 16,
        color: HomeColors.textMuted,
        semanticLabel: 'Arrow separator',
      ),
    );
  }
}
