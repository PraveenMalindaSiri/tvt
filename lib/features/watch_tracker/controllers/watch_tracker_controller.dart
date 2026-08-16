import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/watch_options.dart';
import '../models/backup_data.dart';
import '../models/watch_filter.dart';
import '../models/watch_history_entry.dart';
import '../models/watch_item.dart';
import '../services/backup_service.dart';
import '../services/watch_storage_service.dart';

class WatchTrackerController extends ChangeNotifier {
  WatchTrackerController({
    required WatchStorageService storageService,
    required BackupService backupService,
  })  : _storageService = storageService,
        _backupService = backupService;

  final WatchStorageService _storageService;
  final BackupService _backupService;

  List<WatchItem> _items = <WatchItem>[];
  List<WatchHistoryEntry> _history = <WatchHistoryEntry>[];
  List<WatchItem> _itemsView = const <WatchItem>[];
  List<WatchItem> _visibleItems = const <WatchItem>[];
  List<WatchItem> _continueWatching = const <WatchItem>[];
  List<WatchItem> _watchNextItems = const <WatchItem>[];
  List<WatchHistoryEntry> _recentHistory = const <WatchHistoryEntry>[];
  Map<String, int> _statusCounts = const <String, int>{};
  WatchFilter _filter = const WatchFilter();
  bool _isLoading = true;

  List<WatchItem> get items => _itemsView;
  List<WatchHistoryEntry> get history => List<WatchHistoryEntry>.unmodifiable(_history);
  WatchFilter get filter => _filter;
  bool get isLoading => _isLoading;
  List<WatchItem> get visibleItems => _visibleItems;
  List<WatchItem> get continueWatching => _continueWatching;
  List<WatchItem> get watchNextItems => _watchNextItems;
  List<WatchHistoryEntry> get recentHistory => _recentHistory;

  int get episodesWatched => _history
      .where((WatchHistoryEntry entry) => entry.isEpisode)
      .length;

  int get watchedMovies => _items
      .where((WatchItem item) =>
          item.isMovie && item.status == WatchOptions.watchedStatus)
      .length;

  int get watchTimeMinutes => _history.fold<int>(
        0,
        (int total, WatchHistoryEntry entry) =>
            total + (entry.runtimeMinutes ?? 0),
      );

  Future<void> init() async {
    _setLoading(true);

    try {
      _items = await _storageService.loadItems();
      _history = await _storageService.loadHistory();

      final bool defaultBackupHandled =
          await _storageService.isDefaultBackupHandled();

      if (!defaultBackupHandled) {
        if (_items.isEmpty && _history.isEmpty) {
          await loadDefaultBackup();
        } else {
          // Existing users keep their current data. The bundled backup should
          // never overwrite an already-used installation automatically.
          await _storageService.markDefaultBackupHandled();
        }
      }

      _sortHistory();
      _rebuildDerivedState();
    } finally {
      _setLoading(false);
    }
  }

  Future<int> loadDefaultBackup() async {
    final String text =
        await rootBundle.loadString('assets/data/backup.json');
    final BackupData imported = _backupService.parseBackupJson(text);

    _items = imported.items;
    _history = imported.history;
    _sortHistory();
    await _saveAllAndNotify();
    await _storageService.markDefaultBackupHandled();

    return imported.items.length;
  }

  WatchItem? findItem(String id) {
    for (final WatchItem item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<WatchHistoryEntry> historyForItem(String itemId) {
    return _history
        .where((WatchHistoryEntry entry) => entry.itemId == itemId)
        .toList(growable: false);
  }

  int countByStatus(String status) => _statusCounts[status] ?? 0;

  Future<void> addItem({
    required String name,
    required String category,
    String status = WatchOptions.defaultStatus,
    bool watchNext = false,
  }) async {
    final String cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final WatchItem item = WatchItem.create(
      name: cleanName,
      category: category,
      status: status,
      watchNext: watchNext,
    );

    _items = <WatchItem>[item, ..._items];
    await _saveItemsAndNotify();
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required String category,
    required String status,
    int? runtimeMinutes,
    bool clearRuntimeMinutes = false,
  }) async {
    final String cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final DateTime now = DateTime.now();
    _items = _items.map((WatchItem item) {
      if (item.id != id) return item;
      return item.copyWith(
        name: cleanName,
        category: category,
        status: status,
        watchNext: status == WatchOptions.watchedStatus ? false : item.watchNext,
        runtimeMinutes: runtimeMinutes,
        clearRuntimeMinutes: clearRuntimeMinutes,
        updatedAt: now,
      );
    }).toList();

    await _saveItemsAndNotify();
  }

  Future<void> setStatus(String id, String status) async {
    final DateTime now = DateTime.now();
    _items = _items.map((WatchItem item) {
      if (item.id != id) return item;
      return item.copyWith(
        status: status,
        watchNext: status == WatchOptions.watchedStatus ? false : item.watchNext,
        updatedAt: now,
      );
    }).toList();
    await _saveItemsAndNotify();
  }

  Future<void> toggleWatchNext(String id) async {
    final WatchItem? selected = findItem(id);
    if (selected == null || selected.status == WatchOptions.watchedStatus) return;
    final DateTime now = DateTime.now();
    _items = _items.map((WatchItem item) {
      if (item.id != id) return item;
      return item.copyWith(
        watchNext: !item.watchNext,
        updatedAt: now,
      );
    }).toList();
    await _saveItemsAndNotify();
  }

  Future<void> setProgress({
    required String id,
    required int season,
    required int episode,
  }) async {
    final DateTime now = DateTime.now();
    _items = _items.map((WatchItem item) {
      if (item.id != id) return item;
      return item.copyWith(
        currentSeason: season,
        currentEpisode: episode,
        status: episode > 0 ? WatchOptions.watchingStatus : item.status,
        updatedAt: now,
      );
    }).toList();
    await _saveItemsAndNotify();
  }

  Future<void> incrementEpisode(String id) async {
    final WatchItem? item = findItem(id);
    if (item == null || !item.isEpisodic) return;

    final DateTime now = DateTime.now();
    final int nextEpisode = item.currentEpisode + 1;

    final WatchHistoryEntry entry = WatchHistoryEntry.episode(
      itemId: item.id,
      itemName: item.name,
      category: item.category,
      season: item.currentSeason,
      episode: nextEpisode,
      previousStatus: item.status,
      previousSeason: item.currentSeason,
      previousEpisode: item.currentEpisode,
      runtimeMinutes: item.runtimeMinutes,
      watchedAt: now,
    );

    _history = <WatchHistoryEntry>[entry, ..._history];
    _items = _items.map((WatchItem current) {
      if (current.id != id) return current;
      return current.copyWith(
        currentEpisode: nextEpisode,
        status: WatchOptions.watchingStatus,
        lastWatchedAt: now,
        updatedAt: now,
      );
    }).toList();

    await _saveAllAndNotify();
  }

  Future<void> markMovieWatched(String id) async {
    final WatchItem? item = findItem(id);
    if (item == null || !item.isMovie) return;

    final DateTime now = DateTime.now();
    final WatchHistoryEntry entry = WatchHistoryEntry.movie(
      itemId: item.id,
      itemName: item.name,
      category: item.category,
      previousStatus: item.status,
      runtimeMinutes: item.runtimeMinutes,
      watchedAt: now,
    );

    _history = <WatchHistoryEntry>[entry, ..._history];
    _items = _items.map((WatchItem current) {
      if (current.id != id) return current;
      return current.copyWith(
        status: WatchOptions.watchedStatus,
        watchedAt: now,
        lastWatchedAt: now,
        updatedAt: now,
        watchNext: false,
      );
    }).toList();

    await _saveAllAndNotify();
  }

  Future<bool> undoLastWatch(String itemId) async {
    WatchHistoryEntry? latest;
    for (final WatchHistoryEntry entry in _history) {
      if (entry.itemId == itemId) {
        latest = entry;
        break;
      }
    }
    if (latest == null) return false;

    final WatchHistoryEntry entry = latest;
    _history = _history
        .where((WatchHistoryEntry current) => current.id != entry.id)
        .toList();

    WatchHistoryEntry? previousRecord;
    for (final WatchHistoryEntry current in _history) {
      if (current.itemId == itemId) {
        previousRecord = current;
        break;
      }
    }

    final DateTime now = DateTime.now();
    _items = _items.map((WatchItem item) {
      if (item.id != itemId) return item;

      if (entry.isEpisode) {
        return item.copyWith(
          status: entry.previousStatus,
          currentSeason: entry.previousSeason ?? item.currentSeason,
          currentEpisode: entry.previousEpisode ?? item.currentEpisode,
          lastWatchedAt: previousRecord?.watchedAt,
          clearLastWatchedAt: previousRecord == null,
          updatedAt: now,
        );
      }

      return item.copyWith(
        status: entry.previousStatus,
        lastWatchedAt: previousRecord?.watchedAt,
        clearLastWatchedAt: previousRecord == null,
        watchedAt: previousRecord?.isMovie == true ? previousRecord?.watchedAt : null,
        clearWatchedAt: previousRecord?.isMovie != true,
        updatedAt: now,
      );
    }).toList();

    await _saveAllAndNotify();
    return true;
  }

  Future<void> deleteItem(String id) async {
    _items = _items.where((WatchItem item) => item.id != id).toList();
    // Keep history as a diary even if a title is removed from the library.
    await _saveItemsAndNotify();
  }

  Future<void> deleteAll() async {
    _items = <WatchItem>[];
    _history = <WatchHistoryEntry>[];
    await _saveAllAndNotify();
  }

  String exportBackupJson() {
    return _backupService.createBackupJson(_items, _history);
  }

  int countBackupItems(String text) {
    return _backupService.parseBackupJson(text).items.length;
  }

  Future<int> importBackup(String text) async {
    final BackupData imported = _backupService.parseBackupJson(text);
    _items = imported.items;
    _history = imported.history;
    _sortHistory();
    await _saveAllAndNotify();
    return imported.items.length;
  }

  void setSearchQuery(String value) {
    if (_filter.searchQuery == value) return;
    _filter = _filter.copyWith(searchQuery: value);
    _rebuildDerivedState();
    notifyListeners();
  }

  void setCategoryFilter(String? value) {
    final String category = value ?? WatchOptions.allFilter;
    if (_filter.category == category) return;
    _filter = _filter.copyWith(category: category);
    _rebuildDerivedState();
    notifyListeners();
  }

  void setStatusFilter(String? value) {
    final String status = value ?? WatchOptions.allFilter;
    if (_filter.status == status) return;
    _filter = _filter.copyWith(status: status);
    _rebuildDerivedState();
    notifyListeners();
  }

  void clearFilters() {
    if (!_filter.hasActiveFilters) return;
    _filter = const WatchFilter();
    _rebuildDerivedState();
    notifyListeners();
  }

  Future<void> _saveItemsAndNotify() async {
    _rebuildDerivedState();
    notifyListeners();
    await _storageService.saveItems(_items);
  }

  Future<void> _saveAllAndNotify() async {
    _sortHistory();
    _rebuildDerivedState();
    notifyListeners();
    await Future.wait<void>(<Future<void>>[
      _storageService.saveItems(_items),
      _storageService.saveHistory(_history),
    ]);
  }

  void _sortHistory() {
    _history.sort(
      (WatchHistoryEntry a, WatchHistoryEntry b) =>
          b.watchedAt.compareTo(a.watchedAt),
    );
  }

  void _rebuildDerivedState() {
    _itemsView = List<WatchItem>.unmodifiable(_items);

    final Map<String, int> counts = <String, int>{
      for (final String status in WatchOptions.statuses) status: 0,
    };
    for (final WatchItem item in _items) {
      counts[item.status] = (counts[item.status] ?? 0) + 1;
    }
    _statusCounts = Map<String, int>.unmodifiable(counts);

    final List<WatchItem> filtered = _items.where(_filter.matches).toList()
      ..sort(_compareByName);
    _visibleItems = List<WatchItem>.unmodifiable(filtered);

    final List<WatchItem> watching = _items
        .where((WatchItem item) =>
            item.status == WatchOptions.watchingStatus)
        .toList()
      ..sort(_compareContinueWatching);
    _continueWatching = List<WatchItem>.unmodifiable(watching.take(12));

    final List<WatchItem> next = _items
        .where((WatchItem item) =>
            item.watchNext && item.status != WatchOptions.watchedStatus)
        .toList()
      ..sort(_compareByUpdatedThenName);
    _watchNextItems = List<WatchItem>.unmodifiable(next.take(12));

    _recentHistory = List<WatchHistoryEntry>.unmodifiable(_history.take(12));
  }

  int _compareByName(WatchItem a, WatchItem b) {
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  int _compareContinueWatching(WatchItem a, WatchItem b) {
    if (a.watchNext != b.watchNext) return a.watchNext ? -1 : 1;
    final DateTime aDate = a.lastWatchedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final DateTime bDate = b.lastWatchedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final int dateCompare = bDate.compareTo(aDate);
    return dateCompare != 0 ? dateCompare : _compareByName(a, b);
  }

  int _compareByUpdatedThenName(WatchItem a, WatchItem b) {
    final DateTime aDate = a.updatedAt ?? a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final DateTime bDate = b.updatedAt ?? b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final int dateCompare = bDate.compareTo(aDate);
    return dateCompare != 0 ? dateCompare : _compareByName(a, b);
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
