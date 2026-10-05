import 'package:flutter/material.dart';
import 'home_constants.dart';

class TrustSignalsStrip extends StatelessWidget {
  const TrustSignalsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: HomeColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _buildMetric(
              Icons.science_outlined,
              '10,000+',
              'Samples collected',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildMetric(
              Icons.verified_outlined,
              'NABL',
              'Accredited labs',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildMetric(
              Icons.schedule_outlined,
              '24-48hrs',
              'Report delivery',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Semantics(
      label: '$value $label',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: HomeColors.primary,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: HomeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              color: HomeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: HomeColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
    );
  }
}
