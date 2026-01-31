import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../models/transaction.dart';

class ListTab extends StatelessWidget {
  const ListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserProvider>();
    final sortedKeys = store.groupedTransactions.keys.toList();

    if (sortedKeys.isEmpty && !store.isLoading) {
      return const Center(
        child: Text(
          "Aucune transaction pour le moment.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: sortedKeys.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        String date = sortedKeys[index];
        return _DayGroupWidget(
          date: date,
          items: store.groupedTransactions[date]!,
        );
      },
    );
  }
}

class _DayGroupWidget extends StatefulWidget {
  final String date;
  final List<Transaction> items;
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
      double mnt = item.amount;
      if (item.type == 'revenu') {
        dayRev += mnt;
      } else if (item.type == 'depense') {
        dayDep += mnt;
      }
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
                Text(
                  DateFormat('dd', 'fr_FR').format(dt),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    DateFormat('E', 'fr_FR').format(dt).toLowerCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                SizedBox(
                  width: 90,
                  child: Text(
                    "FCFA ${dayRev.toInt()}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 90,
                  child: Text(
                    "FCFA ${dayDep.toInt()}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          ...widget.items.map((tx) => _TransactionDetailTile(tx: tx)),
      ],
    );
  }
}


class _TransactionDetailTile extends StatelessWidget {
  final Transaction tx;
  const _TransactionDetailTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    bool isRev = tx.type == 'revenu';

    // Récupération sécurisée du nom et de l'emoji
    String categoryName = tx.category?.name ?? 'Autre';
    String emoji = tx.category?.emoji ?? '📁';

    String? note = tx.description;
    String transactionId = tx.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          // Colonne Catégorie
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: const TextStyle(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Colonne Note / Source
          Expanded(
            flex: 3,
            child: Column(
              children: [
                if (note != null && note.isNotEmpty)
                  Text(
                    note,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                const Text(
                  "Portefeuille",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Colonne Montant
          Expanded(
            flex: 2,
            child: Text(
              "FCFA ${tx.amount.toInt()}",
              style: TextStyle(
                color: isRev ? Colors.indigo : Colors.redAccent,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // Menu actions
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditTransactionDialog(context, tx);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, transactionId);
                }
              },
              itemBuilder:
                  (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Éditer'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                  ],
              icon: const Icon(Icons.more_vert, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTransactionDialog(BuildContext context, Transaction tx) {
    final montantController = TextEditingController(text: tx.amount.toString());
    final descriptionController = TextEditingController(
      text: tx.description ?? '',
    );

    DateTime selectedDate = tx.date;
    String selectedType = tx.type;
    String selectedCategoryId = tx.category?.id ?? '';

    showDialog(
      context: context,
      builder:
          (context) => _EditTransactionDialog(
            transactionId: tx.id,
            montantController: montantController,
            descriptionController: descriptionController,
            selectedDate: selectedDate,
            selectedType: selectedType,
            selectedCategoryId: selectedCategoryId,
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String transactionId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer la transaction'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette transaction ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  context.read<UserProvider>().deleteTransaction(transactionId);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction supprimée'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}

class _EditTransactionDialog extends StatefulWidget {
  final String transactionId;
  final TextEditingController montantController;
  final TextEditingController descriptionController;
  final DateTime selectedDate;
  final String selectedType;
  final String selectedCategoryId;

  const _EditTransactionDialog({
    required this.transactionId,
    required this.montantController,
    required this.descriptionController,
    required this.selectedDate,
    required this.selectedType,
    required this.selectedCategoryId,
  });

  @override
  State<_EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<_EditTransactionDialog> {
  late DateTime _selectedDate;
  late String _selectedType;
  late String _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _selectedType = widget.selectedType;
    _selectedCategoryId = widget.selectedCategoryId;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final categories =
        _selectedType == 'revenu'
            ? provider.incomeCategories
            : provider.expenseCategories;

    return AlertDialog(
      title: const Text('Éditer la transaction'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widget.montantController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'revenu', child: Text('Revenu')),
                const DropdownMenuItem(
                  value: 'depense',
                  child: Text('Dépense'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    _selectedCategoryId = '';
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue:
                  _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
              ),
              items:
                  categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategoryId = value);
                }
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(
                'Date: ${DateFormat('dd/MM/yyyy', 'fr_FR').format(_selectedDate)}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  locale: const Locale('fr', 'FR'),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed:
              _isLoading
                  ? null
                  : () async {
                    setState(() => _isLoading = true);
                    final success = await context
                        .read<UserProvider>()
                        .updateTransaction(
                          transactionId: widget.transactionId,
                          montant:
                              double.tryParse(widget.montantController.text) ??
                              0,
                          type: _selectedType,
                          categorieId: _selectedCategoryId,
                          date: _selectedDate,
                          description: widget.descriptionController.text,
                        );

                    if (mounted) {
                      Navigator.pop(context);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transaction mise à jour'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.read<UserProvider>().lastError ??
                                  'Erreur lors de la mise à jour',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
          child:
              _isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Mettre à jour'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    widget.montantController.dispose();
    widget.descriptionController.dispose();
    super.dispose();
  }
}
