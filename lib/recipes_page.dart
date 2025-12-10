import 'package:flutter/material.dart';
import 'recipe_model.dart';
import 'firestore_service.dart';
import 'cook_mode_screen.dart';

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
  List<String> _selectedTags = [];
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
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        backgroundColor: const Color(0xFF8B4513),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search recipes...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() => _applyFilters()),
                  ),
                ),

                // Category dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
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
                ),

                const SizedBox(height: 16),

                // Tags section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by tags:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
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
                            selectedColor: const Color(
                              0xFF8B4513,
                            ).withOpacity(0.3),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Results
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
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: _filteredRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = _filteredRecipes[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CookModeScreen(recipe: recipe),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(recipe.coverImageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.8),
                                      ],
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  alignment: Alignment.bottomLeft,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        recipe.category,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
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
