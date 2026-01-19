import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  static const Color primaryColor = Color(0xFF2D6A4F);

  final List<String> _budgetTips = [
    "Épargnez au moins 10 % de vos revenus chaque mois.",
    "Notez toutes vos dépenses, même les plus petites.",
    "Évitez les dépenses impulsives.",
    "Analysez votre budget chaque fin de mois.",
  ];

  late final String _budgetTip;

  bool get _isFormValid =>
      _identifierController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _budgetTip = (_budgetTips..shuffle()).first;
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================
  // 🔐 CONNEXION
  // ============================
  Future<void> _handleLogin() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      final email = _identifierController.text.trim();
      debugPrint('🔑 Tentative connexion: $email, Se souvenir: $_rememberMe');

      final userProvider = context.read<UserProvider>();
      final success = await userProvider.login(
        email: email,
        password: _passwordController.text.trim(),
      );

      if (!success) {
        debugPrint('❌ Échec authentification');
        _showSnackBar("Email ou mot de passe incorrect", Colors.red);
        return;
      }

      debugPrint('✅ Authentification réussie');

      // Sauvegarder les préférences si "Se souvenir de moi" est activé
      if (_rememberMe) {
        debugPrint('💾 Sauvegarde des identifiants...');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', email);
        debugPrint('✅ Email sauvegardé');
      } else {
        // Effacer les identifiants sauvegardés
        debugPrint('🗑️ Suppression des identifiants sauvegardés');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_email');
        debugPrint('✅ Identifiants supprimés');
      }

      if (!mounted) return;

      _showSnackBar("Bienvenue à wiseNkap 🎉", Colors.green);
      debugPrint('🚀 Navigation vers /home');

      // ✅ NAVIGATION GoRouter
      context.go('/home');
    } on Exception catch (e) {
      final msg =
          e.toString().toLowerCase().contains('network')
              ? "Problème de connexion Internet"
              : "Une erreur est survenue";

      debugPrint('❌ EXCEPTION: $e');
      _showSnackBar(msg, Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedEmail() async {
    debugPrint('📥 Chargement des identifiants sauvegardés...');
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');

    if (savedEmail != null && savedEmail.isNotEmpty) {
      debugPrint('✅ Email trouvé: $savedEmail');
      setState(() {
        _identifierController.text = savedEmail;
        _rememberMe = true;
      });
    } else {
      debugPrint('⚠️ Aucun email sauvegardé');
    }
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

  // ============================
  // 🖼️ UI
  // ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            Center(
              child: Image.asset(
                'assets/avatar.png',
                height: 90,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.account_balance_wallet,
                      size: 80,
                      color: primaryColor,
                    ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Connexion à wiseNkap",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),
            const Text(
              "Accédez à votre espace de gestion budgétaire",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 16),
            _buildBudgetTip(),
            const SizedBox(height: 32),

            _buildInput(
              label: "Email",
              controller: _identifierController,
              icon: LucideIcons.mail,
              keyboardType: TextInputType.emailAddress,
              hintText: "votre.email@example.com",
            ),

            _buildInput(
              label: "Mot de passe",
              controller: _passwordController,
              icon: LucideIcons.lock,
              isPassword: true,
              hintText: "Entrez votre mot de passe",
            ),

            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                ),
                const Text("Se souvenir de moi"),
              ],
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text("Mot de passe oublié ?"),
              ),
            ),

            const SizedBox(height: 16),

            _buildSecurityIndicator(),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                      : const Text(
                        "Se connecter",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
            ),

            const SizedBox(height: 24),

            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text(
                "Créer un compte",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================
  // 🔧 Widgets
  // ============================
  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword ? _obscurePassword : false,
          onChanged: (_) => setState(() {}),
          enabled: !_isLoading,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: hintText,
            suffixIcon:
                isPassword
                    ? IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                      ),
                      onPressed:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    )
                    : null,
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

  Widget _buildSecurityIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.lock, size: 18, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(
            "Connexion sécurisée",
            style: TextStyle(
              fontSize: 13,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F5EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: primaryColor,
            child: Icon(LucideIcons.piggyBank, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(_budgetTip)),
        ],
      ),
    );
  }
}
