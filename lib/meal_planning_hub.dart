import 'package:flutter/material.dart';
import 'recipe_model.dart';
import 'firestore_service.dart';
import 'unified_cook_mode.dart';
import 'shopping_cart_screen.dart';
import 'macinna_fab.dart';

// --- Serving Multiplier Constants ---
const List<double> _kServingMultipliers = [
  0.125,
  0.25,
  0.5,
  1.0,
  1.5,
  2.0,
  3.0,
  4.0,
];

String _multiplierToLabel(double multiplier) {
  if (multiplier == 0.125) return '⅛×';
  if (multiplier == 0.25) return '¼×';
  if (multiplier == 0.5) return '½×';
  if (multiplier == 1.0) return '1×';
  if (multiplier == 1.5) return '1½×';
  if (multiplier == 2.0) return '2×';
  if (multiplier == 3.0) return '3×';
  if (multiplier == 4.0) return '4×';
  return '${multiplier}×';
}

const List<Color> _kRecipeColors = [
  Color(0xFFE53935), // Red
  Color(0xFF1E88E5), // Blue
  Color(0xFF43A047), // Green
  Color(0xFFFB8C00), // Orange
  Color(0xFF8E24AA), // Purple
  Color(0xFF00ACC1), // Teal
  Color(0xFFD81B60), // Pink
  Color(0xFF6D4C41), // Brown
];

class MealPlanningHub extends StatefulWidget {
  const MealPlanningHub({super.key});

  @override
  State<MealPlanningHub> createState() => _MealPlanningHubState();
}

class _MealPlanningHubState extends State<MealPlanningHub> {
  final _firestoreService = FirestoreService();
  List<Recipe> _allRecipes = [];
  final Map<String, double> _selectedRecipeMultipliers =
      {}; // recipeId -> multiplier
  final Map<String, Color> _recipeColors = {};
  final List<PlannedStep> _stepSequence = []; // recipeId -> multiplier
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    _allRecipes = await _firestoreService.loadRecipes();
    setState(() => _isLoading = false);
  }

  void _assignDefaultColor(String recipeId) {
    if (!_recipeColors.containsKey(recipeId)) {
      final usedColors = _recipeColors.values.toSet();
      final availableColor = _kRecipeColors.firstWhere(
        (c) => !usedColors.contains(c),
        orElse: () =>
            _kRecipeColors[_recipeColors.length % _kRecipeColors.length],
      );
      _recipeColors[recipeId] = availableColor;
    }
  }

  void _rebuildStepSequence() {
    _stepSequence.clear();

    final recipes = _selectedRecipeMultipliers.keys
        .map((id) => _allRecipes.firstWhere((r) => r.id == id))
        .toList();

    if (recipes.isEmpty) return;

    // Find max steps across all recipes
    final maxSteps = recipes
        .map((r) => r.steps.length)
        .reduce((a, b) => a > b ? a : b);

    // Interleave: 1A, 1B, 2A, 2B, etc.
    for (var stepIdx = 0; stepIdx < maxSteps; stepIdx++) {
      for (var recipe in recipes) {
        if (stepIdx < recipe.steps.length) {
          _stepSequence.add(
            PlannedStep(recipeId: recipe.id, stepIndex: stepIdx),
          );
        }
      }
    }
  }

  void _pickColor(String recipeId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pick Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _kRecipeColors.map((color) {
            final isSelected = _recipeColors[recipeId] == color;
            return GestureDetector(
              onTap: () {
                setState(() => _recipeColors[recipeId] = color);
                Navigator.pop(context);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [BoxShadow(color: color, blurRadius: 8)]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _openStepSequencer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black54,
      pageBuilder: (context, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: double.infinity,
              color: const Color(0xFFF5E6D3),
              child: _StepSequencerPanel(
                recipes: _selectedRecipeMultipliers.keys
                    .map((id) => _allRecipes.firstWhere((r) => r.id == id))
                    .toList(),
                recipeColors: _recipeColors,
                stepSequence: _stepSequence,
                onSave: (newSequence) {
                  setState(() {
                    _stepSequence.clear();
                    _stepSequence.addAll(newSequence);
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  void _addRecipes() async {
    // Filter out already-selected recipes
    final availableRecipes = _allRecipes
        .where((r) => !_selectedRecipeMultipliers.containsKey(r.id))
        .toList();

    if (availableRecipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All recipes already added!')),
      );
      return;
    }

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (_) => _RecipePickerDialog(allRecipes: availableRecipes),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        for (var recipeId in selected) {
          _selectedRecipeMultipliers[recipeId] = 1.0;
          _assignDefaultColor(recipeId);
        }
        _rebuildStepSequence();
      });
    }
  }

  void _removeRecipe(String recipeId) {
    setState(() {
      _selectedRecipeMultipliers.remove(recipeId);
      _recipeColors.remove(recipeId);
      _rebuildStepSequence();
    });
  }

  void _updateMultiplier(String recipeId, double multiplier) {
    setState(() => _selectedRecipeMultipliers[recipeId] = multiplier);
  }

  int _calculateFinalServings(Recipe recipe, double multiplier) {
    return (recipe.servings * multiplier).round();
  }

  int get _totalShoppingItems {
    final Set<String> allIngredientNames = {};
    for (var recipeId in _selectedRecipeMultipliers.keys) {
      final recipe = _allRecipes.firstWhere((r) => r.id == recipeId);
      for (var ing in recipe.ingredients) {
        final name = ing.split('|').first.trim();
        allIngredientNames.add(name.toLowerCase());
      }
    }
    return allIngredientNames.length;
  }

  void _startCooking() {
    final recipes = _selectedRecipeMultipliers.keys
        .map((id) => _allRecipes.firstWhere((r) => r.id == id))
        .toList();

    final servingsOverrides = _selectedRecipeMultipliers.map((id, multiplier) {
      final recipe = _allRecipes.firstWhere((r) => r.id == id);
      return MapEntry(id, _calculateFinalServings(recipe, multiplier));
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedCookMode(
          recipes: recipes,
          servingsOverrides: servingsOverrides,
          recipeColors: _recipeColors,
          stepSequence: _stepSequence,
        ),
      ),
    );
  }

  void _viewShoppingCart() {
    final recipes = _selectedRecipeMultipliers.keys
        .map((id) => _allRecipes.firstWhere((r) => r.id == id))
        .toList();

    final servingsOverrides = _selectedRecipeMultipliers.map((id, multiplier) {
      final recipe = _allRecipes.firstWhere((r) => r.id == id);
      return MapEntry(id, _calculateFinalServings(recipe, multiplier));
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingCartScreen(
          recipes: recipes,
          servingsOverrides: servingsOverrides,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedRecipes = _selectedRecipeMultipliers.keys
        .map(
          (id) => _allRecipes.firstWhere(
            (r) => r.id == id,
            orElse: () => _allRecipes.first,
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFD4B896),
      body: Stack(
        children: [
          // Macy background
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/backgrounds/bgCreateRecipe.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(
                  8,
                  MediaQuery.of(context).padding.top + 8,
                  16,
                  16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF8B4513),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Meal Planning',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Shopping cart icon with badge
                    if (_selectedRecipeMultipliers.isNotEmpty)
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: _viewShoppingCart,
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_totalShoppingItems',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _selectedRecipeMultipliers.isEmpty
                    ? _buildEmptyState()
                    : _buildRecipeList(selectedRecipes),
              ),

              // Bottom action bar
              if (_selectedRecipeMultipliers.isNotEmpty)
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    12 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (_selectedRecipeMultipliers.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton.icon(
                            onPressed: _openStepSequencer,
                            icon: const Icon(Icons.reorder),
                            label: const Text('Order'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8B4513),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),

                      OutlinedButton.icon(
                        onPressed: _addRecipes,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B4513),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startCooking,
                          icon: const Icon(Icons.restaurant),
                          label: Text(
                            'Start Cooking (${_selectedRecipeMultipliers.length})',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: _selectedRecipeMultipliers.isEmpty
          ? null
          : const MacinnaFAB(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.brown.shade300),
            const SizedBox(height: 24),
            const Text(
              'Plan Your Meal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add recipes to plan a full meal.\nAdjust servings and get a combined shopping list!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.brown.shade600),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addRecipes,
              icon: const Icon(Icons.add),
              label: const Text('Add Recipes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeList(List<Recipe> recipes) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      onReorder: (oldIndex, newIndex) {
        // Reorder logic
        if (newIndex > oldIndex) newIndex--;
        final entries = _selectedRecipeMultipliers.entries.toList();
        final item = entries.removeAt(oldIndex);
        entries.insert(newIndex, item);
        setState(() {
          _selectedRecipeMultipliers.clear();
          for (var entry in entries) {
            _selectedRecipeMultipliers[entry.key] = entry.value;
          }
        });
      },
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        final multiplier = _selectedRecipeMultipliers[recipe.id] ?? 1.0;
        final finalServings = _calculateFinalServings(recipe, multiplier);

        return _RecipeCard(
          key: ValueKey(recipe.id),
          recipe: recipe,
          multiplier: multiplier,
          finalServings: finalServings,
          color: _recipeColors[recipe.id] ?? _kRecipeColors[0],
          onColorTap: () => _pickColor(recipe.id),
          onMultiplierChanged: (m) => _updateMultiplier(recipe.id, m),
          onRemove: () => _removeRecipe(recipe.id),
          index: index,
        );
      },
    );
  }
}

// --- Recipe Card Widget ---
class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final double multiplier;
  final int finalServings;
  final Color color;
  final VoidCallback onColorTap;
  final ValueChanged<double> onMultiplierChanged;
  final VoidCallback onRemove;
  final int index;

  const _RecipeCard({
    super.key,
    required this.recipe,
    required this.multiplier,
    required this.finalServings,
    required this.color,
    required this.onColorTap,
    required this.onMultiplierChanged,
    required this.onRemove,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xE6FFF8E7),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            // Color dot + Drag handle
            Column(
              children: [
                GestureDetector(
                  onTap: onColorTap,
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.15),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // Recipe thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                recipe.coverImageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.brown.shade100,
                  child: const Icon(Icons.restaurant, color: Colors.brown),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Recipe info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.timer_outlined,
                        label:
                            '${recipe.prepTimeMinutes + recipe.cookTimeMinutes}m',
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.list_alt,
                        label: '${recipe.steps.length} steps',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Servings multiplier row
                  Row(
                    children: [
                      const Text(
                        'Servings: ',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<double>(
                          value: multiplier,
                          underline: const SizedBox(),
                          isDense: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF8B4513),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF8B4513),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          onChanged: (v) {
                            if (v != null) onMultiplierChanged(v);
                          },
                          items: _kServingMultipliers.map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text(_multiplierToLabel(m)),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '→ $finalServings',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      Text(
                        ' (was ${recipe.servings})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onRemove,
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }
}

// --- Small stat chip ---
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.brown.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.brown),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.brown),
          ),
        ],
      ),
    );
  }
}

// --- Recipe Picker Dialog ---
class _RecipePickerDialog extends StatefulWidget {
  final List<Recipe> allRecipes;

  const _RecipePickerDialog({required this.allRecipes});

  @override
  State<_RecipePickerDialog> createState() => _RecipePickerDialogState();
}

class _RecipePickerDialogState extends State<_RecipePickerDialog> {
  final Set<String> _selected = {};
  String _searchQuery = '';

  List<Recipe> get _filteredRecipes {
    if (_searchQuery.isEmpty) return widget.allRecipes;
    return widget.allRecipes
        .where((r) => r.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Select Recipes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 12),

            // Recipe list
            Expanded(
              child: _filteredRecipes.isEmpty
                  ? const Center(child: Text('No recipes found'))
                  : ListView.builder(
                      itemCount: _filteredRecipes.length,
                      itemBuilder: (_, i) {
                        final recipe = _filteredRecipes[i];
                        final isSelected = _selected.contains(recipe.id);

                        return Card(
                          color: isSelected
                              ? const Color(0xFF8B4513).withOpacity(0.1)
                              : null,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                recipe.coverImageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.brown.shade100,
                                  child: const Icon(Icons.restaurant),
                                ),
                              ),
                            ),
                            title: Text(
                              recipe.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${recipe.steps.length} steps • ${recipe.servings} servings',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF8B4513),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selected.add(recipe.id);
                                  } else {
                                    _selected.remove(recipe.id);
                                  }
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selected.remove(recipe.id);
                                } else {
                                  _selected.add(recipe.id);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, _selected.toList()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Add ${_selected.length} Recipe${_selected.length == 1 ? '' : 's'}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepSequencerPanel extends StatefulWidget {
  final List<Recipe> recipes;
  final Map<String, Color> recipeColors;
  final List<PlannedStep> stepSequence;
  final Function(List<PlannedStep>) onSave;

  const _StepSequencerPanel({
    required this.recipes,
    required this.recipeColors,
    required this.stepSequence,
    required this.onSave,
  });

  @override
  State<_StepSequencerPanel> createState() => _StepSequencerPanelState();
}

class _StepSequencerPanelState extends State<_StepSequencerPanel> {
  late List<PlannedStep> _localSequence;

  @override
  void initState() {
    super.initState();
    _localSequence = List.from(widget.stepSequence);
  }

  void _resetToDefault() {
    setState(() {
      _localSequence.clear();
      final maxSteps = widget.recipes
          .map((r) => r.steps.length)
          .reduce((a, b) => a > b ? a : b);
      for (var stepIdx = 0; stepIdx < maxSteps; stepIdx++) {
        for (var recipe in widget.recipes) {
          if (stepIdx < recipe.steps.length) {
            _localSequence.add(
              PlannedStep(recipeId: recipe.id, stepIndex: stepIdx),
            );
          }
        }
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    if (totalSeconds >= 3600) {
      final h = totalSeconds ~/ 3600;
      final m = (totalSeconds % 3600) ~/ 60;
      return '${h}h${m > 0 ? ' ${m}m' : ''}';
    } else if (totalSeconds >= 60) {
      return '${totalSeconds ~/ 60}m';
    }
    return '${totalSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 12,
            8,
            12,
          ),
          color: const Color(0xFF8B4513),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Cook Order',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: _resetToDefault,
                child: const Text(
                  'Reset',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: () => widget.onSave(_localSequence),
              ),
            ],
          ),
        ),

        // Legend
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 12,
            children: widget.recipes.map((r) {
              final color = widget.recipeColors[r.id] ?? Colors.grey;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    r.name.length > 15 ? '${r.name.substring(0, 15)}…' : r.name,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ),

        const Divider(height: 1),

        // Step list
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _localSequence.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _localSequence.removeAt(oldIndex);
                _localSequence.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final planned = _localSequence[index];
              final recipe = widget.recipes.firstWhere(
                (r) => r.id == planned.recipeId,
              );
              final step = recipe.steps[planned.stepIndex];
              final color = widget.recipeColors[recipe.id] ?? Colors.grey;
              final totalTimerSeconds = step.timers.fold<int>(
                0,
                (sum, t) => sum + t.durationSeconds,
              );

              return Card(
                key: ValueKey('${planned.recipeId}_${planned.stepIndex}'),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: color.withOpacity(0.5), width: 2),
                ),
                child: ListTile(
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle, color: Colors.grey),
                  ),
                  title: Text(
                    step.title.isEmpty
                        ? 'Step ${planned.stepIndex + 1}'
                        : step.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Step ${planned.stepIndex + 1} • ${recipe.name}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  trailing: totalTimerSeconds > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer,
                                size: 14,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimer(totalTimerSeconds),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PlannedStep {
  final String recipeId;
  final int stepIndex;

  PlannedStep({required this.recipeId, required this.stepIndex});
}
