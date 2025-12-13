import 'package:flutter/material.dart';
import 'dart:async';
import 'recipe_model.dart';
import 'macinna_fab.dart';
import 'meal_planning_hub.dart' show PlannedStep;

class UnifiedCookMode extends StatefulWidget {
  final List<Recipe> recipes;
  final Map<String, int> servingsOverrides;
  final Map<String, Color> recipeColors;
  final List<PlannedStep>? stepSequence;

  const UnifiedCookMode({
    super.key,
    required this.recipes,
    this.servingsOverrides = const {},
    this.recipeColors = const {},
    this.stepSequence,
  });

  @override
  State<UnifiedCookMode> createState() => _UnifiedCookModeState();
}

class _UnifiedCookModeState extends State<UnifiedCookMode> {
  late TabController _tabController;
  final Map<String, Set<int>> _completedSteps =
      {}; // recipeId -> completed step numbers
  final List<CookTimer> _activeTimers = [];
  Timer? _timerTicker;
  int? _drilledStepIndex;
  String? _drilledRecipeId;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();

    // Initialize completed steps tracking
    for (var recipe in widget.recipes) {
      _completedSteps[recipe.id] = {};
    }

    // Start timer ticker
    _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        for (var timer in _activeTimers) {
          if (timer.isRunning && timer.remainingSeconds > 0) {
            timer.remainingSeconds--;
            if (timer.remainingSeconds == 0) {
              _onTimerComplete(timer);
            }
          }
        }
        // Re-sort timers
        _activeTimers.sort(
          (a, b) => a.remainingSeconds.compareTo(b.remainingSeconds),
        );
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timerTicker?.cancel();
    super.dispose();
  }

  void _toggleStepCompletion(String recipeId, int stepNumber) {
    setState(() {
      if (_completedSteps[recipeId]!.contains(stepNumber)) {
        _completedSteps[recipeId]!.remove(stepNumber);
      } else {
        _completedSteps[recipeId]!.add(stepNumber);
      }
    });
  }

  void _startTimer(CookTimer timer) {
    setState(() {
      _activeTimers.add(timer);
      _activeTimers.sort(
        (a, b) => a.remainingSeconds.compareTo(b.remainingSeconds),
      );
    });
  }

  void _onTimerComplete(CookTimer timer) {
    // Play sound/notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏰ ${timer.name} complete!'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
      ),
    );
  }

  void _addCustomTimer() {
    showDialog(
      context: context,
      builder: (_) => _AddTimerDialog(
        onAdd: (name, seconds, recipeId) {
          final timer = CookTimer(
            name: name,
            totalSeconds: seconds,
            remainingSeconds: seconds,
            recipeId: recipeId,
          );
          _startTimer(timer);
        },
        recipes: widget.recipes,
      ),
    );
  }

  void _drillIntoStep(String recipeId, int stepIndex) {
    setState(() {
      _drilledRecipeId = recipeId;
      _drilledStepIndex = stepIndex;
    });
  }

  void _exitDrillMode() {
    setState(() {
      _drilledRecipeId = null;
      _drilledStepIndex = null;
    });
  }

  void _nextStep() {
    if (_drilledRecipeId != null && _drilledStepIndex != null) {
      final recipe = widget.recipes.firstWhere((r) => r.id == _drilledRecipeId);
      if (_drilledStepIndex! < recipe.steps.length - 1) {
        setState(() => _drilledStepIndex = _drilledStepIndex! + 1);
      }
    }
  }

  void _previousStep() {
    if (_drilledStepIndex != null && _drilledStepIndex! > 0) {
      setState(() => _drilledStepIndex = _drilledStepIndex! - 1);
    }
  }

  String _scaleIngredient(String ingredient, String recipeId) {
    final recipe = widget.recipes.firstWhere((r) => r.id == recipeId);
    final servings = widget.servingsOverrides[recipeId] ?? recipe.servings;
    final multiplier = servings / recipe.servings;

    final parts = ingredient.split('|').map((e) => e.trim()).toList();
    if (parts.length < 3) return ingredient;

    final name = parts[0];
    final amount = parts[1];
    final unit = parts[2];

    final numAmount = double.tryParse(amount.replaceAll(RegExp(r'[^\d.]'), ''));
    if (numAmount != null) {
      final scaled = numAmount * multiplier;
      final formattedAmount = scaled % 1 == 0
          ? scaled.toInt().toString()
          : scaled.toStringAsFixed(2);
      return '$name | $formattedAmount | $unit';
    }

    return ingredient;
  }

  List<_StepDisplay> _getFilteredSteps() {
    final List<_StepDisplay> steps = [];

    if (_currentTabIndex == 0) {
      // "All Steps" tab - use custom sequence if available
      if (widget.stepSequence != null && widget.stepSequence!.isNotEmpty) {
        for (var planned in widget.stepSequence!) {
          final recipe = widget.recipes.firstWhere(
            (r) => r.id == planned.recipeId,
          );
          steps.add(
            _StepDisplay(
              recipe: recipe,
              step: recipe.steps[planned.stepIndex],
              stepIndex: planned.stepIndex,
            ),
          );
        }
      } else {
        // Default: all recipes in order
        for (var recipe in widget.recipes) {
          for (var i = 0; i < recipe.steps.length; i++) {
            steps.add(
              _StepDisplay(recipe: recipe, step: recipe.steps[i], stepIndex: i),
            );
          }
        }
      }
    } else {
      // Specific recipe tab
      final recipe = widget.recipes[_currentTabIndex - 1];
      for (var i = 0; i < recipe.steps.length; i++) {
        steps.add(
          _StepDisplay(recipe: recipe, step: recipe.steps[i], stepIndex: i),
        );
      }
    }

    // Sort: incomplete first, completed at bottom
    steps.sort((a, b) {
      final aCompleted = _completedSteps[a.recipe.id]!.contains(
        a.step.stepNumber,
      );
      final bCompleted = _completedSteps[b.recipe.id]!.contains(
        b.step.stepNumber,
      );
      if (aCompleted && !bCompleted) return 1;
      if (!aCompleted && bCompleted) return -1;
      return 0;
    });

    return steps;
  }

  @override
  Widget build(BuildContext context) {
    // Drill mode - full step view
    if (_drilledRecipeId != null && _drilledStepIndex != null) {
      final recipe = widget.recipes.firstWhere((r) => r.id == _drilledRecipeId);
      final step = recipe.steps[_drilledStepIndex!];

      return Scaffold(
        backgroundColor: const Color(0xFFD4B896),
        appBar: AppBar(
          backgroundColor: const Color(0xFF8B4513),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _exitDrillMode,
          ),
          title: Text(
            'Step ${_drilledStepIndex! + 1} - ${recipe.name}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          bottom: _activeTimers.isNotEmpty
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _activeTimers.length,
                      itemBuilder: (_, i) {
                        final timer = _activeTimers[i];
                        final timerRecipe = widget.recipes.firstWhere(
                          (r) => r.id == timer.recipeId,
                        );
                        return _TimerChip(
                          timer: timer,
                          recipeName: timerRecipe.name,
                          color:
                              widget.recipeColors[timerRecipe.id] ??
                              const Color(0xFF8B4513),
                          onTap: () {
                            setState(() {
                              timer.isRunning = !timer.isRunning;
                            });
                          },
                          onDismiss: () {
                            setState(() {
                              _activeTimers.remove(timer);
                            });
                          },
                        );
                      },
                    ),
                  ),
                )
              : null,
        ),
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

            // Step content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    step.title.isEmpty
                        ? 'Step ${_drilledStepIndex! + 1}'
                        : step.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Instructions
                  if (step.instructions.isNotEmpty) ...[
                    const Text(
                      'Instructions:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.instructions,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Ingredients
                  if (step.stepIngredients.isNotEmpty) ...[
                    const Text(
                      'Ingredients:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...step.stepIngredients.map((ing) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.fiber_manual_record,
                              size: 8,
                              color: Color(0xFF8B4513),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_scaleIngredient(ing, recipe.id)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Timers
                  if (step.timers.isNotEmpty) ...[
                    const Text(
                      'Timers:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 70),
                    ...step.timers.map((timer) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _startTimer(
                              CookTimer(
                                name: timer.name,
                                totalSeconds: timer.durationSeconds,
                                remainingSeconds: timer.durationSeconds,
                                recipeId: recipe.id,
                              ),
                            );
                          },
                          icon: const Icon(Icons.timer),
                          label: Text(
                            '${timer.name} (${timer.durationSeconds ~/ 60}:${(timer.durationSeconds % 60).toString().padLeft(2, '0')})',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Pictures
                  if (step.pictures.isNotEmpty) ...[
                    const Text(
                      'Photos:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: step.pictures.length,
                        itemBuilder: (_, i) {
                          return Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(step.pictures[i].url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Video
                  if (step.videoSegment != null) ...[
                    const Text(
                      'Video Segment:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xCCFFF8E7),
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
                            '${step.videoSegment!.startTimeSeconds}s - ${step.videoSegment!.endTimeSeconds}s',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Notes
                  if (step.notes.isNotEmpty) ...[
                    const Text(
                      'Notes:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(step.notes),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),

        // Previous/Next buttons
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            4,
            16,
            4 + MediaQuery.of(context).padding.bottom,
          ),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _drilledStepIndex! > 0 ? _previousStep : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _drilledStepIndex! < recipe.steps.length - 1
                      ? _nextStep
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: const MacinnaFAB(),
      );
    }

    // Main scrollable list view
    final filteredSteps = _getFilteredSteps();

    return Scaffold(
      backgroundColor: const Color(0xFFD4B896),
      bottomNavigationBar: widget.recipes.length > 1
          ? BottomNavigationBar(
              currentIndex: _currentTabIndex,
              onTap: (i) => setState(() => _currentTabIndex = i),
              selectedItemColor: const Color(0xFF8B4513),
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.format_list_bulleted),
                  label: 'All Steps',
                ),
                ...widget.recipes.map(
                  (r) => BottomNavigationBarItem(
                    icon: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color:
                            (widget.recipeColors[r.id] ??
                                    const Color(0xFF8B4513))
                                .withOpacity(0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 1),
                      ),
                    ),
                    label: r.name.length > 12
                        ? '${r.name.substring(0, 12)}…'
                        : r.name,
                  ),
                ),
              ],
            )
          : null,
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
              // Header with timers
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 8,
                  16,
                  12,
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
                            'Cook Mode',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cooking complete! 🎉'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    // Timers bar
                    // Timers bar - always visible
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: Row(
                        children: [
                          Expanded(
                            child: _activeTimers.isEmpty
                                ? Center(
                                    child: Text(
                                      'No active timers',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 13,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _activeTimers.length,
                                    itemBuilder: (_, i) {
                                      final timer = _activeTimers[i];
                                      final recipe = widget.recipes.firstWhere(
                                        (r) => r.id == timer.recipeId,
                                      );
                                      return _TimerChip(
                                        timer: timer,
                                        recipeName: recipe.name,
                                        color:
                                            widget.recipeColors[recipe.id] ??
                                            const Color(0xFF8B4513),
                                        onTap: () {
                                          setState(() {
                                            timer.isRunning = !timer.isRunning;
                                          });
                                        },
                                        onDismiss: () {
                                          setState(() {
                                            _activeTimers.remove(timer);
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.white,
                            ),
                            onPressed: _addCustomTimer,
                            tooltip: 'Add Timer',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Steps list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredSteps.length,
                  itemBuilder: (_, i) {
                    final display = filteredSteps[i];
                    final isCompleted = _completedSteps[display.recipe.id]!
                        .contains(display.step.stepNumber);

                    return _StepCard(
                      recipe: display.recipe,
                      step: display.step,
                      stepIndex: display.stepIndex,
                      isCompleted: isCompleted,
                      onToggleComplete: () => _toggleStepCompletion(
                        display.recipe.id,
                        display.step.stepNumber,
                      ),
                      onDrill: () =>
                          _drillIntoStep(display.recipe.id, display.stepIndex),
                      scaleIngredient: (ing) =>
                          _scaleIngredient(ing, display.recipe.id),
                      color:
                          widget.recipeColors[display.recipe.id] ??
                          const Color(0xFF8B4513),
                      onStartTimer: _startTimer,
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

// Helper classes
class _StepDisplay {
  final Recipe recipe;
  final RecipeStep step;
  final int stepIndex;

  _StepDisplay({
    required this.recipe,
    required this.step,
    required this.stepIndex,
  });
}

class CookTimer {
  final String name;
  final int totalSeconds;
  int remainingSeconds;
  final String recipeId;
  bool isRunning;

  CookTimer({
    required this.name,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.recipeId,
    this.isRunning = true,
  });
}

class _TimerChip extends StatefulWidget {
  final CookTimer timer;
  final String recipeName;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _TimerChip({
    required this.timer,
    required this.recipeName,
    required this.color,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_TimerChip> createState() => _TimerChipState();
}

class _TimerChipState extends State<_TimerChip>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  bool _isOverTarget = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = widget.timer.remainingSeconds ~/ 60;
    final seconds = widget.timer.remainingSeconds % 60;
    final isAlmostDone = widget.timer.remainingSeconds < 60;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: (_) {
        setState(() => _isDragging = true);
        _scaleController.forward();
      },
      onLongPressEnd: (_) {
        if (_isOverTarget) {
          widget.onDismiss();
        }
        setState(() {
          _isDragging = false;
          _isOverTarget = false;
        });
        _scaleController.reverse();
      },
      onLongPressMoveUpdate: (details) {
        // Check if dragged down into delete zone (60px below)
        setState(() {
          _isOverTarget = details.localOffsetFromOrigin.dy > 60;
        });
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? (_isOverTarget ? Colors.red.shade50 : Colors.white)
                        : (isAlmostDone ? Colors.red.shade100 : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDragging
                          ? (_isOverTarget ? Colors.red : widget.color)
                          : (isAlmostDone ? Colors.red : widget.color),
                      width: _isDragging ? 3 : 2,
                    ),
                    boxShadow: _isDragging
                        ? [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!widget.timer.isRunning)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.pause,
                            size: 14,
                            color: Colors.orange,
                          ),
                        ),
                      Text(
                        '$minutes:${seconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isAlmostDone ? Colors.red : widget.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.timer.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: isAlmostDone ? Colors.red : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Delete target - overflows without affecting layout
              if (_isDragging)
                Positioned(
                  top: 55,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isOverTarget ? Colors.red : Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: _isOverTarget ? Colors.white : Colors.red,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Step card widget
class _StepCard extends StatefulWidget {
  final Recipe recipe;
  final RecipeStep step;
  final int stepIndex;
  final bool isCompleted;
  final VoidCallback onToggleComplete;
  final VoidCallback onDrill;
  final String Function(String) scaleIngredient;
  final Color color;
  final Function(CookTimer) onStartTimer;

  const _StepCard({
    required this.recipe,
    required this.step,
    required this.stepIndex,
    required this.isCompleted,
    required this.onToggleComplete,
    required this.onDrill,
    required this.scaleIngredient,
    required this.color,
    required this.onStartTimer,
  });

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.isCompleted
          ? const Color(0x80E0E0E0)
          : const Color(0xCCFFF8E7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.isCompleted
              ? Colors.green
              : widget.color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Checkbox(
                    value: widget.isCompleted,
                    onChanged: (_) => widget.onToggleComplete(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step ${widget.stepIndex + 1} | ${widget.recipe.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isCompleted
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          widget.step.title.isEmpty
                              ? 'Step ${widget.stepIndex + 1}'
                              : widget.step.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: widget.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!_isExpanded) ...[
                    if (widget.step.stepIngredients.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text('🥕${widget.step.stepIngredients.length}'),
                      ),
                    if (widget.step.timers.isNotEmpty)
                      Text('⏲️${widget.step.timers.length}'),
                  ],
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF8B4513),
                  ),
                ],
              ),

              // Expanded content
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                if (widget.step.instructions.isNotEmpty) ...[
                  Text(
                    widget.step.instructions,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],

                if (widget.step.stepIngredients.isNotEmpty) ...[
                  const Text(
                    'Ingredients:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  ...widget.step.stepIngredients.take(3).map((ing) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fiber_manual_record,
                            size: 6,
                            color: Color(0xFF8B4513),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.scaleIngredient(ing),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (widget.step.stepIngredients.length > 3)
                    Text(
                      '+ ${widget.step.stepIngredients.length - 3} more',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  const SizedBox(height: 12),
                ],

                // Timers section
                if (widget.step.timers.isNotEmpty) ...[
                  const Text(
                    'Timers:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.step.timers.map((t) {
                      final mins = t.durationSeconds ~/ 60;
                      final secs = t.durationSeconds % 60;
                      return ActionChip(
                        avatar: const Icon(Icons.timer, size: 16),
                        label: Text(
                          '${t.name} (${mins}m${secs > 0 ? ' ${secs}s' : ''})',
                        ),
                        onPressed: () {
                          widget.onStartTimer(
                            CookTimer(
                              name: t.name,
                              totalSeconds: t.durationSeconds,
                              remainingSeconds: t.durationSeconds,
                              recipeId: widget.recipe.id,
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                ElevatedButton.icon(
                  onPressed: widget.onDrill,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View Full Step'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Add timer dialog
class _AddTimerDialog extends StatefulWidget {
  final Function(String, int, String) onAdd;
  final List<Recipe> recipes;

  const _AddTimerDialog({required this.onAdd, required this.recipes});

  @override
  State<_AddTimerDialog> createState() => _AddTimerDialogState();
}

class _AddTimerDialogState extends State<_AddTimerDialog> {
  final _nameController = TextEditingController();
  int _minutes = 10;
  int _seconds = 0;
  String? _selectedRecipeId;

  @override
  void initState() {
    super.initState();
    if (widget.recipes.isNotEmpty) {
      _selectedRecipeId = widget.recipes.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Timer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Timer Name'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Minutes'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _minutes = int.tryParse(v) ?? 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Seconds'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _seconds = int.tryParse(v) ?? 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedRecipeId,
            decoration: const InputDecoration(labelText: 'Recipe'),
            items: widget.recipes.map((r) {
              return DropdownMenuItem(value: r.id, child: Text(r.name));
            }).toList(),
            onChanged: (v) => setState(() => _selectedRecipeId = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty && _selectedRecipeId != null) {
              final totalSeconds = (_minutes * 60) + _seconds;
              widget.onAdd(
                _nameController.text,
                totalSeconds,
                _selectedRecipeId!,
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B4513),
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
