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
  bool isIncome = true; // Pour basculer entre Income et Expense
  String? selectedCategory;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  // Liste de catégories exemple (à lier à ta table categories plus tard)
  final List<String> categories = ['Salaire', 'Alimentation', 'Transport', 'Loisirs', 'Santé'];

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty || selectedCategory == null) return;

    final userId = _supabase.auth.currentUser?.id;
    final table = isIncome ? 'revenus' : 'depenses';

    try {
      await _supabase.from(table).insert({
        'user_id': userId,
        'montant': double.parse(_amountController.text),
        'description': _noteController.text,
        'date': selectedDate.toIso8601String(),
        // 'categorie_id': ... (nécessite l'ID de la table categories)
      });

      widget.onTransactionAdded();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Pour éviter le clavier
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

            // Sélecteur Income / Expense (Design Maquette)
            Container(
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(child: _buildToggleButton("Income", isIncome, const Color(0xFF2D6A4F), () => setState(() => isIncome = true))),
                  Expanded(child: _buildToggleButton("Expense", !isIncome, Colors.red, () => setState(() => isIncome = false))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel("Amount"),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: "FCFA ",
                filled: true,
                fillColor: Colors.grey[50]!,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 15),
            _buildLabel("Category"),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(filled: true, fillColor: Colors.grey[50]!, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => selectedCategory = val),
              hint: const Text("Select a category"),
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
                child: Row(children: [const Icon(LucideIcons.calendar, size: 20), const SizedBox(width: 10), Text(DateFormat('MMMM d, yyyy').format(selectedDate))]),
              ),
            ),

            const SizedBox(height: 15),
            _buildLabel("Note (optional)"),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(hintText: "Add a note...", filled: true, fillColor: Colors.grey[50]!, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text("Ajouter", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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