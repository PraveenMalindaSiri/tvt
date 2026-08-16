import 'watch_history_entry.dart';
import 'watch_item.dart';

class BackupData {
  const BackupData({
    required this.items,
    required this.history,
  });

  final List<WatchItem> items;
  final List<WatchHistoryEntry> history;
}
