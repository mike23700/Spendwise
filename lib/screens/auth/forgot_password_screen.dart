import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;

  static const Color primaryColor = Color(0xFF2D6A4F);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar("Veuillez entrer votre email", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final (success, error) = await _authService.resetPassword(
        email: _emailController.text.trim(),
      );

      if (!success) {
        _showSnackBar(
          error ?? "Erreur lors de la réinitialisation",
          Colors.red,
        );
        return;
      }

      setState(() => _emailSent = true);
      _showSnackBar(
        "Email de réinitialisation envoyé avec succès",
        Colors.green,
      );
    } catch (e) {
      _showSnackBar("Une erreur est survenue: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _emailSent ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Réinitialiser votre mot de passe",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          "Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 40),
        _buildInput(),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleResetPassword,
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
                    "Envoyer le lien de réinitialisation",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.green.shade100,
          child: const Icon(
            LucideIcons.checkCircle2,
            size: 50,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          "Email envoyé !",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          "Vérifiez votre boîte email à ${_emailController.text}",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Text(
            "💡 Conseil: Vérifiez également votre dossier spam ou indésirables si vous ne trouvez pas l'email.",
            style: TextStyle(fontSize: 14, color: Colors.blue),
          ),
        ),
        const SizedBox(height: 40),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text(
            "Retour à la connexion",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Email", style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          decoration: InputDecoration(
            prefixIcon: const Icon(LucideIcons.mail, size: 20),
            hintText: "Entrez votre email pour réinitialiser",
            filled: true,
            fillColor: const Color(0xFFF6F6F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
