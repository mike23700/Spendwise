import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart'; 
import '../providers/user_provider.dart';
import '../models/category.dart';

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
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _setDefaultCategory());
  }

  void _setDefaultCategory() {
    final userStore = Provider.of<UserProvider>(context, listen: false);
    final categories =
        isIncome ? userStore.incomeCategories : userStore.expenseCategories;

    setState(() {
      _selectedCategory = categories.isNotEmpty ? categories[0] : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserProvider>();
    final categories =
        isIncome ? userStore.incomeCategories : userStore.expenseCategories;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true, //safe area pour les bouton de navigation
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
              // Barre de drag
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Sélecteur Type
              Row(
                children: [
                  _buildTypeTab("Revenu", true, const Color(0xFF2D6A4F)),
                  const SizedBox(width: 10),
                  _buildTypeTab("Dépense", false, Colors.red),
                ],
              ),
              const SizedBox(height: 25),

              // Montant
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 18),
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

              // Catégorie
              DropdownButtonFormField<Category>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: "Catégorie",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text("${cat.emoji ?? '📁'}  ${cat.name}"),
                  );
                }).toList(),
                onChanged: (val) =>
                    setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 15),

              _buildDatePicker(),
              const SizedBox(height: 15),

              // Note
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

              // Bouton enregistrer
              ElevatedButton(
                onPressed: _isSaving ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Enregistrer",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab(String label, bool value, Color activeColor) {
    final isSelected = isIncome == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (isIncome != value) {
            setState(() => isIncome = value);
            _setDefaultCategory();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
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

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
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
            const Icon(LucideIcons.calendar,
                size: 20, color: Colors.grey),
            const SizedBox(width: 10),
            Text(DateFormat('dd MMMM yyyy', 'fr_FR')
                .format(selectedDate)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    final amountText =
        _amountController.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer un montant valide")),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sélectionnez une catégorie")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final success =
          await context.read<UserProvider>().addTransaction(
                montant: amount,
                type: isIncome ? 'revenu' : 'depense',
                categorieId: _selectedCategory!.id,
                date: selectedDate,
                description: _noteController.text.trim(),
              );

      if (success && mounted) {
        widget.onTransactionAdded();
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
