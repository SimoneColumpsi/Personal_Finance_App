import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

// Lista di colori predefiniti tra cui scegliere facilmente
final List<Color> availableCategoryColors = [
  Colors.blue,
  Colors.purple,
  Colors.orange,
  Colors.teal,
  Colors.pink,
  Colors.amber,
  Colors.indigo,
  Colors.brown,
  Colors.deepOrange,
  Colors.blueGrey,
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _addCategory(BuildContext context, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final controller = TextEditingController();
    Color selectedColor = availableCategoryColors.first;
    final isExpense = type == 'expense';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isExpense ? 'Nuova Categoria Spesa' : 'Nuova Categoria Entrata'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Nome Categoria'),
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                const Text("Scegli Colore:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableCategoryColors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annulla')),
              ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('categories')
                        .add({
                      'name': name,
                      'type': type,
                      'color': colorToHex(selectedColor),
                      'createdAt': Timestamp.now(),
                    });
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('Aggiungi'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editCategory(BuildContext context, String catId, String currentName, String currentColorHex) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final controller = TextEditingController(text: currentName);
    Color selectedColor = hexToColor(currentColorHex);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Modifica Categoria'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Nome Categoria'),
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                const Text("Scegli Colore:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableCategoryColors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annulla')),
              ElevatedButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('categories')
                        .doc(catId)
                        .update({
                      'name': newName,
                      'color': colorToHex(selectedColor),
                    });
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('Salva'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteCategory(BuildContext context, String catId, String catName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Elimina "$catName"?'),
        content: const Text('La categoria verrà rimossa dalle opzioni disponibili.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Elimina', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(catId)
          .delete();
    }
  }

  // Utility per convertire Color in Hex String
  static String colorToHex(Color color) {
    return color.value.toRadixString(16);
  }

  // Utility per convertire Hex String in Color
  static Color hexToColor(String hexString) {
    try {
      final buffer = StringBuffer(); // <-- Ecco l'inizializzazione mancante
      if (hexString.length == 6 || hexString.length == 7) {
        buffer.write('ff');
      }
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blue; // Colore di fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final langProvider = Provider.of<LanguageProvider>(context);

    return StreamBuilder<QuerySnapshot>(
      stream: user == null
          ? const Stream.empty()
          : FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('categories')
              .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.hasData ? snapshot.data!.docs : [];
        List<Map<String, dynamic>> expenseCats = [];
        List<Map<String, dynamic>> incomeCats = [];

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final item = {
            'id': doc.id,
            'name': data['name'] ?? '',
            'color': data['color'] ?? '2196f3', // blu di default
          };
          if (data['type'] == 'income') {
            incomeCats.add(item);
          } else {
            expenseCats.add(item);
          }
        }

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text("Gestione Categorie", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // SPESE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Categorie Spese", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                  TextButton.icon(
                    onPressed: () => _addCategory(context, 'expense'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Aggiungi'),
                  ),
                ],
              ),
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenseCats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final cat = expenseCats[i];
                    final catColor = hexToColor(cat['color']);
                    return ListTile(
                      leading: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                      ),
                      title: Text(cat['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                            onPressed: () => _editCategory(context, cat['id'], cat['name'], cat['color']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                            onPressed: () => _deleteCategory(context, cat['id'], cat['name']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ENTRATE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Categorie Entrate", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                  TextButton.icon(
                    onPressed: () => _addCategory(context, 'income'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Aggiungi'),
                  ),
                ],
              ),
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: incomeCats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final cat = incomeCats[i];
                    final catColor = hexToColor(cat['color']);
                    return ListTile(
                      leading: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                      ),
                      title: Text(cat['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                            onPressed: () => _editCategory(context, cat['id'], cat['name'], cat['color']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                            onPressed: () => _deleteCategory(context, cat['id'], cat['name']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}