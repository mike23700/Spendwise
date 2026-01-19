import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../services/onboarding_service.dart';

class UserProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();
  final TransactionService _transactionService = TransactionService();
  final OnboardingService _onboardingService = OnboardingService();

  // ==========================
  // ÉTATS
  // ==========================
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _hasCompletedOnboarding = false;

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _categories = [];

  DateTime _selectedDate = DateTime.now();
  String? _lastError;

  // ==========================
  // GETTERS
  // ==========================
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String? get lastError => _lastError;

  String get displayName => _profile?['nom'] ?? 'Utilisateur';
  String? get email => _profile?['email'];
  DateTime get selectedDate => _selectedDate;

  List<Map<String, dynamic>> get transactions => _transactions;
  List<Map<String, dynamic>> get categories => _categories;

  // ==========================
  // CALCULS FINANCIERS
  // ==========================
  int get totalDepensesCount =>
      _transactions.where((t) => t['type'] == 'depense').length;

  int get moisActifs {
    if (_transactions.isEmpty) return 0;
    final moisUniques =
        _transactions.where((t) => t['date'] != null).map((t) {
          final date = DateTime.parse(t['date'].toString());
          return "${date.year}-${date.month}";
        }).toSet();
    return moisUniques.length;
  }

  double get totalRevenus => _transactions
      .where((t) => t['type'] == 'revenu')
      .fold(0.0, (sum, t) => sum + (t['montant'] as num).toDouble());

  double get totalDepenses => _transactions
      .where((t) => t['type'] == 'depense')
      .fold(0.0, (sum, t) => sum + (t['montant'] as num).toDouble());

  double get epargneTotale => totalRevenus - totalDepenses;

  // ==========================
  // CATÉGORIES
  // ==========================
  List<Map<String, dynamic>> get incomeCategories =>
      _categories.where((c) => c['type'] == 'revenu').toList();

  List<Map<String, dynamic>> get expenseCategories =>
      _categories.where((c) => c['type'] == 'depense').toList();

  // ==========================
  // TRANSACTIONS GROUPÉES
  // ==========================
  Map<String, List<Map<String, dynamic>>> get groupedTransactions {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final t in _transactions) {
      if (t['date'] == null) continue;
      final key = t['date'].toString().split('T').first;
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(t);
    }
    return grouped;
  }

  // ==========================
  // INITIALISATION
  // ==========================
  Future<void> init() async {
    try {
      debugPrint('🔄 Initialisation du UserProvider...');
      final session = _supabase.auth.currentSession;
      if (session != null) {
        debugPrint('✅ Session trouvée pour: ${session.user.email}');
        _isAuthenticated = true;
        await _loadProfile();
        await fetchData();
        debugPrint('✅ Données chargées avec succès');
      } else {
        debugPrint('⚠️ Aucune session trouvée');
      }
    } catch (e) {
      _lastError = 'Erreur lors de l\'initialisation: $e';
      debugPrint('❌ ERREUR INIT: $_lastError');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Initialisation terminée');
    }
  }

  // ==========================
  // AUTHENTIFICATION
  // ==========================
  Future<bool> login({required String email, required String password}) async {
    debugPrint('🔑 Tentative de connexion: $email');
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final (success, error) = await _authService.login(
      email: email,
      password: password,
    );

    if (success) {
      debugPrint('✅ Authentification réussie pour: $email');
      _isAuthenticated = true;
      try {
        debugPrint('📥 Chargement du profil...');
        await _loadProfile();
        debugPrint('✅ Profil chargé');

        debugPrint('📥 Chargement des données...');
        await fetchData();
        debugPrint('✅ Données chargées');

        // Si l'onboarding a été complété localement, le mettre à jour dans Supabase
        if (_hasCompletedOnboarding) {
          debugPrint('📤 Mise à jour du onboarding dans Supabase...');
          await _onboardingService.completeOnboarding();
          debugPrint('✅ Onboarding mis à jour');
        }
      } catch (e) {
        _lastError = 'Erreur lors du chargement du profil: $e';
        debugPrint('❌ ERREUR LOGIN: $_lastError');
      }
    } else {
      _lastError = error;
      _isAuthenticated = false;
      debugPrint('❌ Échec de l\'authentification: $error');
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
  }) async {
    debugPrint('📝 Tentative d\'inscription: $email');
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final (success, error) = await _authService.register(
      email: email,
      password: password,
      nom: nom,
      prenom: prenom,
    );

    if (success) {
      debugPrint('✅ Inscription réussie pour: $email');
      _isAuthenticated = true;
      try {
        debugPrint('📥 Chargement du profil après inscription...');
        await _loadProfile();
        debugPrint('✅ Profil chargé');

        debugPrint('📥 Chargement des données...');
        await fetchData();
        debugPrint('✅ Données chargées');

        // Si l'onboarding a été complété localement, le mettre à jour dans Supabase
        if (_hasCompletedOnboarding) {
          debugPrint('📤 Mise à jour du onboarding dans Supabase...');
          await _onboardingService.completeOnboarding();
          debugPrint('✅ Onboarding mis à jour');
        }
      } catch (e) {
        _lastError = 'Erreur lors du chargement du profil: $e';
        debugPrint('❌ ERREUR REGISTER: $_lastError');
      }
    } else {
      _lastError = error;
      _isAuthenticated = false;
      debugPrint('❌ Échec de l\'inscription: $error');
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    debugPrint('🚪 Déconnexion en cours...');
    try {
      debugPrint('🔌 Appel du service d\'authentification...');
      await _authService.logout();
      debugPrint('✅ Service d\'authentification déconnecté');

      debugPrint('🗑️ Nettoyage des données locales...');
      _isAuthenticated = false;
      _profile = null;
      _transactions.clear();
      debugPrint('✅ Transactions effacées (${_transactions.length})');
      _categories.clear();
      debugPrint('✅ Catégories effacées (${_categories.length})');
      _hasCompletedOnboarding = false;
      _lastError = null;

      notifyListeners();
      debugPrint('✅ Listeners notifiés');
      debugPrint('✅ DÉCONNEXION RÉUSSIE');
    } catch (e) {
      debugPrint('❌ Erreur lors de la déconnexion: $e');
      rethrow;
    }
  }

  // ==========================
  // PROFIL ET ONBOARDING
  // ==========================
  Future<void> _loadProfile() async {
    try {
      debugPrint('📥 Chargement du profil depuis Supabase...');
      final (profile, error) = await _onboardingService.getUserProfile();
      if (error != null) {
        _lastError = error;
        debugPrint('❌ Erreur lors du chargement du profil: $error');
        return;
      }
      _profile = profile;
      _hasCompletedOnboarding = profile?['onboarding_done'] as bool? ?? false;
      debugPrint(
        '✅ Profil chargé: ${profile?['nom'] ?? 'N/A'}, onboarding_done: $_hasCompletedOnboarding',
      );
    } catch (e) {
      _lastError = 'Erreur lors du chargement du profil: $e';
      debugPrint('❌ EXCEPTION: $_lastError');
    }
  }

  Future<bool> completeOnboarding() async {
    debugPrint('🎯 Marquage du onboarding comme complété');
    // Marquer localement comme complété, même si pas encore authentifié
    _hasCompletedOnboarding = true;
    notifyListeners();
    debugPrint('✅ Onboarding marqué localement: $_hasCompletedOnboarding');

    // Essayer de mettre à jour dans Supabase si l'utilisateur est authentifié
    if (_isAuthenticated) {
      debugPrint('📤 Utilisateur authentifié, mise à jour dans Supabase...');
      final (success, error) = await _onboardingService.completeOnboarding();
      if (!success) {
        _lastError = error;
        debugPrint('❌ Erreur Supabase: $error');
        return false;
      }
      debugPrint('✅ Onboarding mis à jour dans Supabase');
    } else {
      debugPrint(
        '⚠️ Utilisateur non authentifié, onboarding sera mis à jour lors de la connexion',
      );
    }
    return true;
  }

  // ==========================
  // DONNÉES
  // ==========================
  Future<void> fetchData() async {
    try {
      await Future.wait([fetchTransactions(), fetchCategories()]);
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchTransactions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ Pas d\'utilisateur pour charger les transactions');
      _transactions = [];
      return;
    }

    try {
      debugPrint('📥 Chargement des transactions pour: ${user.email}');
      final (transactions, error) = await _transactionService.getTransactions();
      if (error != null) {
        _lastError = error;
        _transactions = [];
        debugPrint('❌ Erreur lors du chargement des transactions: $error');
      } else {
        _transactions = transactions;
        debugPrint('✅ ${_transactions.length} transaction(s) chargée(s)');
      }
    } catch (e) {
      _lastError = 'Erreur lors du chargement des transactions: $e';
      debugPrint('❌ EXCEPTION: $_lastError');
      _transactions = [];
    }
  }

  Future<void> fetchCategories() async {
    try {
      debugPrint('📥 Chargement des catégories...');
      final data = await _supabase.from('categories').select();
      _categories = List<Map<String, dynamic>>.from(data);
      debugPrint('✅ ${_categories.length} catégorie(s) chargée(s)');
    } catch (e) {
      _lastError = 'Erreur lors du chargement des catégories: $e';
      debugPrint('❌ EXCEPTION: $_lastError');
      _categories = [];
    }
  }

  // ==========================
  // TRANSACTIONS
  // ==========================
  Future<bool> addTransaction({
    required double montant,
    required String type,
    required String categorieId,
    required DateTime date,
    required String description,
  }) async {
    debugPrint('💰 Ajout d\'une transaction: $montant $type');
    final (success, error) = await _transactionService.addTransaction(
      montant: montant,
      type: type,
      categorieId: categorieId,
      date: date,
      description: description,
    );

    if (success) {
      debugPrint('✅ Transaction ajoutée avec succès');
      await fetchTransactions();
      notifyListeners();
    } else {
      _lastError = error;
      debugPrint('❌ Erreur lors de l\'ajout de transaction: $error');
    }

    return success;
  }

  // ==========================
  // UI
  // ==========================
  void updateSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
}
