import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../widgets/add_transaction_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  double totalRevenus = 0.0;
  double totalDepenses = 0.0;
  
  // Structure : {'2026-01-08': [transaction1, transaction2], ...}
  Map<String, List<Map<String, dynamic>>> groupedTransactions = {};

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final revs = await _supabase.from('revenus').select().eq('user_id', userId);
      final deps = await _supabase.from('depenses').select().eq('user_id', userId);

      final all = [
        ...(revs as List).map((e) => {...e, 'type': 'revenu'}),
        ...(deps as List).map((e) => {...e, 'type': 'depense'}),
      ];

      // Tri global par date décroissante
      all.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

      // Regroupement par jour
      Map<String, List<Map<String, dynamic>>> groups = {};
      double resRev = 0;
      double resDep = 0;

      for (var tx in all) {
        String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(tx['date']));
        if (groups[dateKey] == null) groups[dateKey] = [];
        groups[dateKey]!.add(Map<String, dynamic>.from(tx));
        
        double mnt = (tx['montant'] as num).toDouble();
        if (tx['type'] == 'revenu') resRev += mnt; else resDep += mnt;
      }

      if (mounted) {
        setState(() {
          groupedTransactions = groups;
          totalRevenus = resRev;
          totalDepenses = resDep;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedKeys = groupedTransactions.keys.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
        : Column(
            children: [
              _buildDateSelector(),
              _buildTabs(),
              _buildGlobalSummary(),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    String date = sortedKeys[index];
                    return _DayGroupWidget(date: date, items: groupedTransactions[date]!);
                  },
                ),
              ),
            ],
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFAB(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // --- Éléments d'interface extraits pour la clarté ---

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white, elevation: 0,
    title: const Text("Dépenses", style: TextStyle(color: Colors.black)),
    centerTitle: true,
    leading: const Icon(LucideIcons.search, color: Colors.grey),
    actions: const [Padding(padding: EdgeInsets.only(right: 15), child: CircleAvatar(radius: 15, backgroundColor: Color(0xFFE0E0E0), child: Icon(LucideIcons.user, size: 18, color: Colors.grey)))],
  );

  Widget _buildDateSelector() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.chevron_left, color: Colors.grey),
      Text(DateFormat('MMM. yyyy', 'fr_FR').format(DateTime.now()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      const Icon(Icons.chevron_right, color: Colors.grey),
    ]),
  );

  Widget _buildTabs() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _TabItem(title: "Liste", isActive: true),
      _TabItem(title: "Calendrier"),
      _TabItem(title: "Mois"),
      _TabItem(title: "Résumé"),
    ]),
  );

  Widget _buildGlobalSummary() => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: Colors.grey[200]!))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _SummaryItem(label: "Revenus", value: totalRevenus, color: Colors.indigo),
      _SummaryItem(label: "Dépenses", value: totalDepenses, color: Colors.orange),
      _SummaryItem(label: "Total", value: totalRevenus - totalDepenses, color: const Color(0xFF2D6A4F)),
    ]),
  );

  Widget _buildFAB() => FloatingActionButton(
    backgroundColor: const Color(0xFF2D6A4F),
    onPressed: () => showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(onTransactionAdded: _fetchDashboardData),
    ),
    child: const Icon(Icons.add, color: Colors.white, size: 30),
  );

  Widget _buildBottomBar() => BottomAppBar(
    shape: const CircularNotchedRectangle(), notchMargin: 8,
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [
      Icon(LucideIcons.calendar, color: Color(0xFF2D6A4F)),
      Icon(LucideIcons.barChart2, color: Colors.grey),
      SizedBox(width: 40),
      Icon(LucideIcons.dollarSign, color: Colors.grey),
      Icon(LucideIcons.settings, color: Colors.grey),
    ]),
  );
}

// --- Widget de groupe par jour (L'élément clé de ta capture) ---

class _DayGroupWidget extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> items;

  const _DayGroupWidget({required this.date, required this.items});

  @override
  Widget build(BuildContext context) {
    DateTime dt = DateTime.parse(date);
    double dayRev = 0;
    double dayDep = 0;

    for (var item in items) {
      double mnt = (item['montant'] as num).toDouble();
      if (item['type'] == 'revenu') dayRev += mnt; else dayDep += mnt;
    }

    return Column(
      children: [
        // Header du jour (ex: 08 jeu.)
// Dans _DayGroupWidget, remplace le header du jour par ceci :
Container(
  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
  color: Colors.grey[50],
  child: Row(
    children: [
      Text(
        DateFormat('dd', 'fr_FR').format(dt), 
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
      ),
      const SizedBox(width: 5),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black87, 
          borderRadius: BorderRadius.circular(4)
        ), 
        child: Text(
          DateFormat('E', 'fr_FR').format(dt).toLowerCase(), 
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
        )
      ),
      const Spacer(),
      // Affichage des totaux journaliers
      if (dayRev > 0) Text("FCFA ${dayRev.toInt()}", style: const TextStyle(color: Colors.indigo, fontSize: 12)),
      const SizedBox(width: 15),
      if (dayDep > 0) Text("FCFA ${dayDep.toInt()}", style: const TextStyle(color: Colors.orange, fontSize: 12)),
    ],
  ),
),
        // Liste des transactions du jour
        ...items.map((tx) => _TransactionDetailTile(tx: tx)).toList(),
      ],
    );
  }
}

class _TransactionDetailTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionDetailTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    bool isRev = tx['type'] == 'revenu';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(tx['description'] ?? 'Autre', style: const TextStyle(fontSize: 15))),
          Expanded(flex: 2, child: const Text("Portefeuille", style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(
            "FCFA ${tx['montant']}", 
            style: TextStyle(color: isRev ? Colors.indigo : Colors.redAccent, fontWeight: FontWeight.w500), 
            textAlign: TextAlign.right
          )),
        ],
      ),
    );
  }
}

// Widgets réutilisables simples (Tabs / Summary)
class _TabItem extends StatelessWidget {
  final String title; final bool isActive;
  const _TabItem({required this.title, this.isActive = false});
  @override Widget build(BuildContext context) => Column(children: [
    Text(title, style: TextStyle(color: isActive ? const Color(0xFF2D6A4F) : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
    if (isActive) Container(margin: const EdgeInsets.only(top: 5), height: 2, width: 30, color: const Color(0xFF2D6A4F))
  ]);
}

class _SummaryItem extends StatelessWidget {
  final String label; final double value; final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});
  @override Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    Text(value.toInt().toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
  ]);
}