import 'package:wiseNkap/models/category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class CategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Récupérer toutes les catégories
  Future<List<Category>> getCategories({String? type}) async {
    try {
      var query = _supabase
          .from('categories')
          .select()
          .or('user_id.eq.${_supabase.auth.currentUser?.id},user_id.is.null');

      if (type != null) {
        query = query.eq('type', type);
      }

      final response = await query.order('nom');

      return (response as List).map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      developer.log('Erreur lors de la récupération des catégories: $e');
      rethrow;
    }
  }

  // Ajouter une nouvelle catégorie
  Future<Category> addCategory(Category category) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final response =
          await _supabase
              .from('categories')
              .insert({
                'nom': category.name,
                'type': category.type,
                'emoji': category.emoji,
                'user_id': userId,
              })
              .select()
              .single();

      return Category.fromJson(response);
    } catch (e) {
      developer.log('Erreur lors de l\'ajout de la catégorie: $e');
      rethrow;
    }
  }
}
