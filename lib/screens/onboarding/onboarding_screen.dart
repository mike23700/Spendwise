import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/user_provider.dart';
import 'onboarding_page.dart';
import 'onboarding_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentIndex == onboardingItems.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingItems.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (_, index) {
                  final item = onboardingItems[index];
                  return OnboardingPage(
                    title: item.title,
                    description: item.description,
                    image: item.image,
                  );
                },
              ),
            ),

            // Indicateurs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingItems.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        _currentIndex == index
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bouton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (isLastPage) {
                      await context.read<UserProvider>().completeOnboarding();

                      if (context.mounted) {
                        context.go('/login');
                      }
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(isLastPage ? "Commencer" : "Suivant"),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
