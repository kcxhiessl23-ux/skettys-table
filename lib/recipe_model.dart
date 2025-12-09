class Recipe {
  final String id;
  final String name;
  final String coverImageUrl;
  final String category;
  final List<String> tags;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final String difficulty;
  final String notes;
  final List<RecipeStep> steps;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.name,
    required this.coverImageUrl,
    required this.category,
    required this.tags,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.difficulty,
    required this.notes,
    required this.steps,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'coverImageUrl': coverImageUrl,
      'category': category,
      'tags': tags,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'servings': servings,
      'difficulty': difficulty,
      'notes': notes,
      'steps': steps.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      coverImageUrl: map['coverImageUrl'] ?? '',
      category: map['category'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      prepTimeMinutes: map['prepTimeMinutes'] ?? 0,
      cookTimeMinutes: map['cookTimeMinutes'] ?? 0,
      servings: map['servings'] ?? 0,
      difficulty: map['difficulty'] ?? '',
      notes: map['notes'] ?? '',
      steps:
          (map['steps'] as List<dynamic>?)
              ?.map((s) => RecipeStep.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class RecipeStep {
  final int stepNumber;
  final String title;
  final String instructions;
  final String notes;
  final List<StepPicture> pictures;
  final VideoSegment? videoSegment;
  final List<StepTimer> timers;

  RecipeStep({
    required this.stepNumber,
    required this.title,
    required this.instructions,
    required this.notes,
    required this.pictures,
    this.videoSegment,
    required this.timers,
  });

  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'title': title,
      'instructions': instructions,
      'notes': notes,
      'pictures': pictures.map((p) => p.toMap()).toList(),
      'videoSegment': videoSegment?.toMap(),
      'timers': timers.map((t) => t.toMap()).toList(),
    };
  }

  factory RecipeStep.fromMap(Map<String, dynamic> map) {
    return RecipeStep(
      stepNumber: map['stepNumber'] ?? 0,
      title: map['title'] ?? '',
      instructions: map['instructions'] ?? '',
      notes: map['notes'] ?? '',
      pictures:
          (map['pictures'] as List<dynamic>?)
              ?.map((p) => StepPicture.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      videoSegment: map['videoSegment'] != null
          ? VideoSegment.fromMap(map['videoSegment'] as Map<String, dynamic>)
          : null,
      timers:
          (map['timers'] as List<dynamic>?)
              ?.map((t) => StepTimer.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class StepPicture {
  final String url;
  final String caption;

  StepPicture({required this.url, required this.caption});

  Map<String, dynamic> toMap() => {'url': url, 'caption': caption};

  factory StepPicture.fromMap(Map<String, dynamic> map) {
    return StepPicture(url: map['url'] ?? '', caption: map['caption'] ?? '');
  }
}

class VideoSegment {
  final String url;
  final int startTimeSeconds;
  final int endTimeSeconds;

  VideoSegment({
    required this.url,
    required this.startTimeSeconds,
    required this.endTimeSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'startTimeSeconds': startTimeSeconds,
      'endTimeSeconds': endTimeSeconds,
    };
  }

  factory VideoSegment.fromMap(Map<String, dynamic> map) {
    return VideoSegment(
      url: map['url'] ?? '',
      startTimeSeconds: map['startTimeSeconds'] ?? 0,
      endTimeSeconds: map['endTimeSeconds'] ?? 0,
    );
  }
}

class StepTimer {
  final String name;
  final int durationSeconds;

  StepTimer({required this.name, required this.durationSeconds});

  Map<String, dynamic> toMap() => {
    'name': name,
    'durationSeconds': durationSeconds,
  };

  factory StepTimer.fromMap(Map<String, dynamic> map) {
    return StepTimer(
      name: map['name'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
    );
  }
}
