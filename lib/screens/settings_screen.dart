import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _addCategory(BuildContext context, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final controller = TextEditingController();
    final isExpense = type == 'expense';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isExpense ? 'Nuova Categoria Spesa' : 'Nuova Categoria Entrata'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome Categoria'),
          autofocus: true,
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
                  'createdAt': Timestamp.now(),
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  // Funzione per rinominare una categoria esistente
  Future<void> _editCategory(BuildContext context, String catId, String currentName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rinomina Categoria'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nuovo Nome'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('categories')
                    .doc(catId)
                    .update({'name': newName});
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Salva'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final langProvider = Provider.of<LanguageProvider>(context);
    final texts = langProvider.texts;

    return StreamBuilder<QuerySnapshot>(
      stream: user == null
          ? const Stream.empty()
          : FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('categories')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isEmpty && user != null) {
          final defaultCategories = [
            {'name': 'Cibo', 'type': 'expense'},
            {'name': 'Trasporti', 'type': 'expense'},
            {'name': 'Svago', 'type': 'expense'},
            {'name': 'Casa', 'type': 'expense'},
            {'name': 'Altro', 'type': 'expense'},
            {'name': 'Stipendio', 'type': 'income'},
            {'name': 'Regalo', 'type': 'income'},
            {'name': 'Vendita', 'type': 'income'},
            {'name': 'Bonus', 'type': 'income'},
          ];
          for (var cat in defaultCategories) {
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('categories')
                .add({...cat, 'createdAt': Timestamp.now()});
          }
        }

        final docs = snapshot.hasData ? snapshot.data!.docs : [];
        List<Map<String, dynamic>> expenseCats = [];
        List<Map<String, dynamic>> incomeCats = [];

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final item = {'id': doc.id, 'name': data['name'] ?? ''};
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
              // SEZIONE LINGUA (Ripristinata)
              const Text(
                "Lingua / Language",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Seleziona Lingua", style: TextStyle(fontWeight: FontWeight.w500)),
                      DropdownButton<bool>(
                        value: langProvider.isItalian, //
                        items: const [
                          DropdownMenuItem(value: true, child: Text('Italiano')),
                          DropdownMenuItem(value: false, child: Text('English')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            langProvider.toggleLanguage(val); //[cite: 6]
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // SEZIONE GESTIONE CATEGORIE
              const Text(
                "Gestione Categorie",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
                    return ListTile(
                      title: Text(cat['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                            onPressed: () => _editCategory(context, cat['id'], cat['name']),
                          ),
                          if (expenseCats.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                              onPressed: () => _deleteCategory(context, cat['id'], cat['name']),
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
                    return ListTile(
                      title: Text(cat['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                            onPressed: () => _editCategory(context, cat['id'], cat['name']),
                          ),
                          if (incomeCats.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                              onPressed: () => _deleteCategory(context, cat['id'], cat['name']),
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