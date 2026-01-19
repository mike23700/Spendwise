import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Connexion avec email et mot de passe
  Future<(bool success, String? error)> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        return (false, 'Connexion échouée');
      }

      return (true, null);
    } on AuthException catch (e) {
      debugPrint('Erreur authentification: ${e.message}');
      return (false, e.message);
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
      return (false, 'Une erreur est survenue');
    }
  }

  /// Inscription avec email, mot de passe et infos profil
  Future<(bool success, String? error)> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
  }) async {
    try {
      // 1️⃣ Créer l'utilisateur
      final authResponse = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'nom': nom.trim(), 'prenom': prenom.trim()},
      );

      if (authResponse.user == null) {
        return (false, 'Inscription échouée');
      }

      // 2️⃣ Créer le profil dans la BD
      final userId = authResponse.user!.id;
      await _supabase.from('profiles').insert({
        'id': userId,
        'email': email.trim(),
        'nom': nom.trim(),
        'prenom': prenom.trim(),
        'onboarding_done': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      return (true, null);
    } on AuthException catch (e) {
      debugPrint('Erreur d\'inscription: ${e.message}');
      return (false, e.message);
    } catch (e) {
      debugPrint('Erreur lors de la création du profil: $e');
      return (false, 'Erreur lors de la création du profil');
    }
  }

  /// Réinitialisation du mot de passe
  Future<(bool success, String? error)> resetPassword({
    required String email,
  }) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo:
            'io.supabase.flutter://reset-callback', // À adapter selon la config
      );
      return (true, null);
    } on AuthException catch (e) {
      debugPrint('Erreur réinitialisation: ${e.message}');
      return (false, e.message);
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
      return (false, 'Une erreur est survenue');
    }
  }

  /// Déconnexion
  Future<(bool success, String? error)> logout() async {
    try {
      await _supabase.auth.signOut();
      return (true, null);
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
      return (false, 'Erreur lors de la déconnexion');
    }
  }

  /// Vérifier si l'utilisateur est authentifié
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Obtenir l'utilisateur actuel
  User? get currentUser => _supabase.auth.currentUser;

  /// Obtenir l'email de l'utilisateur
  String? get userEmail => _supabase.auth.currentUser?.email;

  /// Écouter les changements d'authentification
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
