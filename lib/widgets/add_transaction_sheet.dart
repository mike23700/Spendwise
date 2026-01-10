import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddTransactionSheet extends StatefulWidget {
  final VoidCallback onTransactionAdded;
  const AddTransactionSheet({super.key, required this.onTransactionAdded});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _supabase = Supabase.instance.client;
  bool isIncome = true;
  
  // stocke des Maps pour avoir l'ID et le NOM
  List<Map<String, dynamic>> _categoriesFromDb = [];
  String? _selectedCategoryId; 
  
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories(); 
  }

  Future<void> _loadCategories() async {
    try {
      final type = isIncome ? 'revenu' : 'depense';
      final data = await _supabase
          .from('categories')
          .select('id, nom')
          .eq('type', type);

      setState(() {
        _categoriesFromDb = List<Map<String, dynamic>>.from(data);
        _selectedCategoryId = null; // Reset quand on change de type
      });
    } catch (e) {
      debugPrint("Erreur chargement categories: $e");
    }
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Remplissez le montant et la catégorie")),
      );
      return;
    }

    setState(() => _isSaving = true);
    final userId = _supabase.auth.currentUser?.id;
    final table = isIncome ? 'revenus' : 'depenses';

    try {
      await _supabase.from(table).insert({
        'user_id': userId,
        'montant': double.parse(_amountController.text.replaceAll(',', '.')),
        'description': _noteController.text,
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'categorie_id': _selectedCategoryId, // ON ENVOIE L'ID MAINTENANT
      });

      widget.onTransactionAdded();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20, left: 20, right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            const Center(child: Text("Transaction", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F)))),
            const SizedBox(height: 20),

            // Sélecteur Income / Expense
            Container(
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(child: _buildToggleButton("Income", isIncome, const Color(0xFF2D6A4F), () {
                    setState(() => isIncome = true);
                    _loadCategories(); // Recharger les catégories revenus
                  })),
                  Expanded(child: _buildToggleButton("Expense", !isIncome, Colors.red, () {
                    setState(() => isIncome = false);
                    _loadCategories(); // Recharger les catégories dépenses
                  })),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel("Montant"),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: "FCFA ",
                filled: true,
                fillColor: Colors.grey[50]!,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 15),
            _buildLabel("Catégorie"),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: InputDecoration(filled: true, fillColor: Colors.grey[50]!, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              items: _categoriesFromDb.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat['id'].toString(), // On utilise l'ID de la BD
                  child: Text(cat['nom']),      // On affiche le NOM
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategoryId = val),
              hint: const Text("Choisir une catégorie"),
            ),

            const SizedBox(height: 15),
            _buildLabel("Date"),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (date != null) setState(() => selectedDate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.grey[50]!, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [const Icon(LucideIcons.calendar, size: 20), const SizedBox(width: 10), Text(DateFormat('dd MMMM yyyy', 'fr_FR').format(selectedDate))]),
              ),
            ),

            const SizedBox(height: 15),
            _buildLabel("Note (optionnel)"),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(hintText: "Ajouter une note...", filled: true, fillColor: Colors.grey[50]!, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: _isSaving 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Ajouter", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, Color activeColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)));
  }
}