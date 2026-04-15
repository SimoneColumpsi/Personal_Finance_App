import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'Italiano';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const SizedBox(height: 20),
          // SEZIONE LINGUA
          ListTile(
            leading: const Icon(Icons.language, color: Colors.teal),
            title: const Text("Lingua"),
            subtitle: Text("Selezionata: $_selectedLanguage"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showLanguageDialog();
            },
          ),
          const Divider(),
          
          // SPAZIO PER FUTURE IMPOSTAZIONI
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            title: const Text("Informazioni App"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Personal Finance App",
                applicationVersion: "1.0.0",
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Seleziona Lingua"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption("Italiano"),
            _languageOption("English"),
            _languageOption("Français"),
            _languageOption("Español"),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(String lang) {
    return RadioListTile<String>(
      title: Text(lang),
      value: lang,
      groupValue: _selectedLanguage,
      onChanged: (value) {
        setState(() {
          _selectedLanguage = value!;
        });
        Navigator.of(context).pop();
      },
    );
  }
}