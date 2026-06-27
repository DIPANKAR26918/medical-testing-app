import 'package:flutter/material.dart';

import 'home_constants.dart';

class PopularHealthGrid extends StatelessWidget {
  const PopularHealthGrid({super.key, this.onItemTap});

  final VoidCallback? onItemTap;

  static final _collections = [
    _CollectionItem(
      'Thunder deals',
      Icons.bolt_rounded,
      const Color(0xFFDC2626),
    ),
    _CollectionItem(
      'Full body',
      Icons.accessibility_new_rounded,
      const Color(0xFF0E7490),
    ),
    _CollectionItem('CBC', Icons.bloodtype_rounded, const Color(0xFFE11D48)),
    _CollectionItem(
      'Diabetes',
      Icons.water_drop_rounded,
      const Color(0xFFF97316),
    ),
    _CollectionItem(
      'Thyroid',
      Icons.local_hospital_rounded,
      const Color(0xFF4F46E5),
    ),
    _CollectionItem('Heart', Icons.favorite_rounded, const Color(0xFFDB2777)),
    _CollectionItem(
      'Vitamins',
      Icons.medication_rounded,
      const Color(0xFFCA8A04),
    ),
    _CollectionItem(
      'Home visit',
      Icons.home_work_rounded,
      const Color(0xFF16A34A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Popular health picks', style: HomeTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SizedBox(
          height: 192,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 98,
            ),
            itemCount: _collections.length,
            itemBuilder: (_, index) =>
                _CollectionTile(item: _collections[index], onTap: onItemTap),
          ),
        ),
      ],
    );
  }
}

class _CollectionItem {
  const _CollectionItem(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.item, this.onTap});

  final _CollectionItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.color, size: 28),
          ),
          const SizedBox(height: 7),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: HomeTextStyles.tileLabel,
          ),
        ],
      ),
    );
  }
}
