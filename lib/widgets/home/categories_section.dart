import 'package:flutter/material.dart';
import '../../data/categories_data.dart';
import 'home_constants.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({
    super.key,
    this.onViewAll,
    this.onCategoryTap,
  });

  final VoidCallback? onViewAll;
  final ValueChanged<String>? onCategoryTap;

  String? _categoryImagePath(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('blood')) return 'assets/images/medical_categories/blood.webp';
    if (lower.contains('heart')) return 'assets/images/medical_categories/heart.webp';
    if (lower.contains('immunity')) return 'assets/images/medical_categories/immunity.webp';
    if (lower.contains('kidney')) return 'assets/images/medical_categories/kidney.webp';
    if (lower.contains('liver')) return 'assets/images/medical_categories/liver.webp';
    if (lower.contains('thyroid')) return 'assets/images/medical_categories/thyroid.webp';
    if (lower.contains('vitamin')) return 'assets/images/medical_categories/vitamins.webp';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Browse by Health Concern',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: HomeColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Semantics(
                  button: true,
                  label: 'View all categories',
                  child: Text(
                    'View all →',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: HomeColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(right: 20),
            itemCount: categories.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == categories.length) {
                return _buildCategoryChip(
                  name: 'View All',
                  backgroundColor: HomeColors.surfaceTeal,
                  icon: Icons.grid_view_rounded,
                  iconColor: HomeColors.primary,
                  onTap: onViewAll,
                );
              }

              final category = categories[index];
              final name = category['name'] as String;
              final imagePath = _categoryImagePath(name);

              return _buildCategoryChip(
                name: name,
                backgroundColor: category['color'] as Color? ?? HomeColors.surfaceTeal,
                icon: category['icon'] as IconData?,
                iconColor: category['iconColor'] as Color? ?? HomeColors.primary,
                imagePath: imagePath,
                onTap: onCategoryTap != null ? () => onCategoryTap!(name) : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String name,
    required Color backgroundColor,
    IconData? icon,
    Color? iconColor,
    String? imagePath,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        label: name,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                ),
                alignment: Alignment.center,
                child: imagePath != null
                    ? ClipOval(
                        child: Image.asset(
                          imagePath,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            icon ?? Icons.medical_services,
                            color: iconColor,
                            size: 28,
                          ),
                        ),
                      )
                    : Icon(
                        icon ?? Icons.medical_services,
                        color: iconColor,
                        size: 28,
                      ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: HomeColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
