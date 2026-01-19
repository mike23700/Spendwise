class OnboardingItem {
  final String title;
  final String description;
  final String image;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.image,
  });
}

final onboardingItems = [
  OnboardingItem(
    title: "Gérez votre budget",
    description: "Suivez vos revenus et dépenses en toute simplicité.",
    image: "assets/budget.png",
  ),
  OnboardingItem(
    title: "Analyse intelligente",
    description: "Visualisez vos habitudes financières mois après mois.",
    image: "assets/analysis.png",
  ),
  OnboardingItem(
    title: "Atteignez vos objectifs",
    description: "Épargnez efficacement et prenez le contrôle de votre argent.",
    image: "assets/goals.png",
  ),
];
