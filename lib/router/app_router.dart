import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile_screen.dart';

GoRouter appRouter(BuildContext context) {
  final userProvider = context.watch<UserProvider>();

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: userProvider,
    redirect: (context, state) {
      if (userProvider.isLoading) return null;

      final isAuth = userProvider.isAuthenticated;
      final hasOnboarding = userProvider.hasCompletedOnboarding;
      final location = state.matchedLocation;

      // 1️⃣ ONBOARDING (non authentifié et onboarding non complété)
      if (!hasOnboarding && !isAuth) {
        return location == '/onboarding' ? null : '/onboarding';
      }

      // 2️⃣ NON CONNECTÉ (onboarding complété mais pas authentifié)
      if (!isAuth && hasOnboarding) {
        if (location == '/login' ||
            location == '/register' ||
            location == '/welcome' ||
            location == '/forgot-password') {
          return null;
        }
        return '/welcome';
      }

      // 3️⃣ CONNECTÉ (authentifié)
      // Si sur une page d'auth, rediriger vers home
      if (isAuth &&
          (location == '/welcome' ||
              location == '/login' ||
              location == '/register' ||
              location == '/forgot-password' ||
              location == '/onboarding')) {
        return '/home';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
}
