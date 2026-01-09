import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String get url => _getEnv('SUPABASE_URL');
  static String get anonKey => _getEnv('SUPABASE_ANON_KEY');

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
    } catch (e) {
      // En cas d'erreur critique d'init, on bloque l'app proprement
      runApp(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                'Erreur d’initialisation de l’application',
                style: TextStyle(fontSize: 18, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
      rethrow;
    }
  }

  static String _getEnv(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Variable d’environnement manquante : $key');
    }
    return value;
  }
}
