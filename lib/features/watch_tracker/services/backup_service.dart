import 'dart:convert';

import '../../../core/constants/watch_options.dart';
import '../models/backup_data.dart';
import '../models/watch_history_entry.dart';
import '../models/watch_item.dart';

class BackupService {
  const BackupService();

  String createBackupJson(
    List<WatchItem> items,
    List<WatchHistoryEntry> history,
  ) {
    final Map<String, dynamic> backup = <String, dynamic>{
      'metadata': <String, dynamic>{
        'app': 'TVtracker',
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'fields': WatchOptions.backupFields,
      },
      'items': items.map((WatchItem item) => item.toJson()).toList(),
      'history': history
          .map((WatchHistoryEntry entry) => entry.toJson())
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  BackupData parseBackupJson(String text) {
    final dynamic decoded = jsonDecode(text);
    final dynamic rawItems;
    dynamic rawHistory = const <dynamic>[];

    // Old backups were sometimes just a raw items array.
    if (decoded is List<dynamic>) {
      rawItems = decoded;
    } else if (decoded is Map && decoded['items'] is List<dynamic>) {
      rawItems = decoded['items'];
      if (decoded['history'] is List<dynamic>) {
        rawHistory = decoded['history'];
      }
    } else {
      throw const FormatException('No items array found.');
    }

    final List<WatchItem> items = (rawItems as List<dynamic>)
        .where((dynamic item) => item is Map)
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .map(WatchItem.fromJson)
        .where((WatchItem item) => item.name.isNotEmpty)
        .toList();

    if (items.isEmpty) {
      throw const FormatException('No valid items found.');
    }

    final List<WatchHistoryEntry> history = (rawHistory as List<dynamic>)
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

    return BackupData(items: items, history: history);
  }
}
