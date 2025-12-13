import 'package:flutter/material.dart';
import 'ingredient_data.dart';
// OR if the file is in the same directory:

class IngredientInputWidget extends StatefulWidget {
  final Function(String) onIngredientAdded;

  const IngredientInputWidget({super.key, required this.onIngredientAdded});

  @override
  State<IngredientInputWidget> createState() => _IngredientInputWidgetState();
}

class _IngredientInputWidgetState extends State<IngredientInputWidget> {
  final _ingredientController = TextEditingController();
  final _amountController = TextEditingController();
  final _ingredientFocus = FocusNode();
  final _amountFocus = FocusNode();

  String _selectedUnit = 'cup';
  List<String> _filteredIngredients = [];
  bool _showChips = false;

  @override
  void dispose() {
    _ingredientController.dispose();
    _amountController.dispose();
    _ingredientFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _onIngredientChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _filteredIngredients = [];
        _showChips = false;
      } else {
        _filteredIngredients = IngredientData.allIngredientsList
            .where((ing) => ing.toLowerCase().contains(value.toLowerCase()))
            .take(6)
            .toList();
        _showChips = _filteredIngredients.isNotEmpty;
      }
    });
  }

  void _selectIngredient(String ingredient) {
    setState(() {
      _ingredientController.text = ingredient;
      _showChips = false;
      _filteredIngredients = [];
    });
    _amountFocus.requestFocus();
  }

  void _addIngredient() {
    final ingredient = _ingredientController.text.trim();
    final amount = _amountController.text.trim();

    if (ingredient.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    // Check if ingredient exists
    final exists = IngredientData.allIngredientsList.any(
      (i) => i.toLowerCase() == ingredient.toLowerCase(),
    );

    if (!exists) {
      // Show dialog for unknown ingredient
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Add "$ingredient"?'),
          content: const Text(
            'This ingredient is not in the list. Would you like to add it?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _finalizeAdd(ingredient, amount, false);
              },
              child: const Text('Just Use Once'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _finalizeAdd(ingredient, amount, true);
              },
              child: const Text('Add & Use'),
            ),
          ],
        ),
      );
    } else {
      _finalizeAdd(ingredient, amount, false);
    }
  }

  void _finalizeAdd(String ingredient, String amount, bool addToList) {
    if (addToList) {
      IngredientData.addIngredient(ingredient);
    }

    final formatted = '$ingredient | $amount | $_selectedUnit';
    widget.onIngredientAdded(formatted);

    // Clear fields
    setState(() {
      _ingredientController.clear();
      _amountController.clear();
      _selectedUnit = 'cup';
      _showChips = false;
      _filteredIngredients = [];
    });
    _ingredientFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF5E6D3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entry bar
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _ingredientController,
                    focusNode: _ingredientFocus,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Ingredient',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: _onIngredientChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.text,
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    menuMaxHeight: 300,
                    items: IngredientData.units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v!),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add_circle, color: Color(0xFF8B4513)),
                  iconSize: 32,
                ),
              ],
            ),

            // Chips
            if (_showChips) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filteredIngredients.map((ingredient) {
                  return ActionChip(
                    label: Text(ingredient),
                    onPressed: () => _selectIngredient(ingredient),
                    backgroundColor: Colors.brown.shade100,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
