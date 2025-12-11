import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'recipe_model.dart';
import 'firestore_service.dart';
import 'step_editor_screen.dart';
import 'macinna_fab.dart';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

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
  final _descriptionController = TextEditingController(); // ADD THIS
  final _categoryController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  final _notesController = TextEditingController();

  String _difficulty = 'Easy';
  String? _coverImageUrl;
  final List<RecipeStep> _steps = [];
  final List<String> _equipment = []; // ADD THIS
  final List<String> _additionalIngredients = []; // ADD THIS

  bool _isLoading = false;

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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      description: _descriptionController.text, // ADD THIS
      coverImageUrl: _coverImageUrl!,
      category: _categoryController.text,
      tags: _selectedTags,
      equipment: _equipment, // ADD THIS
      ingredients: allIngredients.toList()..sort(), // ADD THIS
      prepTimeMinutes: int.tryParse(_prepTimeController.text) ?? 0,
      cookTimeMinutes: int.tryParse(_cookTimeController.text) ?? 0,
      servings: int.tryParse(_servingsController.text) ?? 1,
      difficulty: _difficulty,
      notes: _notesController.text,
      steps: _steps,
      createdAt: DateTime.now(),
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
        title: const Text('Create Recipe'),
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
                            child: Stack(
                              children: [
                                if (_coverImageUrl == null)
                                  const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 50,
                                          color: Colors.brown,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Add Cover Photo',
                                          style: TextStyle(color: Colors.brown),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Macy watermark
                                if (_coverImageUrl != null)
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Opacity(
                                      opacity: 0.2,
                                      child: Image.asset(
                                        'assets/images/icons/macy template.png',
                                        height: 80,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  labelText: 'Recipe Name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF8B4513),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (v) =>
                                    v?.isEmpty ?? true ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF8B4513),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                maxLines: 3,
                                validator: (v) =>
                                    v?.isEmpty ?? true ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _categoryController.text.isEmpty
                                    ? null
                                    : _categoryController.text,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  border: OutlineInputBorder(),
                                ),
                                items: _categoryOptions.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    _categoryController.text = value;
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _difficulty,
                                decoration: const InputDecoration(
                                  labelText: 'Difficulty',
                                  border: OutlineInputBorder(),
                                ),
                                items: ['Easy', 'Medium', 'Hard']
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(d),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _difficulty = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tags + Equipment Card (side-by-side)
                Card(
                  color: const Color(0x70F5E6D3),
                  elevation: 7.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags (left 50%)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Tags:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Color(0xFF8B4513),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          final controller =
                                              TextEditingController();
                                          return AlertDialog(
                                            title: const Text('Add Tag'),
                                            content: TextField(
                                              controller: controller,
                                              textCapitalization:
                                                  TextCapitalization.sentences,
                                              decoration: const InputDecoration(
                                                hintText: 'New tag',
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  if (controller
                                                      .text
                                                      .isNotEmpty) {
                                                    setState(() {
                                                      _tagOptions.add(
                                                        controller.text,
                                                      );
                                                    });
                                                    Navigator.pop(context);
                                                  }
                                                },
                                                child: const Text('Add'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 80,
                                ),
                                child: SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _tagOptions.map((tag) {
                                      final isSelected = _selectedTags.contains(
                                        tag,
                                      );
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
                                        selectedColor: const Color(
                                          0xFF8B4513,
                                        ).withOpacity(0.3),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Equipment (right 50%)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Equipment:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Color(0xFF8B4513),
                                    ),
                                    onPressed: _addEquipment,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 80,
                                ),
                                child: SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _equipment.map((item) {
                                      return Chip(
                                        label: Text(item),
                                        onDeleted: () {
                                          setState(
                                            () => _equipment.remove(item),
                                          );
                                        },
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 16,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Times and Servings Card
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
                              labelText: 'Prep (min)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _cookTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Cook (min)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _servingsController,
                            decoration: const InputDecoration(
                              labelText: 'Servings',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Notes Card
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
                        labelText: 'Personal Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Steps Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Steps',
                      style: TextStyle(
                        fontSize: 20,
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
                const SizedBox(height: 12),

                // Steps List with preview counts
                ..._steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return Card(
                    color: index % 2 == 0
                        ? const Color(0x95FFF8E7) // Light color for even rows
                        : const Color(0x95F5E6D3),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF8B4513),
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        step.title.isEmpty ? 'Untitled Step' : step.title,
                      ),
                      subtitle: Row(
                        children: [
                          if (step.pictures.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text('📷${step.pictures.length}'),
                            ),
                          if (step.videoSegment != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: const Text('🎥1'),
                            ),
                          if (step.timers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text('⏲️${step.timers.length}'),
                            ),
                          if (step.stepIngredients.isNotEmpty)
                            Text('🥕${step.stepIngredients.length}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Color(0xFF8B4513),
                            ),
                            onPressed: () => _editStep(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteStep(index),
                          ),
                        ],
                      ),
                      onTap: () => _editStep(index),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Master Ingredients Section
                if (_steps.isNotEmpty)
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
                                'Ingredients',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_getAllIngredients().length} items',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _getAllIngredients().length,
                              itemBuilder: (_, i) {
                                final ing = _getAllIngredients()[i];
                                final stepNumber = _getStepNumberForIngredient(
                                  ing,
                                );
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text('${i + 1}. $ing')),
                                      if (stepNumber != null)
                                        GestureDetector(
                                          onTap: () =>
                                              _jumpToStep(stepNumber - 1),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF8B4513),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Step $stepNumber',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Garnishes & Optional Additions',
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
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
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
          title: '', // CHANGE TO EMPTY STRING
          instructions: '',
          notes: '',
          pictures: [],
          timers: [],
          stepIngredients: [], // ADD THIS
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
