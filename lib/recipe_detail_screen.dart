import 'package:flutter/material.dart';
import 'recipe_model.dart';
import 'create_recipe_screen.dart';
import 'firestore_service.dart';
import 'macinna_fab.dart';
import 'unified_cook_mode.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe;
  double _servingMultiplier = 1.0;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
  }

  String _scaleIngredient(String ingredient) {
    final parts = ingredient.split('|').map((e) => e.trim()).toList();
    if (parts.length < 3) return ingredient;

    final name = parts[0];
    final amount = parts[1];
    final unit = parts[2];

    // Try parsing as number (handles decimals and fractions)
    final numAmount = double.tryParse(amount.replaceAll(RegExp(r'[^\d.]'), ''));
    if (numAmount != null) {
      final scaled = numAmount * _servingMultiplier;
      final formattedAmount = scaled % 1 == 0
          ? scaled.toInt().toString()
          : scaled.toStringAsFixed(2);
      return '$name | $formattedAmount | $unit';
    }

    return ingredient; // Can't scale "to taste", etc
  }

  void _adjustServings(int change) {
    setState(() {
      final newServings = (_recipe.servings * _servingMultiplier + change)
          .clamp(1, 100);
      _servingMultiplier = newServings / _recipe.servings;
    });
  }

  Future<void> _deleteRecipe() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Recipe?'),
        content: Text('Are you sure you want to delete "${_recipe.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.deleteRecipe(_recipe.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Recipe deleted')));
      }
    }
  }

  Future<void> _editRecipe() async {
    final updatedRecipe = await Navigator.push<Recipe>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateRecipeScreen(existingRecipe: _recipe),
      ),
    );

    if (updatedRecipe != null) {
      setState(() => _recipe = updatedRecipe);
    }
  }

  void _startCooking() {
    final scaledServings = (_recipe.servings * _servingMultiplier).round();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedCookMode(
          recipes: [_recipe],
          servingsOverrides: {_recipe.id: scaledServings},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentServings = (_recipe.servings * _servingMultiplier).round();

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
                alignment: Alignment.center,
              ),
            ),
          ),

          // Content
          CustomScrollView(
            slivers: [
              // Hero Image AppBar
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: const Color(0xFF8B4513),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    _recipe.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(_recipe.coverImageUrl, fit: BoxFit.cover),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      // Macy watermark
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Opacity(
                          opacity: 0.3,
                          child: Image.asset(
                            'assets/images/icons/macy template.png',
                            height: 80,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Color(0xFF8B4513)),
                            SizedBox(width: 8),
                            Text('Edit Recipe'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'meal',
                        child: Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              color: Color(0xFF8B4513),
                            ),
                            SizedBox(width: 8),
                            Text('Add to Meal Plan'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Recipe'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editRecipe();
                          break;
                        case 'meal':
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coming soon!')),
                          );
                          break;
                        case 'delete':
                          _deleteRecipe();
                          break;
                      }
                    },
                  ),
                ],
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Quick Stats
                    Card(
                      color: const Color(0x90FFF8E7),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            _StatChip(
                              icon: Icons.timer,
                              label: 'Prep',
                              value: '${_recipe.prepTimeMinutes} min',
                            ),
                            _StatChip(
                              icon: Icons.restaurant,
                              label: 'Cook',
                              value: '${_recipe.cookTimeMinutes} min',
                            ),
                            _StatChip(
                              icon: Icons.people,
                              label: 'Serves',
                              value: '$currentServings',
                            ),
                            _StatChip(
                              icon: Icons.signal_cellular_alt,
                              label: 'Difficulty',
                              value: _recipe.difficulty,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Servings Adjuster
                    Card(
                      color: const Color(0x90F5E6D3),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Adjust Servings:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _adjustServings(-1),
                                  icon: const Icon(Icons.remove_circle),
                                  color: const Color(0xFF8B4513),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$currentServings',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _adjustServings(1),
                                  icon: const Icon(Icons.add_circle),
                                  color: const Color(0xFF8B4513),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    if (_recipe.description.isNotEmpty)
                      Card(
                        color: const Color(0x90FFF8E7),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(_recipe.description),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Tags + Equipment
                    Card(
                      color: const Color(0x90F5E6D3),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tags
                            Expanded(
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
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: _recipe.tags.map((tag) {
                                      return Chip(
                                        label: Text(tag),
                                        backgroundColor: const Color(
                                          0xFFD4B896,
                                        ),
                                        labelStyle: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Equipment
                            Expanded(
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
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: _recipe.equipment.map((item) {
                                      return Chip(
                                        label: Text(item),
                                        backgroundColor: const Color(
                                          0xFFD4B896,
                                        ),
                                        labelStyle: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Ingredients
                    Card(
                      color: const Color(0x90FFF8E7),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ingredients',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._recipe.ingredients.map((ing) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.fiber_manual_record,
                                      size: 8,
                                      color: Color(0xFF8B4513),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(_scaleIngredient(ing)),
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

                    // Steps
                    const Text(
                      'Steps',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ..._recipe.steps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      return _StepCard(
                        step: step,
                        index: index,
                        scaleIngredient: _scaleIngredient,
                      );
                    }),

                    const SizedBox(height: 16),

                    // Notes
                    if (_recipe.notes.isNotEmpty)
                      Card(
                        color: const Color(0x90F5E6D3),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(_recipe.notes),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),

      // Start Cooking FAB
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _startCooking,
            backgroundColor: const Color(0xFF8B4513),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Cooking'),
          ),
          const SizedBox(width: 16),
          const MacinnaFAB(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Stat Chip Widget
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8B4513)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Step Card Widget
class _StepCard extends StatefulWidget {
  final RecipeStep step;
  final int index;
  final String Function(String) scaleIngredient;

  const _StepCard({
    required this.step,
    required this.index,
    required this.scaleIngredient,
  });

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.index % 2 == 0
          ? const Color(0x90FFF8E7)
          : const Color(0x90F5E6D3),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF8B4513),
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.step.title.isEmpty
                          ? 'Step ${widget.index + 1}'
                          : widget.step.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Preview icons
                  if (!_isExpanded) ...[
                    if (widget.step.pictures.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text('📷${widget.step.pictures.length}'),
                      ),
                    if (widget.step.videoSegment != null)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text('🎥1'),
                      ),
                    if (widget.step.timers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text('⏲️${widget.step.timers.length}'),
                      ),
                    if (widget.step.stepIngredients.isNotEmpty)
                      Text('🥕${widget.step.stepIngredients.length}'),
                  ],
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF8B4513),
                  ),
                ],
              ),

              // Expanded Content
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Instructions
                if (widget.step.instructions.isNotEmpty) ...[
                  const Text(
                    'Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.step.instructions),
                  const SizedBox(height: 16),
                ],

                // Step Ingredients
                if (widget.step.stepIngredients.isNotEmpty) ...[
                  const Text(
                    'Ingredients for this step:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...widget.step.stepIngredients.map((ing) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fiber_manual_record,
                            size: 6,
                            color: Color(0xFF8B4513),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(widget.scaleIngredient(ing))),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Timers
                if (widget.step.timers.isNotEmpty) ...[
                  const Text(
                    'Timers:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...widget.step.timers.map((timer) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            size: 16,
                            color: Color(0xFF8B4513),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${timer.name}: ${timer.durationSeconds ~/ 60}:${(timer.durationSeconds % 60).toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Pictures
                if (widget.step.pictures.isNotEmpty) ...[
                  const Text(
                    'Photos:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.step.pictures.length,
                      itemBuilder: (_, i) {
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(widget.step.pictures[i].url),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Video Segment
                if (widget.step.videoSegment != null) ...[
                  const Text(
                    'Video Segment:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          color: Color(0xFF8B4513),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.step.videoSegment!.startTimeSeconds}s - ${widget.step.videoSegment!.endTimeSeconds}s',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes
                if (widget.step.notes.isNotEmpty) ...[
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.step.notes),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
