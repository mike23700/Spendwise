import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: const [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 72,
                    color: Color(0xFF2D6A4F),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "wiseNkap",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Color(0xFF2D6A4F),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Prenez le contrôle de vos finances intelligemment",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),

              // =========================
              // CENTRE : Illustration
              // =========================
              Image.asset(
                'assets/wiseNkap.png',
                height: 260,
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) => Container(
                      height: 220,
                      width: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 96,
                        color: Colors.grey,
                      ),
                    ),
              ),

              // =========================
              // BAS : Actions
              // =========================
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => context.push('/register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      minimumSize: const Size(double.infinity, 56),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Créer un compte",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  OutlinedButton(
                    onPressed: () => context.push('/login'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(
                        color: Color(0xFF2D6A4F),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "J'ai déjà un compte",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D6A4F),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Simple • Sécurisé • Intelligent",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
