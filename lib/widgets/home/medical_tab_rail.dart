import 'package:flutter/material.dart';

import 'home_constants.dart';

class MedicalTabRail extends StatelessWidget {
  const MedicalTabRail({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  static const _tabs = [
    _TabData('For You', Icons.home_rounded),
    _TabData('Lab Tests', Icons.biotech_rounded),
    _TabData('Packages', Icons.inventory_2_rounded),
    _TabData('Upload Rx', Icons.note_alt_rounded),
    _TabData('Reports', Icons.fact_check_rounded),
    _TabData('Scans', Icons.monitor_heart_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 70,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _tabs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 18),
          itemBuilder: (_, index) {
            final tab = _tabs[index];
            final isSelected = selectedIndex == index;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onTabChanged(index),
              child: SizedBox(
                width: 76,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      tab.icon,
                      size: 29,
                      color: isSelected
                          ? HomeColors.deepBlue
                          : const Color(0xFF364152),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tab.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w600,
                        color: isSelected
                            ? HomeColors.deepBlue
                            : const Color(0xFF364152),
                      ),
                    ),
                    const SizedBox(height: 7),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: isSelected ? 58 : 0,
                      height: 5,
                      decoration: BoxDecoration(
                        color: HomeColors.blueAccent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TabData {
  const _TabData(this.label, this.icon);
  final String label;
  final IconData icon;
}
