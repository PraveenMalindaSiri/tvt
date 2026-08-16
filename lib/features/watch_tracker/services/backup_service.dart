import 'dart:convert';

import '../../../core/constants/watch_options.dart';
import '../models/backup_data.dart';
import '../models/watch_item.dart';

class BackupService {
  const BackupService();

  String createBackupJson(List<WatchItem> items) {
    final Map<String, dynamic> backup = <String, dynamic>{
      'metadata': <String, dynamic>{
        'app': 'TVtracker',
        'version': 3,
        'exportedAt': _dateText(DateTime.now()),
        'fields': WatchOptions.backupFields,
        'note': 'Date-only compact backup. Episode-by-episode history is not stored.',
      },
      'items': items.map((WatchItem item) => item.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  BackupData parseBackupJson(String text) {
    final dynamic decoded = jsonDecode(text);
    final dynamic rawItems;
    List<dynamic> rawHistory = const <dynamic>[];

    if (decoded is List<dynamic>) {
      rawItems = decoded;
    } else if (decoded is Map && decoded['items'] is List<dynamic>) {
      rawItems = decoded['items'];
      if (decoded['history'] is List<dynamic>) {
        rawHistory = decoded['history'] as List<dynamic>;
      }
    } else {
      throw const FormatException('No items array found.');
    }

    List<WatchItem> items = (rawItems as List<dynamic>)
        .where((dynamic item) => item is Map)
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .map(WatchItem.fromJson)
        .where((WatchItem item) => item.name.isNotEmpty)
        .toList();

    if (items.isEmpty) {
      throw const FormatException('No valid items found.');
    }

    // v2 backups may contain thousands of episode rows. We intentionally do
    // not keep those rows in v3. We only use the latest date per title to fill
    // missing last/completion dates.
    if (rawHistory.isNotEmpty) {
      final Map<String, DateTime> latestByItem = <String, DateTime>{};
      for (final dynamic raw in rawHistory) {
        if (raw is! Map) continue;
        final Map<String, dynamic> entry = Map<String, dynamic>.from(raw);
        final String itemId = (entry['itemId'] ?? '').toString();
        final DateTime? date = DateTime.tryParse((entry['watchedAt'] ?? '').toString());
        if (itemId.isEmpty || date == null) continue;
        final DateTime day = DateTime(date.toLocal().year, date.toLocal().month, date.toLocal().day);
        final DateTime? current = latestByItem[itemId];
        if (current == null || day.isAfter(current)) latestByItem[itemId] = day;
      }

      items = items.map((WatchItem item) {
        final DateTime? latest = latestByItem[item.id];
        if (latest == null) return item;
        return item.copyWith(
          lastWatchedAt: item.lastWatchedAt ?? latest,
          completedAt: item.status == WatchOptions.watchedStatus
              ? (item.completedAt ?? latest)
              : item.completedAt,
        );
      }).toList();
    }

    return BackupData(items: items);
  }

  String _dateText(DateTime value) {
    final DateTime local = value.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
