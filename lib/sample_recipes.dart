import 'recipe_model.dart';

class SampleRecipes {
  /// Helper to parse "Name | Amount | Unit" strings into Ingredient objects
  static Ingredient _parseIngredient(String ingStr) {
    final parts = ingStr.split('|').map((e) => e.trim()).toList();
    final name = parts.isNotEmpty ? parts[0] : '';
    final quantity = parts.length > 1
        ? double.tryParse(parts[1].replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0
        : 0.0;
    final unit = parts.length > 2 ? parts[2] : '';

    return Ingredient(
      name: name,
      quantity: quantity,
      unit: unit,
      rawText: ingStr,
    );
  }

  /// Helper to build ingredientList from all step ingredients
  static List<Ingredient> _buildIngredientList(List<RecipeStep> steps) {
    final List<Ingredient> result = [];
    for (var step in steps) {
      for (var ing in step.stepIngredients) {
        result.add(_parseIngredient(ing));
      }
    }
    return result;
  }

  static List<Recipe> getSampleRecipes() {
    // Define steps first so we can build ingredientList from them
    final lasagnaSteps = [
      RecipeStep(
        stepNumber: 1,
        title: 'Make the Meat Sauce',
        instructions:
            'Heat olive oil in a large pot over medium heat. Add ground beef and Italian sausage, breaking up with a wooden spoon. Cook until browned, about 8-10 minutes. Add diced onion and minced garlic, cook until softened. Stir in crushed tomatoes, tomato paste, basil, oregano, salt, and pepper. Simmer for 30 minutes, stirring occasionally.',
        notes: 'The longer you simmer, the better the flavor develops.',
        pictures: [],
        timers: [StepTimer(name: 'Simmer sauce', durationSeconds: 1800)],
        stepIngredients: [
          'Ground Beef | 1 | lb',
          'Italian Sausage | 1 | lb',
          'Onion | 1 | large',
          'Garlic | 4 | cloves',
          'Crushed Tomatoes | 2 | 28oz cans',
          'Tomato Paste | 2 | tbsp',
          'Olive Oil | 2 | tbsp',
          'Dried Basil | 2 | tsp',
          'Dried Oregano | 2 | tsp',
        ],
      ),
      RecipeStep(
        stepNumber: 2,
        title: 'Prepare Béchamel Sauce',
        instructions:
            'In a medium saucepan, melt butter over medium heat. Whisk in flour and cook for 2 minutes until golden. Gradually whisk in milk, stirring constantly to prevent lumps. Cook until thickened, about 5-7 minutes. Season with salt and pepper.',
        notes: 'Keep whisking to avoid lumps!',
        pictures: [],
        timers: [StepTimer(name: 'Thicken sauce', durationSeconds: 420)],
        stepIngredients: [
          'Butter | 4 | tbsp',
          'All-Purpose Flour | 4 | tbsp',
          'Milk | 3 | cups',
        ],
      ),
      RecipeStep(
        stepNumber: 3,
        title: 'Cook Lasagna Noodles',
        instructions:
            'Bring a large pot of salted water to a boil. Cook lasagna noodles according to package directions until al dente. Drain and lay flat on a clean kitchen towel to prevent sticking.',
        notes: 'Don\'t overcook - they\'ll cook more in the oven.',
        pictures: [],
        timers: [StepTimer(name: 'Boil noodles', durationSeconds: 600)],
        stepIngredients: ['Lasagna Noodles | 1 | lb'],
      ),
      RecipeStep(
        stepNumber: 4,
        title: 'Prepare Cheese Mixture',
        instructions:
            'In a bowl, combine ricotta cheese, 1 cup mozzarella, 1/2 cup parmesan, and eggs. Mix until smooth. Season with salt and pepper.',
        notes: 'This creates the creamy layer between the noodles.',
        pictures: [],
        timers: [],
        stepIngredients: [
          'Ricotta Cheese | 2 | cups',
          'Mozzarella Cheese | 1 | cup',
          'Parmesan Cheese | 0.5 | cup',
          'Eggs | 2 | large',
        ],
      ),
      RecipeStep(
        stepNumber: 5,
        title: 'Assemble Lasagna',
        instructions:
            'Preheat oven to 375°F. Spread 1 cup meat sauce in bottom of 9x13 baking dish. Layer: noodles, ricotta mixture, meat sauce, béchamel, mozzarella. Repeat layers 2-3 times. Top with remaining mozzarella and parmesan.',
        notes: 'Make sure each layer is even for consistent cooking.',
        pictures: [],
        timers: [],
        stepIngredients: [
          'Mozzarella Cheese | 3 | cups',
          'Parmesan Cheese | 0.5 | cup',
        ],
      ),
      RecipeStep(
        stepNumber: 6,
        title: 'Bake',
        instructions:
            'Cover with foil and bake for 45 minutes. Remove foil and bake additional 15 minutes until cheese is golden and bubbly. Let rest 15 minutes before serving.',
        notes: 'The rest time is crucial for clean slices!',
        pictures: [],
        timers: [
          StepTimer(name: 'Bake covered', durationSeconds: 2700),
          StepTimer(name: 'Bake uncovered', durationSeconds: 900),
          StepTimer(name: 'Rest', durationSeconds: 900),
        ],
        stepIngredients: [],
      ),
    ];

    final stockSteps = [
      RecipeStep(
        stepNumber: 1,
        title: 'Prepare Ingredients',
        instructions:
            'Roughly chop onions, carrots, and celery into 2-inch pieces. Halve the garlic head crosswise. No need to peel anything.',
        notes: 'Large pieces are fine - we\'ll strain everything later.',
        pictures: [],
        timers: [],
        stepIngredients: [
          'Onion | 2 | large',
          'Carrots | 3 | large',
          'Celery | 4 | stalks',
          'Garlic | 1 | head',
        ],
      ),
      RecipeStep(
        stepNumber: 2,
        title: 'Start Stock',
        instructions:
            'Place chicken carcass and wings in a large stockpot. Add vegetables, herbs, and peppercorns. Cover with cold water by 2 inches. Bring to a boil over high heat, then reduce to a gentle simmer.',
        notes: 'Starting with cold water extracts maximum flavor.',
        pictures: [],
        timers: [],
        stepIngredients: [
          'Chicken Carcass | 1 | whole',
          'Chicken Wings | 2 | lbs',
          'Bay Leaves | 2 | leaves',
          'Peppercorns | 1 | tbsp',
          'Fresh Thyme | 4 | sprigs',
          'Fresh Parsley | 1 | bunch',
          'Water | 4 | quarts',
        ],
      ),
      RecipeStep(
        stepNumber: 3,
        title: 'Simmer',
        instructions:
            'Maintain a gentle simmer for 4 hours, skimming off any foam that rises to the surface. Add more water if level drops below ingredients.',
        notes: 'Don\'t let it boil - gentle simmer keeps the stock clear.',
        pictures: [],
        timers: [StepTimer(name: 'Simmer stock', durationSeconds: 14400)],
        stepIngredients: [],
      ),
      RecipeStep(
        stepNumber: 4,
        title: 'Strain and Cool',
        instructions:
            'Strain stock through a fine mesh strainer into a large bowl. Discard solids. Let cool to room temperature, then refrigerate overnight. Fat will solidify on top - remove and discard before using.',
        notes: 'Stock should be gelatinous when cold - that\'s the good stuff!',
        pictures: [],
        timers: [],
        stepIngredients: [],
      ),
    ];

    final tiramisuSteps = [
      RecipeStep(
        stepNumber: 1,
        title: 'Make Mascarpone Cream',
        instructions:
            'Whisk egg yolks and sugar in a bowl over simmering water until pale and thick, about 5 minutes. Remove from heat and whisk in mascarpone until smooth. In separate bowl, whip heavy cream to stiff peaks. Fold into mascarpone mixture.',
        notes: 'Don\'t scramble the eggs - keep whisking!',
        pictures: [],
        timers: [StepTimer(name: 'Whisk eggs', durationSeconds: 300)],
        stepIngredients: [
          'Egg Yolks | 6 | large',
          'Sugar | 0.75 | cup',
          'Mascarpone Cheese | 1.5 | lbs',
          'Heavy Cream | 1.5 | cups',
        ],
      ),
      RecipeStep(
        stepNumber: 2,
        title: 'Prepare Coffee',
        instructions:
            'Combine espresso and Kahlua in a shallow bowl. Let cool to room temperature.',
        notes: 'Can use strong brewed coffee instead of espresso.',
        pictures: [],
        timers: [],
        stepIngredients: ['Espresso | 2 | cups', 'Kahlua | 3 | tbsp'],
      ),
      RecipeStep(
        stepNumber: 3,
        title: 'Assemble',
        instructions:
            'Quickly dip each ladyfinger in coffee mixture (1 second per side) and arrange in single layer in 9x13 dish. Spread half the mascarpone cream over ladyfingers. Repeat with another layer of dipped ladyfingers and remaining cream.',
        notes: 'Don\'t oversoak - they\'ll get mushy!',
        pictures: [],
        timers: [],
        stepIngredients: ['Ladyfinger Cookies | 2 | packages'],
      ),
      RecipeStep(
        stepNumber: 4,
        title: 'Chill',
        instructions:
            'Dust top generously with cocoa powder. Cover and refrigerate at least 6 hours or overnight.',
        notes: 'Patience is key - it needs time for flavors to meld.',
        pictures: [],
        timers: [StepTimer(name: 'Chill', durationSeconds: 21600)],
        stepIngredients: ['Cocoa Powder | 2 | tbsp'],
      ),
    ];

    return [
      Recipe(
        id: 'sample_1',
        name: 'Nonna\'s Classic Lasagna',
        description:
            'A traditional Italian lasagna with layers of rich meat sauce, creamy béchamel, and melted cheese. Perfect for Sunday dinner with the family.',
        coverImageUrl: 'https://picsum.photos/seed/lasagna/800/600',
        category: 'Main Course',
        tags: ['Italian', 'Heavy', 'Party', 'Red Sauce'],
        equipment: ['Large pot', 'Deep baking dish', 'Whisk', 'Wooden spoon'],
        ingredients: [
          'Ground Beef | 1 | lb',
          'Italian Sausage | 1 | lb',
          'Onion | 1 | large',
          'Garlic | 4 | cloves',
          'Crushed Tomatoes | 2 | 28oz cans',
          'Tomato Paste | 2 | tbsp',
          'Lasagna Noodles | 1 | lb',
          'Ricotta Cheese | 2 | cups',
          'Mozzarella Cheese | 4 | cups',
          'Parmesan Cheese | 1 | cup',
          'Eggs | 2 | large',
          'Butter | 4 | tbsp',
          'All-Purpose Flour | 4 | tbsp',
          'Milk | 3 | cups',
          'Olive Oil | 2 | tbsp',
          'Dried Basil | 2 | tsp',
          'Dried Oregano | 2 | tsp',
          'Salt | to taste',
          'Black Pepper | to taste',
          'Fresh Parsley | for garnish',
        ],
        ingredientList: _buildIngredientList(lasagnaSteps),
        prepTimeMinutes: 45,
        cookTimeMinutes: 90,
        servings: 12,
        difficulty: 'Medium',
        notes:
            'Can be made ahead and frozen. Let rest 15 minutes before cutting for cleaner slices.',
        steps: lasagnaSteps,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),

      Recipe(
        id: 'sample_2',
        name: 'Homemade Chicken Stock',
        description:
            'Rich, flavorful chicken stock made from scratch. Perfect base for soups, risottos, and sauces. Make a big batch and freeze for later.',
        coverImageUrl: 'https://picsum.photos/seed/stock/800/600',
        category: 'Soup',
        tags: ['Quick', 'Light'],
        equipment: [
          'Large stockpot',
          'Fine mesh strainer',
          'Storage containers',
        ],
        ingredients: [
          'Chicken Carcass | 1 | whole',
          'Chicken Wings | 2 | lbs',
          'Onion | 2 | large',
          'Carrots | 3 | large',
          'Celery | 4 | stalks',
          'Garlic | 1 | head',
          'Bay Leaves | 2 | leaves',
          'Peppercorns | 1 | tbsp',
          'Fresh Thyme | 4 | sprigs',
          'Fresh Parsley | 1 | bunch',
          'Water | 4 | quarts',
        ],
        ingredientList: _buildIngredientList(stockSteps),
        prepTimeMinutes: 20,
        cookTimeMinutes: 240,
        servings: 16,
        difficulty: 'Easy',
        notes:
            'Stock freezes beautifully for up to 6 months. Use ice cube trays for small portions.',
        steps: stockSteps,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),

      Recipe(
        id: 'sample_3',
        name: 'Tiramisu',
        description:
            'Classic Italian dessert with layers of coffee-soaked ladyfingers and mascarpone cream. No baking required!',
        coverImageUrl: 'https://picsum.photos/seed/tiramisu/800/600',
        category: 'Dessert',
        tags: ['Italian', 'Light', 'Party'],
        equipment: ['9x13 dish', 'Electric mixer', 'Shallow bowl'],
        ingredients: [
          'Egg Yolks | 6 | large',
          'Sugar | 0.75 | cup',
          'Mascarpone Cheese | 1.5 | lbs',
          'Heavy Cream | 1.5 | cups',
          'Espresso | 2 | cups',
          'Kahlua | 3 | tbsp',
          'Ladyfinger Cookies | 2 | packages',
          'Cocoa Powder | 2 | tbsp',
        ],
        ingredientList: _buildIngredientList(tiramisuSteps),
        prepTimeMinutes: 30,
        cookTimeMinutes: 0,
        servings: 12,
        difficulty: 'Medium',
        notes:
            'Must be refrigerated at least 6 hours, preferably overnight. Gets better after a day!',
        steps: tiramisuSteps,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
