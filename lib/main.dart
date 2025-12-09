import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'create_recipe_screen.dart';
import 'cook_mode_screen.dart';
import 'firestore_service.dart';
import 'recipe_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SkettysTableApp());
}

class SkettysTableApp extends StatelessWidget {
  const SkettysTableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Sketty's Table",
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFFFF8E7),
        fontFamily: 'Georgia',
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Navigation logic for viewing recipes (Go to Home Screen)
  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  // 2. Navigation logic for creating a new recipe
  void _goToCreateRecipe() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // Use a Column to stack the two buttons vertically
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Keep column size minimal
          children: [
            // BUTTON 1: Go To Home Screen (View Recipes)
            ElevatedButton(
              onPressed:
                  _goToHome, // Calls the function to navigate to HomeScreen
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
              ),
              child: const Text(
                'View All Recipes',
                style: TextStyle(fontSize: 18),
              ),
            ),

            const SizedBox(height: 20), // Spacing between buttons
            // BUTTON 2: Go To Create Recipe Screen
            ElevatedButton(
              onPressed:
                  _goToCreateRecipe, // Calls the function to navigate to CreateRecipeScreen
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
              ),
              child: const Text(
                'Create New Recipe',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes(); // ⬅️ This is the call that starts the loading process
  }

  Future<void> _loadRecipes() async {
    print('Loading recipes...');
    setState(() => _isLoading = true);
    try {
      // You may need to update this line with the date fix we discussed earlier
      _recipes = await _firestoreService.loadRecipes();
    } catch (e) {
      print('Error loading recipes: $e');
      // Set to empty list on failure to avoid showing previous state
      _recipes = [];
    }

    print('Loaded ${_recipes.length} recipes');
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // This is where your screen title goes
        title: const Text("Home Screen: Sketty's Table"),
        backgroundColor: const Color(0xFF8B4513),
      ),

      // The main content of the screen
      body: Column(
        children: [
          // Diagnostic Text at the top
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loading status: $_isLoading'),
                Text('Recipe count: ${_recipes.length}'),
              ],
            ),
          ),

          // The main content area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                // If not loading, check if recipes list is empty
                : _recipes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No recipes yet',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateRecipeScreen(),
                              ),
                            );
                            _loadRecipes();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 20,
                            ),
                          ),
                          child: const Text(
                            'Create First Recipe',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  )
                // If recipes are loaded and not empty, show the list
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recipes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              recipe.coverImageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            recipe.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${recipe.steps.length} steps • ${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CookModeScreen(recipe: recipe),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ], // Closes the Column children list
      ), // Closes the body widget

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
          );
          _loadRecipes();
        },
        backgroundColor: const Color(0xFF8B4513),
        child: const Icon(Icons.add),
      ),
    ); // Closes the Scaffold
  }
}
