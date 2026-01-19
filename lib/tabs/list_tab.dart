import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';

class ListTab extends StatelessWidget {
  const ListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserProvider>();
    final sortedKeys = store.groupedTransactions.keys.toList();

    if (sortedKeys.isEmpty && !store.isLoading) {
      return const Center(
        child: Text(
          "Aucune transaction pour le moment.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: sortedKeys.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        String date = sortedKeys[index];
        return _DayGroupWidget(
          date: date,
          items: store.groupedTransactions[date]!,
        );
      },
    );
  }
}

class _DayGroupWidget extends StatefulWidget {
  final String date;
  final List<Map<String, dynamic>> items;
  const _DayGroupWidget({required this.date, required this.items});

  @override
  State<_DayGroupWidget> createState() => _DayGroupWidgetState();
}

class _DayGroupWidgetState extends State<_DayGroupWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    DateTime dt = DateTime.parse(widget.date);
    double dayRev = 0;
    double dayDep = 0;
    for (var item in widget.items) {
      double mnt = (item['montant'] as num).toDouble();
      if (item['type'] == 'revenu') {
        dayRev += mnt;
      } else if (item['type'] == 'expense') {
        dayDep += mnt;
      }
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            color: Colors.grey[50],
            child: Row(
              children: [
                Text(
                  DateFormat('dd', 'fr_FR').format(dt),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    DateFormat('E', 'fr_FR').format(dt).toLowerCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                Text(
                  "FCFA ${dayRev.toInt()}",
                  style: const TextStyle(color: Colors.indigo, fontSize: 12),
                ),
                const SizedBox(width: 40),
                Text(
                  "FCFA ${dayDep.toInt()}",
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          ...widget.items.map((tx) => _TransactionDetailTile(tx: tx)),
      ],
    );
  }
}

class _TransactionDetailTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionDetailTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    bool isRev = tx['type'] == 'income';

    // Récupération sécurisée du nom et de l'emoji
    final categoryData = tx['categories'];
    String categoryName = categoryData?['nom'] ?? 'Autre';
    String emoji = categoryData?['emoji'] ?? '📁';

    String? note = tx['description'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          // Colonne Catégorie
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: const TextStyle(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Colonne Note / Source
          Expanded(
            flex: 3,
            child: Column(
              children: [
                if (note != null && note.isNotEmpty)
                  Text(
                    note,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                const Text(
                  "Portefeuille",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Colonne Montant
          Expanded(
            flex: 3,
            child: Text(
              "FCFA ${(tx['montant'] as num).toInt()}",
              style: TextStyle(
                color: isRev ? Colors.indigo : Colors.redAccent,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
