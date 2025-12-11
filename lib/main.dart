import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'create_recipe_screen.dart';
import 'cook_mode_screen.dart';
import 'firestore_service.dart';
import 'recipe_model.dart';
import 'media_model.dart';
import 'upload_media_screen.dart';
import 'nonna_chat_dialog.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'recipes_page.dart';
import 'media_search_overlay.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'splash_screen.dart';

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
        scaffoldBackgroundColor: const Color(0xFFD4B896), // brick tan color
        fontFamily: 'Georgia',
      ),
      home: const SplashScreen(),
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

  Widget _actionCard({
    required String asset,
    required String label,
    required Color color,
    required void Function() onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 140, // ← bigger
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// DOG ICON BIG AS FUCK NOW
              SvgPicture.asset(asset, width: 90, height: 90),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Standard card (solid color or gradient)
  Widget _homeCard({
    required String label,
    required Widget child,
    required Color color,
    void Function()? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              child,
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card with a left/right gradient (for Search)
  Widget _homeCardGradient({
    required String label,
    required Color leftColor,
    required Color rightColor,
    void Function()? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [leftColor, rightColor],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Add simple icon here if desired
              SvgPicture.asset(
                '/images/icons/iconSearch.svg',
                width: 90,
                height: 90,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                      // ★★★ New Modern Layout (Macy Cards + Pick of Day) ★★★
                      // AppBar-like header (small picture + large title)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
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
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundImage: AssetImage(
                                'assets/images/icons/macy template.png',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Sketty's Table",
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Main card row (five equal cards)
                      Row(
                        children: [
                          // Mystery / AI suggestion card
                          _homeCard(
                            label: "Surprise",
                            color: const Color(0xFFF5CBA7),
                            onTap: () {
                              _showNonnaChat(
                                context,
                              ); // Opens Macinna with random suggestion prompt
                            },
                            child: Image.asset(
                              'assets/images/icons/macy template.png',
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),

                          // Photo upload card
                          _homeCard(
                            label: "Photo",
                            color: const Color(0xFFFFD59A),
                            onTap: () => _openUploader('photo'),
                            child: SvgPicture.asset(
                              'assets/images/icons/iconPhoto.svg',
                              height: 100,
                            ),
                          ),

                          // Video upload card
                          _homeCard(
                            label: "Video",
                            color: const Color(0xFFABEBC6),
                            onTap: () => _openUploader('video'),
                            child: SvgPicture.asset(
                              'assets/images/icons/iconVideo.svg',
                              height: 100,
                            ),
                          ),

                          // Search card with gradient indicating photo/video
                          _homeCardGradient(
                            label: "Search",
                            leftColor: const Color(0xFFFFE0B2), // photo tone
                            rightColor: const Color(0xFFD1F2EB), // video tone
                            onTap: _openSearch,
                          ),
                          // Macy's Pick of the Day card
                          if (_recipeOfTheDay != null)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CookModeScreen(
                                      recipe: _recipeOfTheDay!,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  height: 180,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        _recipeOfTheDay!.coverImageUrl,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Macy icon in top-right corner
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.white,
                                          backgroundImage: AssetImage(
                                            'assets/images/icons/macy template.png',
                                          ),
                                        ),
                                      ),
                                      // Recipe name at bottom
                                      Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                const BorderRadius.only(
                                                  bottomLeft: Radius.circular(
                                                    18,
                                                  ),
                                                  bottomRight: Radius.circular(
                                                    18,
                                                  ),
                                                ),
                                          ),
                                          child: Text(
                                            _recipeOfTheDay!.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Recently added section, overlaps background slightly
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: const Text(
                          "Recent Uploads",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _recentlyUploaded.length,
                          itemBuilder: (_, i) {
                            final item = _recentlyUploaded[i];
                            final isRecipe = item is Recipe;
                            final img = isRecipe
                                ? item.coverImageUrl
                                : (item as MediaItem).url;

                            return GestureDetector(
                              onTap: () {
                                if (isRecipe) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CookModeScreen(recipe: item),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 150,
                                margin: const EdgeInsets.only(right: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  image: DecorationImage(
                                    image: NetworkImage(img),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  alignment: Alignment.bottomLeft,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.75),
                                      ],
                                    ),
                                  ),
                                  child: Text(
                                    isRecipe ? item.name : item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

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

  // ==========================
  // REQUIRED HELPERS FOR CARDS
  // ==========================
  void _openUploader(String mediaType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadMediaScreen(mediaType: mediaType),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _openSearch() async {
    final result = await showDialog<MediaItem>(
      context: context,
      builder: (_) => const MediaSearchOverlay(),
    );

    if (result != null) {
      // later you can open viewer or details here if needed
    }
  }
}
