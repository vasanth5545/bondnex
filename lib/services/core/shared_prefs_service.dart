import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SharedPrefsService {
  static const String _searchHistoryKeyPrefix = 'search_history_';

  // Custom encoder to handle Timestamp and DateTime
  static dynamic _customEncoder(dynamic item) {
    if (item is Timestamp) {
      return item.toDate().toIso8601String();
    } else if (item is DateTime) {
      return item.toIso8601String();
    }
    return item;
  }

  // Save a search result locally
  static Future<void> saveLocalSearch(
    String currentUid,
    Map<String, dynamic> userData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_searchHistoryKeyPrefix$currentUid';

    List<String> historyStrings = prefs.getStringList(key) ?? [];

    // Check if it already exists, if so, remove it to move it to the top
    historyStrings.removeWhere((item) {
      final map = json.decode(item);
      return map['uid'] == userData['uid'] ||
          map['premium_id'] == userData['premium_id'];
    });

    historyStrings.insert(
      0,
      json.encode(userData, toEncodable: _customEncoder),
    );

    // Keep only the last 20 searches
    if (historyStrings.length > 20) {
      historyStrings = historyStrings.sublist(0, 20);
    }

    await prefs.setStringList(key, historyStrings);
  }

  // Get local search history
  static Future<List<Map<String, dynamic>>> getLocalSearchHistory(
    String currentUid,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_searchHistoryKeyPrefix$currentUid';

    List<String> historyStrings = prefs.getStringList(key) ?? [];

    return historyStrings
        .map((item) => json.decode(item) as Map<String, dynamic>)
        .toList();
  }

  // Delete a specific search result locally
  static Future<void> deleteLocalSearch(
    String currentUid,
    String searchedUidOrPremiumId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_searchHistoryKeyPrefix$currentUid';

    List<String> historyStrings = prefs.getStringList(key) ?? [];

    historyStrings.removeWhere((item) {
      final map = json.decode(item);
      return map['uid'] == searchedUidOrPremiumId ||
          map['premium_id'] == searchedUidOrPremiumId;
    });

    await prefs.setStringList(key, historyStrings);
  }
}
