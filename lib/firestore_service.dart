import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save recipe
  Future<void> saveRecipe(Recipe recipe) async {
    await _db.collection('recipes').doc(recipe.id).set(recipe.toMap());
  }

  // Load all recipes
  Future<List<Recipe>> loadRecipes() async {
    final snapshot = await _db
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Recipe.fromMap(doc.data())).toList();
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
}
