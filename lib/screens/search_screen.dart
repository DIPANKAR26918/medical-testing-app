import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _allItems = [
    'Complete Blood Count (CBC)',
    'Blood Sugar Test',
    'HbA1c',
    'Liver Function Test',
    'Kidney Function Test',
    'Thyroid Profile',
    'Vitamin D Test',
    'Vitamin B12 Test',
    'Lipid Profile',
    'Urine Routine Test',
    'Dengue Test',
    'Malaria Test',
    'Pregnancy Test',
    'Fever Package',
    'Diabetes Package',
    'Heart Health Package',
    'Full Body Checkup',
    'Senior Citizen Package',
  ];

  final List<String> _recentSearches = [
    'Full Body Checkup',
    'CBC Test',
    'Thyroid Profile',
  ];

  late List<String> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = _allItems;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onSearchChanged(String query) {
    final normalized = query.trim().toLowerCase();

    setState(() {
      if (normalized.isEmpty) {
        _filteredItems = _allItems;
        return;
      }

      _filteredItems = _allItems
          .where((item) => item.toLowerCase().contains(normalized))
          .toList();
    });
  }

  void _onSuggestionTap(String item) {
    _controller.text = item;
    _controller.selection = TextSelection.collapsed(offset: item.length);

    setState(() {
      if (!_recentSearches.contains(item)) {
        _recentSearches.insert(0, item);
      }

      if (_recentSearches.length > 6) {
        _recentSearches.removeRange(6, _recentSearches.length);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$item selected'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _clearSearch() {
    _controller.clear();
    setState(() => _filteredItems = _allItems);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _SearchPalette.bg,
      body: SafeArea(
        child: Column(
          children: [
            _SearchTopBar(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isSearching
                    ? _SuggestionsList(
                        key: const ValueKey('suggestions'),
                        items: _filteredItems,
                        onTap: _onSuggestionTap,
                      )
                    : _DiscoveryContent(
                        key: const ValueKey('discovery'),
                        recentSearches: _recentSearches,
                        onTap: _onSuggestionTap,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchTopBar extends StatelessWidget {
  const _SearchTopBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      color: _SearchPalette.bg,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _SearchPalette.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: _SearchPalette.border),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _SearchPalette.border),
                boxShadow: _softShadow,
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: _SearchPalette.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.search,
                      cursorColor: _SearchPalette.teal,
                      style: const TextStyle(
                        color: _SearchPalette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search tests, packages, symptoms',
                        hintStyle: TextStyle(
                          color: _SearchPalette.muted,
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                        color: _SearchPalette.slate,
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryContent extends StatelessWidget {
  const _DiscoveryContent({
    required this.recentSearches,
    required this.onTap,
    super.key,
  });

  final List<String> recentSearches;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _SectionTitle(title: 'Recent searches'),
        const SizedBox(height: 8),
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              for (var i = 0; i < recentSearches.length; i++) ...[
                _SearchTile(
                  icon: Icons.history_rounded,
                  title: recentSearches[i],
                  subtitle: 'Search again',
                  onTap: () => onTap(recentSearches[i]),
                ),
                if (i != recentSearches.length - 1)
                  const Divider(height: 1, color: _SearchPalette.border),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _SectionTitle(title: 'Popular searches'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            'Full Body Checkup',
            'CBC',
            'Thyroid',
            'Diabetes Package',
            'Vitamin D',
            'Fever Package',
            'Lipid Profile',
            'Liver Function',
          ]
              .map(
                (item) => ActionChip(
                  label: Text(item),
                  onPressed: () => onTap(item),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _SearchPalette.border),
                  labelStyle: const TextStyle(
                    color: _SearchPalette.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 22),
        const _PrescriptionHint(),
      ],
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({
    required this.items,
    required this.onTap,
    super.key,
  });

  final List<String> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySearchState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];

        return _SearchTile(
          icon: Icons.biotech_rounded,
          title: item,
          subtitle: _subtitleFor(item),
          trailing: Icons.arrow_forward_rounded,
          onTap: () => onTap(item),
        );
      },
    );
  }

  String _subtitleFor(String item) {
    if (item.toLowerCase().contains('package') ||
        item.toLowerCase().contains('checkup')) {
      return 'Health package';
    }
    return 'Lab test';
  }
}

class _SearchTile extends StatelessWidget {
  const _SearchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing = Icons.north_west_rounded,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IconData trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _SearchPalette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _SearchPalette.teal.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _SearchPalette.teal, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _SearchPalette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _SearchPalette.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(trailing, size: 18, color: _SearchPalette.slate),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrescriptionHint extends StatelessWidget {
  const _PrescriptionHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.medication_rounded, color: Color(0xFF2563EB)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Not sure what to search? Upload your prescription and we will map the tests.',
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 58, color: _SearchPalette.slate),
            SizedBox(height: 16),
            Text(
              'No matching tests found',
              style: TextStyle(
                color: _SearchPalette.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Try a test name, package, or symptom.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _SearchPalette.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _SearchPalette.ink,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SearchPalette {
  const _SearchPalette._();

  static const Color bg = Color(0xFFF7FAFC);
  static const Color ink = Color(0xFF0B2538);
  static const Color muted = Color(0xFF64748B);
  static const Color slate = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color teal = Color(0xFF087E86);
}

const List<BoxShadow> _softShadow = [
  BoxShadow(
    color: Color(0x08000000),
    blurRadius: 18,
    offset: Offset(0, 8),
  ),
];

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _SearchPalette.border),
    boxShadow: _softShadow,
  );
}
