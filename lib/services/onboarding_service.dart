import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Marquer le onboarding comme complété
  Future<(bool success, String? error)> completeOnboarding() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return (false, 'Utilisateur non authentifié');
    }

    try {
      await _supabase
          .from('profiles')
          .update({'onboarding_done': true})
          .eq('id', user.id);

      debugPrint('✅ Onboarding complété pour ${user.id}');
      return (true, null);
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour du onboarding: $e');
      return (false, 'Erreur lors de la mise à jour');
    }
  }

  /// Vérifier si le onboarding est complété
  Future<(bool? isCompleted, String? error)> isOnboardingCompleted() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return (null, 'Utilisateur non authentifié');
    }

    try {
      final data =
          await _supabase
              .from('profiles')
              .select('onboarding_done')
              .eq('id', user.id)
              .single();

      return (data['onboarding_done'] as bool? ?? false, null);
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification du onboarding: $e');
      return (null, 'Erreur lors de la vérification');
    }
  }

  /// Obtenir le profil de l'utilisateur
  Future<(Map<String, dynamic>? profile, String? error)>
  getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return (null, 'Utilisateur non authentifié');
    }

    try {
      final data =
          await _supabase.from('profiles').select().eq('id', user.id).single();

      return (Map<String, dynamic>.from(data), null);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du profil: $e');
      return (null, 'Erreur lors de la récupération');
    }
  }
}
