import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'recipe_model.dart';
import 'firestore_service.dart';
import 'step_editor_screen.dart';
import 'macinna_fab.dart';

class CreateRecipeScreen extends StatefulWidget {
  final Recipe? existingRecipe;

  const CreateRecipeScreen({super.key, this.existingRecipe});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  final List<String> _categoryOptions = [
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

  final List<String> _tagOptions = [
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

  final List<String> _selectedTags = [];

  // Controllers for basic info
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  final _notesController = TextEditingController();

  String _difficulty = 'Easy';
  String? _coverImageUrl;
  final List<RecipeStep> _steps = [];
  final List<String> _equipment = [];
  final List<String> _additionalIngredients = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingRecipe != null) {
      final recipe = widget.existingRecipe!;
      _nameController.text = recipe.name;
      _descriptionController.text = recipe.description;
      _categoryController.text = recipe.category;
      _prepTimeController.text = recipe.prepTimeMinutes.toString();
      _cookTimeController.text = recipe.cookTimeMinutes.toString();
      _servingsController.text = recipe.servings.toString();
      _notesController.text = recipe.notes;
      _difficulty = recipe.difficulty;
      _coverImageUrl = recipe.coverImageUrl;
      _selectedTags.addAll(recipe.tags);
      _equipment.addAll(recipe.equipment);
      _additionalIngredients.addAll(
        recipe.ingredients.where(
          (ing) =>
              !recipe.steps.any((step) => step.stepIngredients.contains(ing)),
        ),
      );
      _steps.addAll(recipe.steps);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isLoading = true);

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('recipeCoverImages')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(File(pickedFile.path));
      final url = await ref.getDownloadURL();

      setState(() {
        _coverImageUrl = url;
        _isLoading = false;
      });
    }
  }

  /// Builds the ingredientList from step ingredients + additional ingredients
  List<Ingredient> _buildIngredientList() {
    final List<Ingredient> result = [];

    // Parse step ingredients
    for (var step in _steps) {
      for (var ing in step.stepIngredients) {
        final parsed = _parseIngredientString(ing);
        if (parsed != null) {
          result.add(parsed);
        }
      }
    }

    // Parse additional ingredients
    for (var ing in _additionalIngredients) {
      final parsed = _parseIngredientString(ing);
      if (parsed != null) {
        result.add(parsed);
      }
    }

    return result;
  }

  /// Parses "Name | Amount | Unit" format into Ingredient object
  Ingredient? _parseIngredientString(String ingredientStr) {
    final parts = ingredientStr.split('|').map((e) => e.trim()).toList();
    if (parts.isEmpty) return null;

    final name = parts[0];
    final quantity = parts.length > 1
        ? double.tryParse(parts[1].replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0
        : 0.0;
    final unit = parts.length > 2 ? parts[2] : '';

    return Ingredient(
      name: name,
      quantity: quantity,
      unit: unit,
      rawText: ingredientStr,
    );
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    _coverImageUrl ??= 'https://picsum.photos/300/200';

    setState(() => _isLoading = true);

    // Aggregate all ingredients from steps + additional
    final Set<String> allIngredients = {};
    for (var step in _steps) {
      allIngredients.addAll(step.stepIngredients);
    }
    allIngredients.addAll(_additionalIngredients);

    final recipe = Recipe(
      id:
          widget.existingRecipe?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      description: _descriptionController.text,
      coverImageUrl: _coverImageUrl!,
      category: _categoryController.text,
      tags: _selectedTags,
      equipment: _equipment,
      ingredients: allIngredients.toList()..sort(),
      ingredientList: _buildIngredientList(), // <-- FIXED: Added this
      prepTimeMinutes: int.tryParse(_prepTimeController.text) ?? 0,
      cookTimeMinutes: int.tryParse(_cookTimeController.text) ?? 0,
      servings: int.tryParse(_servingsController.text) ?? 1,
      difficulty: _difficulty,
      notes: _notesController.text,
      steps: _steps,
      createdAt: widget.existingRecipe?.createdAt ?? DateTime.now(),
    );

    await _firestoreService.saveRecipe(recipe);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recipe saved!')));
      Navigator.pop(context);
    }
  }

  /////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4B896),
      appBar: AppBar(
        title: Text(
          widget.existingRecipe != null ? 'Edit Recipe' : 'Create Recipe',
        ),
        backgroundColor: const Color(0xFF8B4513),
        actions: [
          if (_steps.isNotEmpty)
            TextButton(
              onPressed: _isLoading ? null : _saveRecipe,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Save',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Macy background
          Positioned.fill(
            child: Opacity(
              opacity: 0.50,
              child: Image.asset(
                'assets/images/backgrounds/bgCreateRecipe.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),

          // Main content
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cover Image + Name/Description side-by-side
                Card(
                  color: const Color(0x80F5E6D3),
                  elevation: 7.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Image (left)
                        GestureDetector(
                          onTap: _pickCoverImage,
                          child: Container(
                            width: 400,
                            height: 400,
                            decoration: BoxDecoration(
                              color: Colors.brown.shade100,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              image: _coverImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_coverImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _coverImageUrl == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 50,
                                        color: Colors.brown.shade300,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add Cover Photo',
                                        style: TextStyle(
                                          color: Colors.brown.shade400,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Name + Description (right)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Recipe Name',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Color(0xCCFFFFFF),
                                ),
                                validator: (v) =>
                                    v?.isEmpty ?? true ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Color(0xCCFFFFFF),
                                ),
                                maxLines: 4,
                              ),
                              const SizedBox(height: 16),

                              // Category dropdown
                              DropdownButtonFormField<String>(
                                value: _categoryController.text.isEmpty
                                    ? null
                                    : _categoryController.text,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Color(0xCCFFFFFF),
                                ),
                                items: _categoryOptions.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(
                                      () => _categoryController.text = v,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time/Servings/Difficulty Row
                Card(
                  color: const Color(0x80F5E6D3),
                  elevation: 7.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _prepTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Prep Time (min)',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Color(0xCCFFFFFF),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cookTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Cook Time (min)',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Color(0xCCFFFFFF),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _servingsController,
                            decoration: const InputDecoration(
                              labelText: 'Servings',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Color(0xCCFFFFFF),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _difficulty,
                            decoration: const InputDecoration(
                              labelText: 'Difficulty',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Color(0xCCFFFFFF),
                            ),
                            items: ['Easy', 'Medium', 'Hard'].map((d) {
                              return DropdownMenuItem(value: d, child: Text(d));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _difficulty = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tags Section
                Card(
                  color: const Color(0x80F5E6D3),
                  elevation: 7.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tags',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tagOptions.map((tag) {
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
                                });
                              },
                              selectedColor: const Color(0xFF8B4513),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Equipment Section
                Card(
                  color: const Color(0x80F5E6D3),
                  elevation: 7.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Equipment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._equipment.map((eq) {
                              return Chip(
                                label: Text(eq),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () {
                                  setState(() => _equipment.remove(eq));
                                },
                              );
                            }),
                            ActionChip(
                              avatar: const Icon(Icons.add, size: 18),
                              label: const Text('Add'),
                              onPressed: _addEquipment,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Steps Section
                Card(
                  color: const Color(0x80F5E6D3),
                  elevation: 7.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Steps',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _addStep,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Step'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B4513),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_steps.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'No steps yet. Add your first step!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _steps.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final step = _steps.removeAt(oldIndex);
                                _steps.insert(newIndex, step);
                                // Update step numbers
                                for (var i = 0; i < _steps.length; i++) {
                                  _steps[i] = RecipeStep(
                                    stepNumber: i + 1,
                                    title: _steps[i].title,
                                    instructions: _steps[i].instructions,
                                    notes: _steps[i].notes,
                                    pictures: _steps[i].pictures,
                                    videoSegment: _steps[i].videoSegment,
                                    timers: _steps[i].timers,
                                    stepIngredients: _steps[i].stepIngredients,
                                  );
                                }
                              });
                            },
                            itemBuilder: (context, index) {
                              final step = _steps[index];
                              final ingredientCount =
                                  step.stepIngredients.length;
                              final timerCount = step.timers.length;
                              final hasVideo = step.videoSegment != null;
                              final hasPictures = step.pictures.isNotEmpty;

                              return Card(
                                key: ValueKey('step_$index'),
                                color: index % 2 == 0
                                    ? const Color(0xCCFFF8E7)
                                    : const Color(0xCCF5E6D3),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.drag_handle),
                                  ),
                                  title: Text(
                                    step.title.isEmpty
                                        ? 'Step ${index + 1}'
                                        : 'Step ${index + 1}: ${step.title}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      if (hasPictures)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Text('📷'),
                                        ),
                                      if (hasVideo)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Text('🎥'),
                                        ),
                                      if (timerCount > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: Text('⏲️$timerCount'),
                                        ),
                                      if (ingredientCount > 0)
                                        Text('🥕$ingredientCount'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _editStep(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _confirmDeleteStep(index),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _editStep(index),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Master Ingredients List (read-only aggregation)
                if (_steps.isNotEmpty || _additionalIngredients.isNotEmpty)
                  Card(
                    color: const Color(0x80F5E6D3),
                    elevation: 7.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'All Ingredients',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._getAllIngredients().map((ing) {
                            final stepNum = _getStepNumberForIngredient(ing);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.fiber_manual_record,
                                    size: 8,
                                    color: Color(0xFF8B4513),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(ing)),
                                  if (stepNum != null)
                                    GestureDetector(
                                      onTap: () => _jumpToStep(stepNum - 1),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B4513),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'Step $stepNum',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Additional Ingredients Section
                Card(
                  color: const Color(0x80F5E6D3),
                  elevation: 7.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Garnishes & Optional Ingredients',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._additionalIngredients.asMap().entries.map((e) {
                          return ListTile(
                            dense: true,
                            title: Text(e.value),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(
                                () => _additionalIngredients.removeAt(e.key),
                              ),
                            ),
                          );
                        }),
                        ElevatedButton.icon(
                          onPressed: _addAdditionalIngredient,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Garnish/Optional'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Notes Section
                const SizedBox(height: 16),
                Card(
                  color: const Color(0x80F5E6D3),
                  elevation: 7.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Recipe Notes',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xCCFFFFFF),
                      ),
                      maxLines: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: const MacinnaFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _addStep() {
    setState(() {
      _steps.add(
        RecipeStep(
          stepNumber: _steps.length + 1,
          title: '',
          instructions: '',
          notes: '',
          pictures: [],
          timers: [],
          stepIngredients: [],
        ),
      );
    });
  }

  Future<void> _editStep(int index) async {
    final updatedStep = await Navigator.push<RecipeStep>(
      context,
      MaterialPageRoute(
        builder: (_) => StepEditorScreen(step: _steps[index], stepIndex: index),
      ),
    );

    if (updatedStep != null) {
      setState(() => _steps[index] = updatedStep);
    }
  }

  List<String> _getAllIngredients() {
    final Map<String, List<String>> ingredientMap = {};

    // Aggregate from steps
    for (var step in _steps) {
      for (var ingredient in step.stepIngredients) {
        final parts = ingredient.split('|').map((e) => e.trim()).toList();
        if (parts.length >= 3) {
          final name = parts[0];
          final amount = parts[1];
          final unit = parts[2];

          if (!ingredientMap.containsKey(name)) {
            ingredientMap[name] = [];
          }
          ingredientMap[name]!.add('$amount $unit');
        }
      }
    }

    // Add additional ingredients
    for (var ingredient in _additionalIngredients) {
      final parts = ingredient.split('|').map((e) => e.trim()).toList();
      if (parts.length >= 3) {
        final name = parts[0];
        final amount = parts[1];
        final unit = parts[2];

        if (!ingredientMap.containsKey(name)) {
          ingredientMap[name] = [];
        }
        ingredientMap[name]!.add('$amount $unit');
      }
    }

    // Format output
    final List<String> result = [];
    final sortedKeys = ingredientMap.keys.toList()..sort();

    for (var name in sortedKeys) {
      final amounts = ingredientMap[name]!.join(', ');
      result.add('$name - $amounts');
    }

    return result;
  }

  void _addAdditionalIngredient() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Optional Ingredients'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Format: Ingredient | Qty | Unit | Brand (optional)\nOne per line',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Salt | to taste\nParsley | for garnish',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                onSubmitted: (_) {
                  if (controller.text.isNotEmpty) {
                    final lines = controller.text
                        .split('\n')
                        .where((line) => line.trim().isNotEmpty);
                    setState(() => _additionalIngredients.addAll(lines));
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final lines = controller.text
                    .split('\n')
                    .where((line) => line.trim().isNotEmpty);
                setState(() => _additionalIngredients.addAll(lines));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addEquipment() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Equipment'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'e.g., Large pot'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _equipment.add(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStep(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Step ${index + 1}?'),
        content: const Text('This will remove all content from this step.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _steps.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  int? _getStepNumberForIngredient(String ingredient) {
    for (var step in _steps) {
      if (step.stepIngredients.contains(ingredient)) {
        return step.stepNumber;
      }
    }
    return null;
  }

  void _jumpToStep(int index) {
    _editStep(index);
  }
}
