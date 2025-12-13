import 'package:flutter/material.dart';
import 'recipe_model.dart';
import 'macinna_fab.dart';

class ShoppingCartScreen extends StatefulWidget {
  final List<Recipe> recipes;
  final Map<String, int> servingsOverrides;

  const ShoppingCartScreen({
    super.key,
    required this.recipes,
    this.servingsOverrides = const {},
  });

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  final Map<String, bool> _checkedItems = {};
  // Ingredient groups will now store the final SCALED and AGGREGATED result
  final Map<String, _IngredientGroup> _groupedIngredients = {};

  @override
  void initState() {
    super.initState();
    _aggregateIngredients();
  }

  void _aggregateIngredients() {
    _groupedIngredients.clear();

    // Map to hold the final, scaled, and aggregated quantities:
    // Key: "Name|Unit" (e.g., "Flour|cup(s)") -> Value: Total Quantity (e.g., 6.0)
    final Map<String, double> aggregatedQuantities = {};

    // Map to hold the list of original recipes contributing to the aggregated item
    // Key: "Name|Unit" -> Value: List of Recipe Names
    final Map<String, Set<String>> contributingRecipes = {};

    for (var recipe in widget.recipes) {
      final servings = widget.servingsOverrides[recipe.id] ?? recipe.servings;
      final multiplier = servings / recipe.servings;

      for (var ingredient in recipe.ingredients) {
        final parts = ingredient.split('|').map((e) => e.trim()).toList();

        // Ensure ingredient string is in the expected format: Name | Amount | Unit | (Optional notes)
        if (parts.length < 3) {
          // If unparsable, still add it as a standalone entry using its full text for display
          final name = parts.isNotEmpty ? parts[0] : ingredient;
          if (!_groupedIngredients.containsKey(name)) {
            _groupedIngredients[name] = _IngredientGroup(name: name);
          }
          _groupedIngredients[name]!.addEntry(recipe.name, ingredient);
          continue;
        }

        final name = parts[0];
        final amountString = parts[1];
        final unit = parts[2];
        final key = '$name|$unit'; // Key for aggregation

        final numAmount = double.tryParse(
          amountString.replaceAll(RegExp(r'[^\d.]'), ''),
        );

        if (numAmount != null) {
          final scaled = numAmount * multiplier;

          // --- AGGREGATION STEP ---
          aggregatedQuantities[key] =
              (aggregatedQuantities[key] ?? 0.0) + scaled;

          // Track which recipes contributed to this item
          contributingRecipes.putIfAbsent(key, () => {}).add(recipe.name);
        } else {
          // Non-scalable ingredient (e.g., "1 large onion") - treat as a unique group
          if (!_groupedIngredients.containsKey(name)) {
            _groupedIngredients[name] = _IngredientGroup(name: name);
          }
          _groupedIngredients[name]!.addEntry(recipe.name, ingredient);
        }
      }
    }

    // 2. Convert aggregated quantities into the _groupedIngredients structure
    aggregatedQuantities.forEach((key, totalQuantity) {
      final keyParts = key.split('|');
      final name = keyParts[0];
      final unit = keyParts[1];

      // Format the total quantity
      final formattedAmount = totalQuantity % 1 == 0
          ? totalQuantity.toInt().toString()
          : totalQuantity.toStringAsFixed(2);

      // Re-create the pipe-delimited string for the final display structure
      final aggregatedIngredientString = '$name | $formattedAmount | $unit';

      if (!_groupedIngredients.containsKey(name)) {
        _groupedIngredients[name] = _IngredientGroup(name: name);
      }

      // Create a single entry for the aggregated total, listing all contributors
      _groupedIngredients[name]!.addEntry(
        contributingRecipes[key]!.join(', '), // List all recipe names
        aggregatedIngredientString,
      );
    });

    setState(() {}); // Update the UI with the aggregated list
  }

  // The _scaleIngredient function is no longer needed since scaling is done in _aggregateIngredients
  // String _scaleIngredient(String ingredient, String recipeId) { ... }

  void _toggleItem(String key) {
    setState(() {
      _checkedItems[key] = !(_checkedItems[key] ?? false);
    });
  }
  // ... (rest of the functions and build method remain the same)
  // ...

  void _clearChecked() {
    setState(() {
      _checkedItems.removeWhere((_, checked) => checked);
    });
  }

  int get _totalItems => _groupedIngredients.length;
  int get _checkedCount => _checkedItems.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    final sortedKeys = _groupedIngredients.keys.toList()..sort();

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
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Shopping List',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (_checkedCount > 0)
                          TextButton.icon(
                            onPressed: _clearChecked,
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: Text(
                              'Clear ($_checkedCount)',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _totalItems > 0 ? _checkedCount / _totalItems : 0,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_checkedCount of $_totalItems items',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Shopping list
              Expanded(
                child: widget.recipes.isEmpty
                    ? const Center(
                        child: Text(
                          'No recipes added to shopping list',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedKeys.length,
                        itemBuilder: (_, i) {
                          final ingredientName = sortedKeys[i];
                          final group = _groupedIngredients[ingredientName]!;
                          final isChecked =
                              _checkedItems[ingredientName] ?? false;

                          return Card(
                            color: const Color(0xCCFFF8E7),
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CheckboxListTile(
                              value: isChecked,
                              onChanged: (_) => _toggleItem(ingredientName),
                              title: Text(
                                ingredientName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: isChecked
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isChecked ? Colors.grey : Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: group.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B4513),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            entry.recipeName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            entry.ingredient
                                                .split('|')
                                                .skip(1)
                                                .join('|')
                                                .trim(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isChecked
                                                  ? Colors.grey
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: const MacinnaFAB(),
    );
  }
}

// Helper class to group ingredients
class _IngredientGroup {
  final String name;
  final List<_IngredientEntry> entries = [];

  _IngredientGroup({required this.name});

  void addEntry(String recipeName, String ingredient) {
    entries.add(
      _IngredientEntry(recipeName: recipeName, ingredient: ingredient),
    );
  }
}

class _IngredientEntry {
  final String recipeName;
  final String ingredient;

  _IngredientEntry({required this.recipeName, required this.ingredient});
}
