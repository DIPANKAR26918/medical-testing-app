import 'package:flutter/material.dart';
import 'home_constants.dart';

class DualActionStrip extends StatelessWidget {
  const DualActionStrip({
    required this.onUploadPrescription,
    required this.onBookTest,
    super.key,
  });

  final VoidCallback onUploadPrescription;
  final VoidCallback onBookTest;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 310) {
          return Column(
            children: [
              _ActionTile(
                backgroundColor: HomeColors.mintSoft,
                icon: Icons.description_outlined,
                title: 'Upload Prescription',
                description: 'Have a prescription? Upload it',
                onTap: onUploadPrescription,
              ),
              const SizedBox(height: 12),
              _ActionTile(
                backgroundColor: HomeColors.primarySoft,
                icon: Icons.biotech_outlined,
                title: 'Book a Test',
                description: 'Search our test catalogue',
                onTap: onBookTest,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _ActionTile(
                backgroundColor: HomeColors.mintSoft,
                icon: Icons.description_outlined,
                title: 'Upload Prescription',
                description: 'Have a prescription? Upload it',
                onTap: onUploadPrescription,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                backgroundColor: HomeColors.primarySoft,
                icon: Icons.biotech_outlined,
                title: 'Book a Test',
                description: 'Search our test catalogue',
                onTap: onBookTest,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.backgroundColor,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final Color backgroundColor;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      hint: description,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: HomeColors.primary.withValues(alpha: 0.08),
          highlightColor: HomeColors.primary.withValues(alpha: 0.04),
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: HomeColors.primary,
                    size: 20,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: HomeColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: HomeColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: HomeColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
