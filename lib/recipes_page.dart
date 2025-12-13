import 'package:flutter/material.dart';
import 'recipe_model.dart';
import 'firestore_service.dart';
import 'cook_mode_screen.dart';
import 'recipe_detail_screen.dart'; // Ensure you have this file for detailed view

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();

  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  String? _selectedCategory;
  final List<String> _selectedTags = [];
  bool _isLoading = true;

  // Retaining original categories and tags
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
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    // Assuming FirestoreService.loadRecipes() fetches List<Recipe>
    _allRecipes = await _firestoreService.loadRecipes();
    _applyFilters();
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    _filteredRecipes = _allRecipes.where((recipe) {
      // Search filter
      final searchTerm = _searchController.text.toLowerCase();
      final matchesSearch =
          searchTerm.isEmpty || recipe.name.toLowerCase().contains(searchTerm);

      // Category filter
      final matchesCategory =
          _selectedCategory == null ||
          _selectedCategory == 'All' ||
          recipe.category == _selectedCategory;

      // Tags filter
      final matchesTags =
          _selectedTags.isEmpty ||
          _selectedTags.any((tag) => recipe.tags.contains(tag));

      return matchesSearch && matchesCategory && matchesTags;
    }).toList();
  }

  // --- NEW: FILTER MODAL FUNCTION ---
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        // Use StatefulBuilder to manage the filter state visually inside the modal
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Filter Recipes',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),

                  // Category Dropdown (Retains look and feel)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: const TextStyle(color: Color(0xFF8B4513)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8B4513)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B4513),
                          width: 2,
                        ),
                      ),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (value) {
                      modalSetState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Tags section
                  const Text(
                    'Filter by tags:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (selected) {
                              modalSetState(() {
                                if (selected) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                            selectedColor: const Color(
                              0xFF8B4513,
                            ).withOpacity(0.3),
                            checkmarkColor: const Color(0xFF8B4513),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF8B4513)
                                  : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            backgroundColor: Colors.white,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      // Apply filters to the main page state once the modal is closed
    ).whenComplete(() => setState(() => _applyFilters()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Default white background
      appBar: AppBar(
        title: const Text(
          'Recipes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8B4513), // Retaining brown color
        actions: [
          // Filter Icon Button
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: _showFilterModal, // Calls the filter modal
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Modernized Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search recipes...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF8B4513),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100], // Light grey fill
                      // Highly rounded corners for a soft look
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                      ),
                    ),
                    onChanged: (_) => setState(() => _applyFilters()),
                  ),
                ),

                const SizedBox(height: 8),

                // Results Grid
                Expanded(
                  child: _filteredRecipes.isEmpty
                      ? const Center(
                          child: Text(
                            'No recipes found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75, // Taller cards
                              ),
                          itemCount: _filteredRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = _filteredRecipes[index];

                            // --- REVISED RECIPE CARD UI ---
                            return GestureDetector(
                              onTap: () {
                                // Corrected navigation to detailed info screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RecipeDetailScreen(recipe: recipe),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 4, // Floating effect
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    16,
                                  ), // Softer corners
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            recipe.coverImageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                      ),
                                                    ),
                                          ),
                                          // Softened Gradient overlay (only on bottom)
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.5),
                                                ],
                                                stops: const [
                                                  0.7,
                                                  1.0,
                                                ], // Start gradient lower
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Text moved outside the image/stack area
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            recipe.name,
                                            style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w700, // Bold title
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            recipe.category,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
