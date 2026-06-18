import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  bool _isItalian = true;

  bool get isItalian => _isItalian;

  Map<String, String> get texts {
    if (_isItalian) {
      return {
        'app_title': 'LE MIE SPESE',
        'balance_title': 'ANALISI SALDO',
        'stats_title': 'STATISTICHE',
        'settings_title': 'IMPOSTAZIONI',
      };
    } else {
      return {
        'app_title': 'MY EXPENSES',
        'balance_title': 'BALANCE ANALYSIS',
        'stats_title': 'STATISTICS',
        'settings_title': 'SETTINGS',
      };
    }
  }

  void toggleLanguage(bool value) {
    _isItalian = value;
    notifyListeners();
  }
}