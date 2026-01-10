import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  String _displayName = "Utilisateur";
  String _email = "";
  int _totalDepensesCount = 0;
  int _moisActifs = 0;
  double _epargneTotale = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final userId = user.id;
      _email = user.email ?? "";

      // 1. Récupérer les infos du profil
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // 2. Récupérer les stats
      final revs = await _supabase.from('revenus').select('montant').eq('user_id', userId);
      final deps = await _supabase.from('depenses').select('montant').eq('user_id', userId);

      double totalRev = (revs as List).fold(0, (sum, item) => sum + (item['montant'] as num).toDouble());
      double totalDep = (deps as List).fold(0, (sum, item) => sum + (item['montant'] as num).toDouble());

      if (user.createdAt != null) {
        DateTime debut = DateTime.parse(user.createdAt!);
        DateTime maintenant = DateTime.now();
        _moisActifs = ((maintenant.year - debut.year) * 12) + maintenant.month - debut.month + 1;
      }

      if (mounted) {
        setState(() {
          if (profileData != null) {
            _displayName = "${profileData['prenom'] ?? ''} ${profileData['nom'] ?? ''}".trim();
            if (_displayName.isEmpty) _displayName = "Utilisateur";
          }
          _totalDepensesCount = deps.length;
          double calculEpargne = totalRev - totalDep;
          _epargneTotale = calculEpargne > 0 ? calculEpargne : 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur Profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await _supabase.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
        : SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 60), // Espace réduit pour remonter le contenu
                _buildStatsSection(),
                const SizedBox(height: 25),
                _buildMenuSection(),
                const SizedBox(height: 25),
                _buildLogoutButton(context),
                const SizedBox(height: 50),
              ],
            ),
          ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF2D6A4F),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40), 
              bottomRight: Radius.circular(40)
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LIGNE 1 : Bouton Back seul
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  // LIGNE 2 : Profile et Settings
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Profile", 
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.settings, color: Colors.white), 
                          onPressed: () {}
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // CARTE BLANCHE
        Positioned(
          top: 150, 
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 35, 
                  backgroundColor: Color(0xFFE0E0E0), 
                  child: Icon(LucideIcons.user, size: 40, color: Colors.grey)
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_displayName, 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), 
                        overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 5),
                      _buildInfoRow(LucideIcons.mail, _email),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 14, color: const Color(0xFF2D6A4F)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, 
        style: const TextStyle(color: Colors.grey, fontSize: 13), 
        overflow: TextOverflow.ellipsis)
      ),
    ]);
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(_totalDepensesCount.toString(), "Dépenses"),
          _buildStatCard(_moisActifs.toString(), "Mois Actif"),
          _buildStatCard("${(_epargneTotale / 1000).toStringAsFixed(1)}k", "Epargné"),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      width: 105,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
      ),
      child: Column(children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.grey.withOpacity(0.1))
      ),
      child: Column(children: [
        _buildMenuItem(LucideIcons.user, "Infos du Compte"),
        const Divider(height: 1),
        _buildMenuItem(LucideIcons.shieldCheck, "Securité & Confidentialité"),
        const Divider(height: 1),
        _buildMenuItem(LucideIcons.helpCircle, "Aide"),
      ]),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF2D6A4F).withOpacity(0.1), 
        child: Icon(icon, color: const Color(0xFF2D6A4F), size: 18)
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: OutlinedButton.icon(
        onPressed: () => _signOut(context),
        icon: const Icon(LucideIcons.logOut, color: Colors.red, size: 20),
        label: const Text("Log out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 55),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}