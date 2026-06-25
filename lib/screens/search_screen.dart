import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Dummy data (replace with API data later)
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

  List<String> _filteredItems = [];

  final List<String> _recentSearches = [
    'Full Body Checkup',
    'CBC Test',
    'Thyroid Profile',
  ];

  @override
  void initState() {
    super.initState();

    _filteredItems = _allItems;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _onSuggestionTap(String item) {
    _controller.text = item;

    if (!_recentSearches.contains(item)) {
      setState(() {
        _recentSearches.insert(0, item);

        if (_recentSearches.length > 6) {
          _recentSearches.removeLast();
        }
      });
    }

    //TODO
    // Navigate to test details page
    // Navigator.push(...)
  }

  void _clearSearch() {
    _controller.clear();

    setState(() {
      _filteredItems = _allItems;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _controller.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(
              child: isSearching ? _buildSuggestions() : _buildRecentSearches(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            splashRadius: 22,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),

          Expanded(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF64748B)),

                  const SizedBox(width: 12),

                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Search tests, packages or symptoms',
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  if (_controller.text.isNotEmpty)
                    IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Searches',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 20),

          ..._recentSearches.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.history_rounded,
                color: Color(0xFF64748B),
              ),
              title: Text(item),
              onTap: () => _onSuggestionTap(item),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'Popular Searches',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                [
                      'Full Body Checkup',
                      'CBC',
                      'Thyroid',
                      'Diabetes Package',
                      'Vitamin D',
                      'Fever Package',
                    ]
                    .map(
                      (e) => ActionChip(
                        label: Text(e),
                        onPressed: () => _onSuggestionTap(e),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.search_off_rounded, size: 70, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                'No matching tests found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 12),
      itemCount: _filteredItems.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _filteredItems[index];

        return ListTile(
          leading: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
          title: Text(item),
          trailing: const Icon(Icons.north_west_rounded, size: 18),
          onTap: () => _onSuggestionTap(item),
        );
      },
    );
  }
}
