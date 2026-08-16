import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/watch_options.dart';
import '../models/watch_item.dart';

class WatchStorageService {
  const WatchStorageService();

  static const String _defaultBackupHandledKey =
      'simpleWatchTracker.defaultBackupHandled.v1';

  Future<List<WatchItem>> loadItems() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? v3Saved = prefs.getString(WatchOptions.storageKey);
    if (v3Saved != null) return _decodeItems(v3Saved);

    // One-time migration from v2, then v1.
    final String? v2Saved = prefs.getString(WatchOptions.legacyV2StorageKey);
    if (v2Saved != null) {
      final List<WatchItem> migrated = _decodeItems(v2Saved);
      if (migrated.isNotEmpty) await saveItems(migrated);
      return migrated;
    }

    final String? v1Saved = prefs.getString(WatchOptions.legacyStorageKey);
    if (v1Saved == null) return <WatchItem>[];
    final List<WatchItem> migrated = _decodeItems(v1Saved);
    if (migrated.isNotEmpty) await saveItems(migrated);
    return migrated;
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
