import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Ajouter une transaction
  Future<(bool success, String? error)> addTransaction({
    required double montant,
    required String type, // 'revenu' ou 'depense'
    required String categorieId,
    required DateTime date,
    required String description,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return (false, 'Utilisateur non authentifié');
    }

    try {
      // Validation des données
      if (montant <= 0) {
        return (false, 'Le montant doit être supérieur à 0');
      }

      if (type != 'revenu' && type != 'depense') {
        return (false, 'Type invalide');
      }

      final transactionData = {
        'user_id': user.id,
        'montant': montant,
        'type': type,
        'categorie_id': categorieId,
        'date': date.toIso8601String().split('T')[0], // Format: YYYY-MM-DD
        'description': description.trim().isEmpty ? null : description.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      debugPrint('📝 Ajout transaction: $transactionData');

      await _supabase.from('transactions').insert(transactionData);

      debugPrint('✅ Transaction ajoutée avec succès');
      return (true, null);
    } on PostgrestException catch (e) {
      debugPrint('❌ Erreur Postgrest: ${e.message}');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Détails: ${e.details}');
      return (false, e.message);
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      return (false, 'Une erreur est survenue');
    }
  }

  /// Récupérer les transactions
  Future<(List<Map<String, dynamic>> transactions, String? error)>
  getTransactions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return (<Map<String, dynamic>>[], null);
    }

    try {
      final data = await _supabase
          .from('transactions')
          .select('*, categories(id, nom, emoji, type)')
          .eq('user_id', user.id)
          .order('date', ascending: false);

      return (List<Map<String, dynamic>>.from(data), null);
    } catch (e) {
      debugPrint('Erreur lors du chargement des transactions: $e');
      return (<Map<String, dynamic>>[], 'Erreur lors du chargement');
    }
  }

  /// Supprimer une transaction
  Future<(bool success, String? error)> deleteTransaction(
    String transactionId,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return (false, 'Utilisateur non authentifié');
    }

    try {
      await _supabase
          .from('transactions')
          .delete()
          .eq('id', transactionId)
          .eq('user_id', user.id);

      return (true, null);
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
      return (false, 'Erreur lors de la suppression');
    }
  }
}
