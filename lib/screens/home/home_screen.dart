import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:wiseNkap/providers/user_provider.dart';
import 'package:wiseNkap/widgets/home_header_stats.dart';
import 'package:wiseNkap/widgets/add_transaction_sheet.dart';

import 'package:wiseNkap/tabs/list_tab.dart';
import 'package:wiseNkap/tabs/calendar_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeTabIndex = 0;

  late final List<_HomeTab> _tabs;

  @override
  void initState() {
    super.initState();

    _tabs = const [
      _HomeTab(
        title: "Transactions",
        icon: LucideIcons.list,
        widget: ListTab(),
        showFab: true,
      ),
      _HomeTab(
        title: "Calendrier",
        icon: LucideIcons.calendar,
        widget: CalendarTab(),
        showFab: true,
      ),
      _HomeTab(
        title: "Mois",
        icon: LucideIcons.dollarSign,
        widget: Center(child: Text("Vue mensuelle")),
        showFab: false,
      ),
      _HomeTab(
        title: "Résumé",
        icon: LucideIcons.barChart2,
        widget: Center(child: Text("Statistiques & résumé")),
        showFab: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<UserProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),

      body: Selector<UserProvider, bool>(
        selector: (_, p) => p.isLoading,
        builder: (_, isLoading, __) {
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
            );
          }

          return Column(
            children: [
              HomeHeaderStats(
                activeTabIndex: _activeTabIndex,
                store: store,
                onTabChanged: _onTabChanged,
              ),
              Expanded(
                child: IndexedStack(
                  index: _activeTabIndex,
                  children: _tabs.map((t) => t.widget).toList(),
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: _tabs[_activeTabIndex].showFab ? _buildFab() : null,

      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        _tabs[_activeTabIndex].title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(LucideIcons.search, color: Colors.grey),
        onPressed: () {
          // TODO: navigation recherche
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recherche - Bientôt disponible')),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.lightbulb, color: Colors.amber),
          tooltip: "Conseils",
          onPressed: () {
            // TODO: navigation conseils
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Conseils - Bientôt disponibles')),
            );
          },
        ),
        IconButton(
          tooltip: "Profil",
          icon: const CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xFFE0E0E0),
            child: Icon(LucideIcons.user, size: 18, color: Colors.grey),
          ),
          onPressed: () => context.push('/profile'),
        ),
      ],
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF2D6A4F),
      child: const Icon(Icons.add, color: Colors.white, size: 30),
      onPressed:
          () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder:
                (_) => AddTransactionSheet(
                  onTransactionAdded:
                      () => context.read<UserProvider>().fetchData(),
                ),
          ),
    );
  }

  Widget _buildNavigationBar() {
    return NavigationBar(
      selectedIndex: _activeTabIndex,
      indicatorColor: const Color(0xFFB7E4C7),
      onDestinationSelected: _onTabChanged,
      destinations:
          _tabs
              .map(
                (tab) => NavigationDestination(
                  icon: Icon(tab.icon),
                  label: tab.title,
                ),
              )
              .toList(),
    );
  }

  void _onTabChanged(int index) {
    if (_activeTabIndex == index) return;
    setState(() => _activeTabIndex = index);
  }
}

class _HomeTab {
  final String title;
  final IconData icon;
  final Widget widget;
  final bool showFab;

  const _HomeTab({
    required this.title,
    required this.icon,
    required this.widget,
    required this.showFab,
  });
}
