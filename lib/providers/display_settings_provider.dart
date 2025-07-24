// File: lib/providers/display_settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NameSortOrder { firstNameFirst, lastNameFirst }

class DisplaySettingsProvider extends ChangeNotifier {
  NameSortOrder _sortOrder = NameSortOrder.firstNameFirst;

  NameSortOrder get sortOrder => _sortOrder;

  DisplaySettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final sortOrderIndex = prefs.getInt('nameSortOrder') ?? 0;
    _sortOrder = NameSortOrder.values[sortOrderIndex];
    notifyListeners();
  }

  Future<void> setSortOrder(NameSortOrder newOrder) async {
    _sortOrder = newOrder;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nameSortOrder', newOrder.index);
    notifyListeners();
  }
}
