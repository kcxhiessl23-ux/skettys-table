import 'package:flutter/material.dart';
import 'recipe_model.dart';
import 'video_segment_picker.dart';
import 'macinna_fab.dart';
import 'ingredient_data.dart'; // Keep this one reference to ingredient_data

// -----------------------------------------------------------------------------
// STEP EDITOR SCREEN
// -----------------------------------------------------------------------------

class StepEditorScreen extends StatefulWidget {
  final RecipeStep step;
  final int stepIndex;

  const StepEditorScreen({
    super.key,
    required this.step,
    required this.stepIndex,
  });

  @override
  State<StepEditorScreen> createState() => _StepEditorScreenState();
}

class _StepEditorScreenState extends State<StepEditorScreen> {
  // 1. STATE VARIABLES: Declared at the top of the class
  late TextEditingController _titleController;
  late TextEditingController _instructionsController;
  late TextEditingController _notesController;

  late List<StepPicture> _pictures;
  VideoSegment? _videoSegment;
  late List<StepTimer> _timers;
  late List<String> _stepIngredients;

  // Initialized fields
  final bool _isLoading = false;
  late bool _showChips;

  @override
  void initState() {
    super.initState();

    // 2. INITIALIZATION: All controllers and late fields are initialized here
    _titleController = TextEditingController(text: widget.step.title);
    _instructionsController = TextEditingController(
      text: widget.step.instructions,
    );
    _notesController = TextEditingController(text: widget.step.notes);

    _showChips = true;
    _pictures = List.from(widget.step.pictures);
    _timers = List.from(widget.step.timers);
    _stepIngredients = List.from(widget.step.stepIngredients);
    _videoSegment = widget.step.videoSegment;
  }

  @override
  void dispose() {
    // 3. CLEANUP: Dispose all controllers
    _titleController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // 4. HELPER METHODS: Must be outside of initState/dispose/build

  Future<void> _addPicture() async {
    // This function body was duplicated and incorrectly nested. Simplified below:
    // Skip file upload on web - just use placeholder
    setState(() {
      _pictures.add(
        StepPicture(
          url:
              'https://picsum.photos/200/200?random=${DateTime.now().millisecondsSinceEpoch}',
          caption: '',
        ),
      );
    });
  }

  Future<void> _addVideoSegment() async {
    final segment = await Navigator.push<VideoSegment>(
      context,
      MaterialPageRoute(
        builder: (_) => VideoSegmentPicker(existingSegment: _videoSegment),
      ),
    );

    if (segment != null) {
      setState(() => _videoSegment = segment);
    }
  }

  void _addTimer() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final durationController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Timer Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (seconds)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    durationController.text.isNotEmpty) {
                  setState(() {
                    _timers.add(
                      StepTimer(
                        name: nameController.text,
                        durationSeconds: int.parse(durationController.text),
                      ),
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
  }

  void _saveStep() {
    final updatedStep = RecipeStep(
      stepNumber: widget.stepIndex + 1,
      title: _titleController.text,
      instructions: _instructionsController.text,
      notes: _notesController.text,
      pictures: _pictures,
      videoSegment: _videoSegment,
      timers: _timers,
      stepIngredients: _stepIngredients,
    );

    Navigator.pop(context, updatedStep);
  }

  // 5. BUILD METHOD: The mandatory UI definition
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4B896),
      appBar: AppBar(
        title: Text('Edit Step ${widget.stepIndex + 1}'),
        backgroundColor: const Color(0xFF8B4513),
        actions: [
          TextButton(
            onPressed: _saveStep,
            child: const Text(
              'Done',
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

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Title
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Step Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Instructions
                    TextField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Instructions',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Pictures Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pictures',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addPicture,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_pictures.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _pictures.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(_pictures[index].url),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => setState(
                                      () => _pictures.removeAt(index),
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Video Segment Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Video Segment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addVideoSegment,
                          icon: const Icon(Icons.videocam),
                          label: Text(_videoSegment == null ? 'Add' : 'Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (_videoSegment != null)
                      Card(
                        margin: const EdgeInsets.only(top: 8),
                        child: ListTile(
                          leading: const Icon(Icons.play_circle_outline),
                          title: Text(
                            '${_videoSegment!.startTimeSeconds}s - ${_videoSegment!.endTimeSeconds}s',
                          ),
                          subtitle: Text(_videoSegment!.url),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => _videoSegment = null),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Timers Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Timers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addTimer,
                          icon: const Icon(Icons.timer),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._timers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final timer = entry.value;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.timer),
                          title: Text(timer.name),
                          subtitle: Text(
                            '${timer.durationSeconds ~/ 60}:${(timer.durationSeconds % 60).toString().padLeft(2, '0')}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => _timers.removeAt(index)),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Ingredients Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ingredients for this step',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final newIngredients =
                                await showDialog<List<String>>(
                                  context: context,
                                  builder: (dialogContext) =>
                                      const _IngredientInputDialog(),
                                );

                            if (newIngredients != null &&
                                newIngredients.isNotEmpty) {
                              setState(() {
                                _stepIngredients.addAll(newIngredients);
                              });
                            }
                          },
                          icon: const Icon(Icons.restaurant),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Ingredient list
                    ..._stepIngredients.asMap().entries.map((entry) {
                      final index = entry.key;
                      final ingredient = entry.value;
                      return Card(
                        child: ListTile(
                          leading: const Text(
                            '•',
                            style: TextStyle(fontSize: 24),
                          ),
                          title: Text(ingredient),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(
                              () => _stepIngredients.removeAt(index),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 100),
                  ],
                ),

          const SizedBox(height: 24),
        ],
      ),
      floatingActionButton: const MacinnaFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}

// -----------------------------------------------------------------------------
// INGREDIENT INPUT DIALOG (Correctly placed outside _StepEditorScreenState)
// -----------------------------------------------------------------------------

class _IngredientInputDialog extends StatefulWidget {
  const _IngredientInputDialog();

  @override
  State<_IngredientInputDialog> createState() => _IngredientInputDialogState();
}

class _IngredientInputDialogState extends State<_IngredientInputDialog> {
  final _ingredientController = TextEditingController();
  final _amountController = TextEditingController();
  final _ingredientFocus = FocusNode();
  final _amountFocus = FocusNode();

  String _selectedUnit = 'cup';
  List<String> _filteredIngredients = [];
  bool _showChips = false;
  final List<String> _addedIngredients = [];

  @override
  void initState() {
    super.initState();
    _filteredIngredients = IngredientData.getTopIngredients(10);
    _showChips = true;
  }

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
        _filteredIngredients = IngredientData.getTopIngredients(20);
        _showChips = true; // Show top 10 by default
      } else {
        _filteredIngredients = IngredientData.searchIngredients(
          value,
          limit: 10,
        );
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

  void _finalizeAdd(String ingredient, String amount, bool addToList) {
    if (addToList) {
      IngredientData.addIngredient(ingredient);
    }

    final formatted = '$ingredient | $amount | $_selectedUnit';

    print('DEBUG: Adding ingredient: $formatted');

    setState(() {
      _addedIngredients.add(formatted);
      print(
        'DEBUG: _addedIngredients now has ${_addedIngredients.length} items',
      );
      _ingredientController.clear();
      _amountController.clear();
      _selectedUnit = 'cup';
      _showChips = false;
      _filteredIngredients = [];
    });

    _ingredientFocus.requestFocus();
  }

  // ... inside class _IngredientInputDialogState

  void _addIngredient() async {
    final ingredient = _ingredientController.text.trim();
    final amount = _amountController.text.trim();

    if (ingredient.isEmpty || amount.isEmpty) {
      return;
    }

    // *** FIX IS HERE: Changed IngredientData.ingredients to IngredientData.allIngredientsList ***
    final exists = IngredientData.allIngredientsList.any(
      (i) => i.toLowerCase() == ingredient.toLowerCase(),
    );

    print('DEBUG: Ingredient exists in list: $exists');

    _finalizeAdd(ingredient, amount, !exists);
  } // <-- ADDED THE MISSING CLOSING BRACE FOR _addIngredient HERE

  void _saveAndClose() {
    print('DEBUG: Saving ${_addedIngredients.length} ingredients');
    print('DEBUG: Ingredients: $_addedIngredients');
    Navigator.pop(context, _addedIngredients);
  }

  @override // <-- THIS MUST BE HERE
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 1000,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Add Ingredients',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

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
                    ),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
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
            const SizedBox(height: 12),

            // Chips
            // Chips
            if (_showChips) ...[
              // Removed extra vertical space here
              SizedBox(
                height: 100, // Explicitly set height
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filteredIngredients.map((ingredient) {
                      return ActionChip(
                        label: Text(ingredient),
                        onPressed: () => _selectIngredient(ingredient),
                        // Retaining your custom colors
                        backgroundColor: const Color(0xAA8B4513),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            // Adjusted vertical spacing
            const SizedBox(height: 16),
            const Divider(),

            // Added ingredients list
            Expanded(
              child: ListView.builder(
                // ... rest of ListView.builder ...
                itemCount: _addedIngredients.length,
                itemBuilder: (_, i) {
                  return ListTile(
                    leading: const Text('•'),
                    title: Text(_addedIngredients[i]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          setState(() => _addedIngredients.removeAt(i)),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveAndClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
