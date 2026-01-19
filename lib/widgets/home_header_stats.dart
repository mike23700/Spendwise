import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';

class HomeHeaderStats extends StatelessWidget {
  final int activeTabIndex;
  final Function(int) onTabChanged;
  final UserProvider store;

  const HomeHeaderStats({
    super.key,
    required this.activeTabIndex,
    required this.onTabChanged,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDateSelector(context),
        _buildTabsHeader(),
        _buildGlobalSummary(),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    // On utilise la date stockée dans le provider pour que tout soit synchrone
    // Si tu n'as pas encore 'selectedDate' dans ton provider, utilise DateTime.now() par défaut
    DateTime displayDate = store.selectedDate;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bouton Mois Précédent
          IconButton(
            onPressed: () => _changeMonth(context, -1),
            icon: const Icon(Icons.chevron_left, color: Colors.grey),
          ),
          const SizedBox(width: 20),

          // Affichage du mois et de l'année
          Text(
              DateFormat('MMM yyyy', 'fr_FR').format(displayDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)
          ),

          const SizedBox(width: 20),

          // Bouton Mois Suivant
          IconButton(
            onPressed: () => _changeMonth(context, 1),
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Fonction pour changer le mois
  void _changeMonth(BuildContext context, int offset) {
    DateTime current = store.selectedDate;
    // On crée la nouvelle date en ajoutant/retirant un mois
    DateTime newDate = DateTime(current.year, current.month + offset, 1);

    // On met à jour la date dans le provider (méthode à créer dans user_provider.dart)
    store.updateSelectedDate(newDate);
  }

  Widget _buildTabsHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _tabButton("Liste", 0),
          _tabButton("Calendrier", 1),
          _tabButton("Mois", 2),
          _tabButton("Résumé", 3),
        ]
    ),
  );

  Widget _tabButton(String title, int index) {
    bool isActive = activeTabIndex == index;
    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: Column(
        children: [
          Text(title, style: TextStyle(
              color: isActive ? const Color(0xFF2D6A4F) : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal
          )),
          if (isActive) Container(margin: const EdgeInsets.only(top: 5), height: 2, width: 30, color: const Color(0xFF2D6A4F))
        ],
      ),
    );
  }

  Widget _buildGlobalSummary() => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: Colors.grey[200]!))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _SummaryItem(label: "Revenus", value: store.totalRevenus, color: Colors.indigo),
      _SummaryItem(label: "Dépenses", value: store.totalDepenses, color: Colors.orange),
      _SummaryItem(label: "Total", value: store.totalRevenus - store.totalDepenses, color: const Color(0xFF2D6A4F)),
    ]),
  );
}

class _SummaryItem extends StatelessWidget {
  final String label; final double value; final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});
  @override Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    Text("FCFA ${value.toInt()}", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
  ]);
}