import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/user_provider.dart';
import '../widgets/home_header_stats.dart';
import '../widgets/add_transaction_sheet.dart';
import '../tabs/list_tab.dart';
import '../tabs/calendar_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeTabIndex = 0;

  final List<Widget> _tabs = [
    const ListTab(),
    const CalendarTab(),
    const Center(child: Text("Mois")),
    const Center(child: Text("Résumé")),
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: store.isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
        : Column(
            children: [
              HomeHeaderStats(
                activeTabIndex: _activeTabIndex,
                store: store,
                onTabChanged: (index) => setState(() => _activeTabIndex = index),
              ),
              Expanded(child: _tabs[_activeTabIndex]),
            ],
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFAB(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    title: const Text("Transactions", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    centerTitle: true,
    leading: const Icon(LucideIcons.search, color: Colors.grey),
    actions: [
    IconButton(
      onPressed: () {
        // TODO : astuces ia
      },
      icon: const Icon(
        LucideIcons.lightbulb,
        color: Colors.amber, 
        size: 22,
      ),
      tooltip: "Conseils",
    ),      
      IconButton(
        onPressed: () => Navigator.pushNamed(context, '/profile'),
        icon: const CircleAvatar(
          radius: 15,
          backgroundColor: Color(0xFFE0E0E0),
          child: Icon(LucideIcons.user, size: 18, color: Colors.grey)
        ),
      )
    ],
  );

  Widget _buildFAB() => FloatingActionButton(
    backgroundColor: const Color(0xFF2D6A4F),
    shape: const CircleBorder(),
    onPressed: () => showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(onTransactionAdded: () => context.read<UserProvider>().fetchData()),
    ),
    child: const Icon(Icons.add, color: Colors.white, size: 40),
  );

/*Widget _buildFAB() => FloatingActionButton(
  backgroundColor: const Color(0xFF2D6A4F),
  shape: const CircleBorder(), 
  onPressed: () => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddTransactionSheet(
      onTransactionAdded: () => context.read<UserProvider>().fetchData(),
    ),
  ),
  child: const Icon(Icons.add, color: Colors.white, size: 30),
);*/



  Widget _buildBottomBar() => BottomAppBar(
    shape: const CircularNotchedRectangle(),
    notchMargin: 8,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Icon(LucideIcons.calendar, color: Color(0xFF2D6A4F)),
        const Icon(LucideIcons.barChart2, color: Colors.grey),
        const SizedBox(width: 40), 
        const Icon(LucideIcons.dollarSign, color: Colors.grey),
        IconButton(icon: const Icon(LucideIcons.user, color: Colors.grey), onPressed: () => Navigator.pushNamed(context, '/profile')),
      ],
    ),
  );
}