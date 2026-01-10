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
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final revenusData = await _supabase.from('revenus').select().eq('user_id', userId);
      final depensesData = await _supabase.from('depenses').select().eq('user_id', userId);

      final revenus = (revenusData as List).map((e) => {...e, 'type': 'revenu'}).toList();
      final depenses = (depensesData as List).map((e) => {...e, 'type': 'depense'}).toList();

      final allTransactions = [...revenus, ...depenses];

      // Tri par date de création
      allTransactions.sort((a, b) => 
        DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']))
      );

      if (mounted) {
        setState(() {
          totalRevenus = revenus.fold(0.0, (sum, item) => sum + (item['montant'] as num));
          totalDepenses = depenses.fold(0.0, (sum, item) => sum + (item['montant'] as num));
          transactions = List<Map<String, dynamic>>.from(allTransactions);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur dashboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Dépenses", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(LucideIcons.search, color: Colors.grey), onPressed: () {}),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 15,
              backgroundColor: Color(0xFFF0F0F0),
              child: Icon(LucideIcons.user, size: 18, color: Colors.grey),
            ),
            onPressed: () {},
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
          : Column(
              children: [
                // Sélecteur de date
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chevron_left, color: Colors.grey),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('MMM yyyy', 'fr_FR').format(DateTime.now()),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),

                // Onglets de navigation haute
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _TabItem(title: "Liste", isActive: true),
                      _TabItem(title: "Calendrier"),
                      _TabItem(title: "Mois"),
                      _TabItem(title: "Résumé"),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 0.5),

                // Résumé financier (Ruban de totaux)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryItem(label: "Revenus", value: totalRevenus, color: Colors.indigo),
                      _SummaryItem(label: "Dépenses", value: totalDepenses, color: Colors.orange),
                      _SummaryItem(label: "Total", value: totalRevenus - totalDepenses, color: const Color(0xFF2D6A4F)),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 0.5),

                // Liste des transactions dynamique
                Expanded(
                  child: transactions.isEmpty
                      ? const Center(child: Text("Aucune transaction enregistrée"))
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final item = transactions[index];
                            return _TransactionTile(
                              description: item['description'] ?? 'Transaction',
                              wallet: "Portefeuille",
                              amount: (item['montant'] as num).toDouble(),
                              isRevenu: item['type'] == 'revenu',
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
floatingActionButton: FloatingActionButton(
  backgroundColor: const Color(0xFF2D6A4F),
  onPressed: () {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        onTransactionAdded: () {
          _fetchDashboardData(); 
        },
      ),
    );
  },
  child: const Icon(Icons.add, color: Colors.white, size: 30),
),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(icon: const Icon(LucideIcons.calendar, color: Color(0xFF2D6A4F)), onPressed: () {}),
              IconButton(icon: const Icon(LucideIcons.barChart2, color: Colors.grey), onPressed: () {}),
              const SizedBox(width: 40), // Espace central
              IconButton(
                icon: const Icon(LucideIcons.dollarSign, color: Colors.grey), 
                onPressed: () {}
              ),
              IconButton(
                icon: const Icon(LucideIcons.user, color: Colors.grey), 
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SOUS-WIDGETS ---

class _TabItem extends StatelessWidget {
  final String title;
  final bool isActive;
  const _TabItem({required this.title, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: TextStyle(color: isActive ? const Color(0xFF2D6A4F) : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        if (isActive) Container(margin: const EdgeInsets.only(top: 5), height: 3, width: 30, color: const Color(0xFF2D6A4F)),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value.toStringAsFixed(0), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String description;
  final String wallet;
  final double amount;
  final bool isRevenu;

  const _TransactionTile({required this.description, required this.wallet, required this.amount, required this.isRevenu});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5)))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(description, style: const TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(wallet, style: const TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center)),
          Expanded(
            flex: 3,
            child: Text(
              "${isRevenu ? '' : '- '}FCFA ${amount.toStringAsFixed(0)}",
              style: TextStyle(color: isRevenu ? Colors.indigo : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}