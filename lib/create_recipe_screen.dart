import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'recipe_model.dart';
import 'firestore_service.dart';
import 'step_editor_screen.dart';

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

  List<String> _selectedTags = [];

  // Controllers for basic info
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  final _notesController = TextEditingController();

  String _difficulty = 'Easy';
  String? _coverImageUrl;
  final List<RecipeStep> _steps = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
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
    if (_coverImageUrl == null) {
      // Use placeholder for web testing
      _coverImageUrl ??= 'https://picsum.photos/300/200';
    }

    setState(() => _isLoading = true);

    final recipe = Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      coverImageUrl: _coverImageUrl!,
      category: _categoryController.text,
      tags: _selectedTags,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cover Image
            GestureDetector(
              onTap: _pickCoverImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.brown.shade100,
                  borderRadius: BorderRadius.circular(12),
                  image: _coverImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _coverImageUrl == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // Recipe Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Recipe Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Category + Add button
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
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
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xFF8B4513),
                    size: 28,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        final controller = TextEditingController();
                        return AlertDialog(
                          title: const Text('Add Category'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              hintText: 'New category',
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
                                  setState(() {
                                    _categoryOptions.add(controller.text);
                                    _categoryController.text = controller.text;
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
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle,
                    color: Colors.red,
                    size: 28,
                  ),
                  onPressed: () {
                    if (_categoryController.text.isNotEmpty &&
                        ![
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
                        ].contains(_categoryController.text)) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Category'),
                          content: Text(
                            'Remove "${_categoryController.text}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _categoryOptions.remove(
                                    _categoryController.text,
                                  );
                                  _categoryController.clear();
                                });
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot delete default categories'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _difficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Easy', 'Medium', 'Hard']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _difficulty = v!),
                  ),
                ),
              ],
            ),

            // Tags section
            Row(
              children: [
                const Text(
                  'Tags:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF8B4513)),
                  onPressed: () {
                    // Add custom tag
                    showDialog(
                      context: context,
                      builder: (context) {
                        final controller = TextEditingController();
                        return AlertDialog(
                          title: const Text('Add Tag'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              hintText: 'New tag',
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
                                  setState(() {
                                    _tagOptions.add(controller.text);
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

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tagOptions.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Tag'),
                        content: Text('Remove "$tag" from available tags?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _tagOptions.remove(tag);
                                _selectedTags.remove(tag);
                              });
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: FilterChip(
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
                    selectedColor: const Color(0xFF8B4513).withOpacity(0.3),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Times and Servings Row
            Row(
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
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Steps Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Steps',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addStep(),
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

            // Steps List
            ..._steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF8B4513),
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    step.title.isEmpty ? 'Step ${index + 1}' : step.title,
                  ),
                  subtitle: Text(
                    step.instructions.isEmpty
                        ? 'No instructions'
                        : step.instructions,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _steps.removeAt(index)),
                  ),
                  onTap: () => _editStep(index),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _addStep() {
    // TODO: Navigate to step editor
    setState(() {
      _steps.add(
        RecipeStep(
          stepNumber: _steps.length + 1,
          title: 'Step ${_steps.length + 1}',
          instructions: '',
          notes: '',
          pictures: [],
          timers: [],
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
}
