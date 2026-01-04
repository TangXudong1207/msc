import 'package:flutter/material.dart';

enum AppLanguage {
  chinese,
  english,
}

class LanguageProvider with ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.chinese;

  AppLanguage get currentLanguage => _currentLanguage;

  bool get isChinese => _currentLanguage == AppLanguage.chinese;

  void setLanguage(AppLanguage language) {
    _currentLanguage = language;
    notifyListeners();
  }

  void toggleLanguage() {
    _currentLanguage = _currentLanguage == AppLanguage.chinese
        ? AppLanguage.english
        : AppLanguage.chinese;
    notifyListeners();
  }

  // Helper for simple string localization
  String getText(String zh, String en) {
    return isChinese ? zh : en;
  }
}
