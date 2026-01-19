import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AddTransactionSheet extends StatefulWidget {
  final VoidCallback onTransactionAdded;
  const AddTransactionSheet({super.key, required this.onTransactionAdded});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  bool isIncome = true;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool _isSaving = false;
  Map<String, dynamic>? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setDefaultCategory());
  }

  void _setDefaultCategory() {
    final store = Provider.of<UserProvider>(context, listen: false);
    final categories =
        isIncome ? store.incomeCategories : store.expenseCategories;
    if (categories.isNotEmpty) {
      setState(() => _selectedCategory = categories[0]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserProvider>();
    final categories =
        isIncome ? store.incomeCategories : store.expenseCategories;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Sélecteur Revenu / Dépense
            Row(
              children: [
                _buildTypeTab("Revenu", true, const Color(0xFF2D6A4F)),
                const SizedBox(width: 10),
                _buildTypeTab("Dépense", false, Colors.red),
              ],
            ),
            const SizedBox(height: 25),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: "Montant",
                prefixText: "FCFA ",
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<Map<String, dynamic>>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: "Catégorie",
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              items:
                  categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text("${cat['emoji'] ?? '📁'}  ${cat['nom']}"),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 15),

            _buildDatePicker(),
            const SizedBox(height: 15),

            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: "Note (optionnel)",
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _isSaving ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child:
                  _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        "Ajouter",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) setState(() => selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.calendar,
              size: 20,
              color: Color(0xFF2D6A4F),
            ),
            const SizedBox(width: 10),
            Text(DateFormat('dd MMMM yyyy', 'fr_FR').format(selectedDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(String label, bool value, Color activeColor) {
    bool isSelected = isIncome == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => isIncome = value);
          _setDefaultCategory();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty || _selectedCategory == null) return;
    setState(() => _isSaving = true);
    try {
      final userProvider = context.read<UserProvider>();
      final success = await userProvider.addTransaction(
        montant: double.parse(_amountController.text),
        type: isIncome ? 'revenu' : 'depense',
        categorieId: _selectedCategory!['id'],
        date: selectedDate,
        description: _noteController.text.trim(),
      );

      if (success && mounted) {
        widget.onTransactionAdded();
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Erreur: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
