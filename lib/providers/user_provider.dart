import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class UserProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // État de la date sélectionnée
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  double totalRevenus = 0.0;
  double totalDepenses = 0.0;
  int totalDepensesCount = 0;
  int moisActifs = 0;
  double epargneTotale = 0.0; 
  String displayName = "Utilisateur";
  Map<String, List<Map<String, dynamic>>> groupedTransactions = {};
  bool isLoading = true;

  // Fonction pour mettre à jour la date depuis le Header
  void updateSelectedDate(DateTime newDate) {
    _selectedDate = newDate;
    notifyListeners();
    fetchData(); 
  }

  Future<void> fetchData() async {
    try {
      isLoading = true;
      notifyListeners();

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Calcul du premier et dernier jour du mois sélectionné pour le filtrage
      final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);

      final results = await Future.wait<dynamic>([
        _supabase.from('profiles').select().eq('id', user.id).maybeSingle(),
        _supabase.from('revenus')
            .select('*, categories(nom)')
            .eq('user_id', user.id)
            .gte('date', firstDay.toIso8601String())
            .lte('date', lastDay.toIso8601String()),
        _supabase.from('depenses')
            .select('*, categories(nom)')
            .eq('user_id', user.id)
            .gte('date', firstDay.toIso8601String())
            .lte('date', lastDay.toIso8601String()),
      ]);

      final profileData = results[0] as Map<String, dynamic>?;
      final revs = results[1] as List<dynamic>;
      final deps = results[2] as List<dynamic>;

      if (profileData != null) {
        displayName = "${profileData['prenom'] ?? ''} ${profileData['nom'] ?? ''}".trim();
        if (displayName.isEmpty) displayName = "Utilisateur";
      }

      final all = [
        ...revs.map((e) => {...e, 'type': 'revenu'}),
        ...deps.map((e) => {...e, 'type': 'depense'}),
      ];
      
      // Tri décroissant par date
      all.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

      Map<String, List<Map<String, dynamic>>> groups = {};
      double resRev = 0;
      double resDep = 0;

      for (var tx in all) {
        String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(tx['date']));
        groups.putIfAbsent(dateKey, () => []);
        groups[dateKey]!.add(Map<String, dynamic>.from(tx));
        
        double mnt = (tx['montant'] as num).toDouble();
        if (tx['type'] == 'revenu') resRev += mnt; else resDep += mnt;
      }

      totalRevenus = resRev;
      totalDepenses = resDep;
      totalDepensesCount = deps.length;
      groupedTransactions = groups;
      epargneTotale = (resRev - resDep) > 0 ? (resRev - resDep) : 0;
      
      if (user.createdAt != null) {
        DateTime debut = DateTime.parse(user.createdAt!);
        DateTime maintenant = DateTime.now();
        moisActifs = ((maintenant.year - debut.year) * 12) + maintenant.month - debut.month + 1;
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur Provider: $e");
      isLoading = false;
      notifyListeners();
    }
  }
}