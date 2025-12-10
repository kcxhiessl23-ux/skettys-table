import 'package:flutter/material.dart';
import 'media_model.dart';
import 'firestore_service.dart';

class MediaSearchOverlay extends StatefulWidget {
  const MediaSearchOverlay({super.key});

  @override
  State<MediaSearchOverlay> createState() => _MediaSearchOverlayState();
}

class _MediaSearchOverlayState extends State<MediaSearchOverlay> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();

  List<MediaItem> _allMedia = [];
  List<MediaItem> _filteredMedia = [];
  String? _selectedCategory;
  List<String> _selectedTags = [];
  String _mediaType = 'all'; // 'all', 'video', 'photo'
  bool _isLoading = true;

  final List<String> _categories = [
    'All',
    'Pasta',
    'Dinner',
    'Dessert',
    'Breakfast',
    'Soup',
    'Salad',
    'Appetizer',
    'Main Course',
    'Side Dish',
    'Snack',
  ];

  final List<String> _tags = [
    'Italian',
    'Quick',
    'Heavy',
    'Light',
    'Party',
    'Red Sauce',
    'White Sauce',
    'Vegetarian',
    'Spicy',
    'Mild',
  ];

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);
    _allMedia = await _firestoreService.loadAllMedia();
    _applyFilters();
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    _filteredMedia = _allMedia.where((media) {
      final searchTerm = _searchController.text.toLowerCase();
      final matchesSearch =
          searchTerm.isEmpty || media.name.toLowerCase().contains(searchTerm);

      final matchesType = _mediaType == 'all' || media.type == _mediaType;

      final matchesCategory =
          _selectedCategory == null ||
          _selectedCategory == 'All' ||
          media.tags.contains(_selectedCategory);

      final matchesTags =
          _selectedTags.isEmpty ||
          _selectedTags.any((tag) => media.tags.contains(tag));

      return matchesSearch && matchesType && matchesCategory && matchesTags;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Search Media',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() => _applyFilters()),
            ),
            const SizedBox(height: 12),

            // Type filter
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _mediaType == 'all',
                    onSelected: (_) => setState(() {
                      _mediaType = 'all';
                      _applyFilters();
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Videos'),
                    selected: _mediaType == 'video',
                    onSelected: (_) => setState(() {
                      _mediaType = 'video';
                      _applyFilters();
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Photos'),
                    selected: _mediaType == 'photo',
                    onSelected: (_) => setState(() {
                      _mediaType = 'photo';
                      _applyFilters();
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _applyFilters();
                });
              },
            ),
            const SizedBox(height: 12),

            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                      _applyFilters();
                    });
                  },
                  selectedColor: const Color(0xFF8B4513).withOpacity(0.3),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Results
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredMedia.isEmpty
                  ? const Center(child: Text('No media found'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                      itemCount: _filteredMedia.length,
                      itemBuilder: (context, index) {
                        final media = _filteredMedia[index];
                        return GestureDetector(
                          onTap: () => Navigator.pop(context, media),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(media.url, fit: BoxFit.cover),
                              if (media.type == 'video')
                                const Center(
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
