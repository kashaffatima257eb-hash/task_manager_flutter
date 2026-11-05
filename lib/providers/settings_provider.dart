import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  SoundOption sound = SoundOption.defaultSound;
  int accentIndex = 0;

  Color get accent => accentPalettes[accentIndex].color;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    themeMode = ThemeMode.values[p.getInt('theme') ?? 0];
    sound = SoundOption.values[p.getInt('sound') ?? 0];
    final a = p.getInt('accent') ?? 0;
    accentIndex = (a >= 0 && a < accentPalettes.length) ? a : 0;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setInt('theme', m.index);
  }

  Future<void> setSound(SoundOption s) async {
    sound = s;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setInt('sound', s.index);
  }

  Future<void> setAccent(int i) async {
    accentIndex = i;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setInt('accent', i);
  }
}
