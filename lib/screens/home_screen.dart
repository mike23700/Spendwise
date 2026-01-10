import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../widgets/add_transaction_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // On écoute le store
    final store = context.watch<UserProvider>();
    final sortedKeys = store.groupedTransactions.keys.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(store),
      body: store.isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
        : Column(
            children: [
              _buildDateSelector(),
              _buildTabs(),
              _buildGlobalSummary(store),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    String date = sortedKeys[index];
                    return _DayGroupWidget(date: date, items: store.groupedTransactions[date]!);
                  },
                ),
              ),
            ],
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFAB(context),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(UserProvider store) => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    title: const Text("Transactions", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    centerTitle: true,
    leading: const Icon(LucideIcons.search, color: Colors.grey),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 15),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: const CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xFFE0E0E0),
            child: Icon(LucideIcons.user, size: 18, color: Colors.grey)
          ),
        ),
      )
    ],
  );

  Widget _buildDateSelector() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.chevron_left, color: Colors.grey),
      const SizedBox(width: 10),
      Text(DateFormat('MMM yyyy', 'fr_FR').format(DateTime.now()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      const SizedBox(width: 10),
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

  Widget _buildGlobalSummary(UserProvider store) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: Colors.grey[200]!))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _SummaryItem(label: "Revenus", value: store.totalRevenus, color: Colors.indigo),
      _SummaryItem(label: "Dépenses", value: store.totalDepenses, color: Colors.orange),
      _SummaryItem(label: "Total", value: store.totalRevenus - store.totalDepenses, color: const Color(0xFF2D6A4F)),
    ]),
  );

  Widget _buildFAB(BuildContext context) => FloatingActionButton(
    backgroundColor: const Color(0xFF2D6A4F),
    onPressed: () => showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        onTransactionAdded: () => context.read<UserProvider>().fetchData(),
      ),
    ),
    child: const Icon(Icons.add, color: Colors.white, size: 30),
  );

  Widget _buildBottomBar(BuildContext context) => BottomAppBar(
    shape: const CircularNotchedRectangle(),
    notchMargin: 8,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Icon(LucideIcons.calendar, color: Color(0xFF2D6A4F)),
        const Icon(LucideIcons.barChart2, color: Colors.grey),
        const SizedBox(width: 40), 
        const Icon(LucideIcons.dollarSign, color: Colors.grey),
        IconButton(
          icon: const Icon(LucideIcons.user, color: Colors.grey),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
      ],
    ),
  );
}

// Widget de Groupe par Jour (Repliable)
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
      if (item['type'] == 'revenu') dayRev += mnt; else dayDep += mnt;
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
                Text(DateFormat('dd', 'fr_FR').format(dt), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)), 
                  child: Text(DateFormat('E', 'fr_FR').format(dt).toLowerCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
                ),
                const SizedBox(width: 8),
                const Spacer(),
                Text("FCFA ${dayRev.toInt()}", style: const TextStyle(color: Colors.indigo, fontSize: 12)),
                const SizedBox(width: 40),
                Text("FCFA ${dayDep.toInt()}", style: const TextStyle(color: Colors.orange, fontSize: 12)),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...widget.items.map((tx) => _TransactionDetailTile(tx: tx)).toList(),
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
    String category = tx['categories']?['nom'] ?? 'Autre';
    String? note = tx['description'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(category, style: const TextStyle(fontSize: 15))),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                if (note != null && note.isNotEmpty)
                  Text(note, style: const TextStyle(fontSize: 14, color: Colors.black87), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                const Text("Portefeuille", style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          ),
          Expanded(
            flex: 3, 
            child: Text("FCFA ${tx['montant']}", 
              style: TextStyle(color: isRev ? Colors.indigo : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14), 
              textAlign: TextAlign.right
            )
          ),
        ],
      ),
    );
  }
}

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