import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/user_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const Color primaryColor = Color(0xFF2D6A4F);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _validateInputs() {
    // Vérifier que les champs ne sont pas vides
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _nomController.text.isEmpty ||
        _prenomController.text.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs", Colors.orange);
      return false;
    }

    // Vérifier que l'email est valide
    if (!_isValidEmail(_emailController.text.trim())) {
      _showSnackBar("Veuillez entrer un email valide", Colors.orange);
      return false;
    }

    // Vérifier que le mot de passe contient au moins 6 caractères
    if (_passwordController.text.length < 6) {
      _showSnackBar(
        "Le mot de passe doit contenir au moins 6 caractères",
        Colors.orange,
      );
      return false;
    }

    // Vérifier que les mots de passe correspondent
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("Les mots de passe ne correspondent pas", Colors.orange);
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleSignUp() async {
    // Valider les inputs
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final success = await userProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
      );

      if (!success) {
        _showSnackBar(
          "Cet email est déjà utilisé ou inscription échouée",
          Colors.red,
        );
        return;
      }

      if (mounted) {
        _showSnackBar("Compte créé avec succès 🎉", Colors.green);

        // Rediriger vers la page home après inscription
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      _showSnackBar("Erreur: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Créer un Compte",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Rejoignez wiseNkap et gérez votre budget en toute sécurité",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            _buildInput(
              "Nom",
              _nomController,
              LucideIcons.user,
              hintText: "Ex: Kenmogne",
            ),
            _buildInput(
              "Prénom",
              _prenomController,
              LucideIcons.user,
              hintText: "Ex: ange",
            ),
            _buildInput(
              "Email",
              _emailController,
              LucideIcons.mail,
              keyboardType: TextInputType.emailAddress,
              hintText: "votre.email@example.com",
            ),
            _buildPasswordInput(
              "Mot de passe",
              _passwordController,
              _obscurePassword,
              (newValue) => setState(() => _obscurePassword = newValue),
              hintText: "Minimum 6 caractères",
            ),
            _buildPasswordInput(
              "Confirmer le mot de passe",
              _confirmPasswordController,
              _obscureConfirmPassword,
              (newValue) => setState(() => _obscureConfirmPassword = newValue),
              hintText: "Répétez votre mot de passe",
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        "S'inscrire",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Vous avez déjà un compte? "),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    "Se connecter",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: !_isLoading,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFF6F6F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPasswordInput(
    String label,
    TextEditingController controller,
    bool obscureText,
    Function(bool) onToggleVisibility, {
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          enabled: !_isLoading,
          decoration: InputDecoration(
            prefixIcon: const Icon(LucideIcons.lock, size: 20),
            hintText: hintText,
            suffixIcon: IconButton(
              icon: Icon(obscureText ? LucideIcons.eye : LucideIcons.eyeOff),
              onPressed: () => onToggleVisibility(!obscureText),
            ),
            filled: true,
            fillColor: const Color(0xFFF6F6F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
