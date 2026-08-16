import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/watch_options.dart';
import '../models/watch_history_entry.dart';
import '../models/watch_item.dart';

class WatchStorageService {
  const WatchStorageService();

  static const String _defaultBackupHandledKey =
      'simpleWatchTracker.defaultBackupHandled.v1';

  Future<List<WatchItem>> loadItems() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? v2Saved = prefs.getString(WatchOptions.storageKey);
    if (v2Saved != null) {
      return _decodeItems(v2Saved);
    }

    // Automatic one-time migration from the existing app data. We do not
    // delete the old key, so the original data remains available as a fallback.
    final String? legacySaved = prefs.getString(WatchOptions.legacyStorageKey);
    if (legacySaved == null) return <WatchItem>[];

    final List<WatchItem> migrated = _decodeItems(legacySaved);
    if (migrated.isNotEmpty) {
      await saveItems(migrated);
    }
    return migrated;
  }

  Future<List<WatchHistoryEntry>> loadHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(WatchOptions.historyStorageKey);
    if (saved == null) return <WatchHistoryEntry>[];

    try {
      final dynamic decoded = jsonDecode(saved);
      if (decoded is! List<dynamic>) return <WatchHistoryEntry>[];

      final List<WatchHistoryEntry> history = decoded
          .where((dynamic item) => item is Map)
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .map(WatchHistoryEntry.fromJson)
          .where((WatchHistoryEntry entry) =>
              entry.itemId.isNotEmpty && entry.itemName.isNotEmpty)
          .toList();

      history.sort(
        (WatchHistoryEntry a, WatchHistoryEntry b) =>
            b.watchedAt.compareTo(a.watchedAt),
      );
      return history;
    } catch (_) {
      return <WatchHistoryEntry>[];
    }
  }


  Future<bool> isDefaultBackupHandled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_defaultBackupHandledKey) ?? false;
  }

  Future<void> markDefaultBackupHandled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_defaultBackupHandledKey, true);
  }

  Future<void> saveItems(List<WatchItem> items) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String data =
        jsonEncode(items.map((WatchItem item) => item.toJson()).toList());
    await prefs.setString(WatchOptions.storageKey, data);
  }

  Future<void> saveHistory(List<WatchHistoryEntry> history) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(
      history.map((WatchHistoryEntry entry) => entry.toJson()).toList(),
    );
    await prefs.setString(WatchOptions.historyStorageKey, data);
  }

  List<WatchItem> _decodeItems(String text) {
    try {
      final dynamic decoded = jsonDecode(text);
      if (decoded is! List<dynamic>) return <WatchItem>[];
      return decoded
          .where((dynamic item) => item is Map)
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .map(WatchItem.fromJson)
          .where((WatchItem item) => item.name.isNotEmpty)
          .toList();
    } catch (_) {
      return <WatchItem>[];
    }
  }
}
