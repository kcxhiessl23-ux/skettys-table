import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_model.dart';
import 'media_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save recipe
  Future<void> saveRecipe(Recipe recipe) async {
    await _db.collection('recipes').doc(recipe.id).set(recipe.toMap());
  }

  // Load all recipes
  Future<List<Recipe>> loadRecipes() async {
    final snapshot = await _db.collection('recipes').get();
    final recipes = snapshot.docs
        .map((doc) => Recipe.fromMap(doc.data()))
        .toList();
    // Sort in memory instead of Firestore
    recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return recipes;
  }

  // Load single recipe
  Future<Recipe?> loadRecipe(String recipeId) async {
    final doc = await _db.collection('recipes').doc(recipeId).get();
    if (!doc.exists) return null;
    return Recipe.fromMap(doc.data()!);
  }

  // Delete recipe
  Future<void> deleteRecipe(String recipeId) async {
    await _db.collection('recipes').doc(recipeId).delete();
  }

  // Media library methods
  Future<void> saveMedia(MediaItem media) async {
    await _db.collection('mediaLibrary').doc(media.id).set(media.toMap());
  }

  Future<List<MediaItem>> loadAllMedia() async {
    final snapshot = await _db.collection('mediaLibrary').get();
    final items = snapshot.docs
        .map((doc) => MediaItem.fromMap(doc.data()))
        .toList();
    items.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return items;
  }

  Future<List<MediaItem>> searchMedia(String query) async {
    final snapshot = await _db.collection('mediaLibrary').get();
    final items = snapshot.docs
        .map((doc) => MediaItem.fromMap(doc.data()))
        .toList();

    return items.where((item) {
      final lowerQuery = query.toLowerCase();
      return item.name.toLowerCase().contains(lowerQuery) ||
          item.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  Future<void> deleteMedia(String mediaId) async {
    await _db.collection('mediaLibrary').doc(mediaId).delete();
  }
}
