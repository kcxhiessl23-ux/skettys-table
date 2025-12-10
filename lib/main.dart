import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'create_recipe_screen.dart';
import 'cook_mode_screen.dart';
import 'firestore_service.dart';
import 'recipe_model.dart';
import 'media_model.dart';
import 'upload_media_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'ai_recipe_screen.dart';
import 'nonna_chat_dialog.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'recipes_page.dart';
import 'media_search_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "lib/.env");
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
  List<MediaItem> _media = [];
  bool _isLoading = true;
  Recipe? _recipeOfTheDay;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _recipes = await _firestoreService.loadRecipes();
    _media = await _firestoreService.loadAllMedia();
    _pickRecipeOfTheDay();
    setState(() => _isLoading = false);
  }

  void _pickRecipeOfTheDay() {
    if (_recipes.isNotEmpty) {
      final shuffled = List<Recipe>.from(_recipes)..shuffle();
      _recipeOfTheDay = shuffled.first;
    }
  }

  void _refreshRecipeOfTheDay() {
    setState(() {
      _pickRecipeOfTheDay();
    });
  }

  void _showNonnaChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const NonnaChatDialog();
      },
    );
  }

  List<dynamic> get _recentlyUploaded {
    final List<dynamic> combined = [..._recipes, ..._media];
    combined.sort((a, b) {
      final aDate = a is Recipe ? a.createdAt : (a as MediaItem).uploadedAt;
      final bDate = b is Recipe ? b.createdAt : (b as MediaItem).uploadedAt;
      return bDate.compareTo(aDate);
    });
    return combined.take(12).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Macy background image
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.75,
                    child: Image.asset(
                      'assets/images/macy_logo_floor.png',
                      width: MediaQuery.of(context).size.width * 0.75,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Main content (your existing RefreshIndicator)
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    'https://picsum.photos/100',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Sketty's Table",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Georgia',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Recipe of the Day
                      if (_recipeOfTheDay != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quick Actions (Now on the LEFT)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Title and Refresh button (Aligned to the right of this column)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Text(
                                          "Macy's Pick of the Day",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.refresh,
                                            color: Color(0xFF8B4513),
                                          ),
                                          onPressed: _refreshRecipeOfTheDay,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Three simple, clickable containers (cards) with equal height
                                    Row(
                                      children: [
                                        // Photo Button/Card
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const UploadMediaScreen(
                                                        mediaType: 'photo',
                                                      ),
                                                ),
                                              );
                                              if (result == true) _loadData();
                                            },
                                            child: Container(
                                              height: 60, // Fixed height
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade300,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.add_photo_alternate,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Photo',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Video Button/Card
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const UploadMediaScreen(
                                                        mediaType: 'video',
                                                      ),
                                                ),
                                              );
                                              if (result == true) _loadData();
                                            },
                                            child: Container(
                                              height: 60, // Fixed height
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade300,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.videocam,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Video',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Search Button/Card
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () async {
                                              final result =
                                                  await showDialog<MediaItem>(
                                                    context: context,
                                                    builder: (_) =>
                                                        const MediaSearchOverlay(),
                                                  );

                                              if (result != null) {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) => Dialog(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (result.type ==
                                                            'video')
                                                          const Icon(
                                                            Icons.videocam,
                                                            size: 100,
                                                          )
                                                        else
                                                          Image.network(
                                                            result.url,
                                                            fit: BoxFit.contain,
                                                          ),
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        Text(
                                                          result.name,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 18,
                                                              ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                              ),
                                                          child: const Text(
                                                            'Close',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Container(
                                              height: 60, // Fixed height
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade400,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.search,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Search',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ), // Spacing between actions and recipe
                              // Recipe of the Day Card (Now on the RIGHT)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CookModeScreen(
                                        recipe: _recipeOfTheDay!,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 200,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        _recipeOfTheDay!.coverImageUrl,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.center,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.9),
                                        ],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    alignment: Alignment.bottomLeft,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _recipeOfTheDay!.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _recipeOfTheDay!.category,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Recently Uploaded
                      if (_recentlyUploaded.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Recent Uploads',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 180,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _recentlyUploaded.length,
                                itemBuilder: (context, index) {
                                  final item = _recentlyUploaded[index];

                                  if (item is Recipe) {
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CookModeScreen(recipe: item),
                                          ),
                                        );
                                      },
                                      child: _buildRecentCard(
                                        item.coverImageUrl,
                                        item.name,
                                        item.category,
                                        Icons.restaurant_menu,
                                      ),
                                    );
                                  } else {
                                    final media = item as MediaItem;
                                    return _buildRecentCard(
                                      media.url,
                                      media.name,
                                      media.type,
                                      media.type == 'video'
                                          ? Icons.play_circle
                                          : Icons.photo,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      const SizedBox(height: 10), // Space for bottom nav
                    ],
                  ),
                ),
              ],
            ),

      // Floating Action Button (Nonna Chat)
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showNonnaChat(context), // <-- Calls the function above
        backgroundColor: Colors.red[300],
        // Use a child icon or image. Assuming 'assets/nonna_dog.jpg' is your image.
        child: const CircleAvatar(
          radius: 28,
          backgroundImage: AssetImage('assets/images/nonna_dog.jpg'),
        ),
      ),
      // Position it in the bottom-right corner
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8B4513),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Shopping',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Cook'),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
            ).then((_) => _loadData());
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecipesPage()),
            );
          } else if (index == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Shopping list coming soon')),
            );
          } else if (index == 4) {
            if (_recipes.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CookModeScreen(recipe: _recipes.first),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildRecentCard(
    String imageUrl,
    String name,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const Spacer(),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
