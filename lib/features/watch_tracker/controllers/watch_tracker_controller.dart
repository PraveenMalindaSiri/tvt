import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/watch_options.dart';
import '../models/backup_data.dart';
import '../models/watch_filter.dart';
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
  List<WatchItem> _itemsView = const <WatchItem>[];
  List<WatchItem> _visibleItems = const <WatchItem>[];
  List<WatchItem> _continueWatching = const <WatchItem>[];
  List<WatchItem> _watchNextItems = const <WatchItem>[];
  List<WatchItem> _recentlyCompleted = const <WatchItem>[];
  Map<String, int> _statusCounts = const <String, int>{};
  Map<String, int> _categoryCounts = const <String, int>{};
  WatchFilter _filter = const WatchFilter();
  bool _isLoading = true;

  List<WatchItem> get items => _itemsView;
  WatchFilter get filter => _filter;
  bool get isLoading => _isLoading;
  List<WatchItem> get visibleItems => _visibleItems;
  List<WatchItem> get continueWatching => _continueWatching;
  List<WatchItem> get watchNextItems => _watchNextItems;
  List<WatchItem> get recentlyCompleted => _recentlyCompleted;

  int countByStatus(String status) => _statusCounts[status] ?? 0;
  int countByCategory(String category) => _categoryCounts[category] ?? 0;

  Future<void> init() async {
    _setLoading(true);
    try {
      _items = await _storageService.loadItems();
      final bool defaultBackupHandled =
          await _storageService.isDefaultBackupHandled();

      if (!defaultBackupHandled) {
        if (_items.isEmpty) {
          await loadDefaultBackup();
        } else {
          await _storageService.markDefaultBackupHandled();
        }
      }
      _rebuildDerivedState();
    } finally {
      _setLoading(false);
    }
  }

  Future<int> loadDefaultBackup() async {
    final String text = await rootBundle.loadString('assets/data/backup.json');
    final BackupData imported = _backupService.parseBackupJson(text);
    _items = imported.items;
    await _saveItemsAndNotify();
    await _storageService.markDefaultBackupHandled();
    return imported.items.length;
  }

  WatchItem? findItem(String id) {
    for (final WatchItem item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> addItem({
    required String name,
    required String category,
    String status = WatchOptions.defaultStatus,
    bool watchNext = false,
    List<int> seasonEpisodeCounts = const <int>[],
  }) async {
    final String cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final WatchItem item = WatchItem.create(
      name: cleanName,
      category: category,
      status: status,
      watchNext: watchNext,
      seasonEpisodeCounts: seasonEpisodeCounts,
    );
    _items = <WatchItem>[item, ..._items];
    await _saveItemsAndNotify();
  }

  Future<String?> updateItem({
    required String id,
    required String name,
    required String category,
    required String status,
    List<int>? seasonEpisodeCounts,
  }) async {
    final WatchItem? old = findItem(id);
    final String cleanName = name.trim();
    if (old == null || cleanName.isEmpty) return 'Title name is required.';

    final bool movie = category == 'Movie';
    List<int> counts = movie
        ? const <int>[]
        : (seasonEpisodeCounts ?? old.seasonEpisodeCounts);
    if (!movie && counts.isEmpty) counts = const <int>[0];

    int season = movie ? 1 : old.currentSeason;
    int episode = movie ? 0 : old.currentEpisode;
    if (!movie) {
      if (season > counts.length) season = counts.length;
      if (season < 1) season = 1;
      final int total = counts[season - 1];
      if (total > 0 && episode > total) {
        return 'Season $season has $total episodes, but current progress is episode $episode.';
      }
    }

    final DateTime today = WatchItem.today();
    DateTime? completedAt = old.completedAt;
    if (status == WatchOptions.watchedStatus) {
      completedAt ??= today;
      if (!movie && counts.isNotEmpty) {
        season = counts.length;
        final int finalTotal = counts.last;
        if (finalTotal > 0) episode = finalTotal;
      }
    } else {
      completedAt = null;
    }

    _replaceItem(
      old.copyWith(
        name: cleanName,
        category: category,
        status: status,
        seasonEpisodeCounts: counts,
        currentSeason: season,
        currentEpisode: episode,
        watchNext: status == WatchOptions.watchedStatus ? false : old.watchNext,
        completedAt: completedAt,
        clearCompletedAt: status != WatchOptions.watchedStatus,
        updatedAt: today,
      ),
    );
    await _saveItemsAndNotify();
    return null;
  }

  Future<void> setStatus(String id, String status) async {
    final WatchItem? item = findItem(id);
    if (item == null) return;
    final DateTime today = WatchItem.today();

    int season = item.currentSeason;
    int episode = item.currentEpisode;
    if (status == WatchOptions.watchedStatus && item.isEpisodic && item.seasonCount > 0) {
      season = item.seasonCount;
      final int finalTotal = item.episodeCountForSeason(season);
      if (finalTotal > 0) episode = finalTotal;
    }

    _replaceItem(
      item.copyWith(
        status: status,
        currentSeason: season,
        currentEpisode: episode,
        watchNext: status == WatchOptions.watchedStatus ? false : item.watchNext,
        completedAt: status == WatchOptions.watchedStatus ? today : item.completedAt,
        clearCompletedAt: status != WatchOptions.watchedStatus,
        updatedAt: today,
      ),
    );
    await _saveItemsAndNotify();
  }

  Future<void> toggleWatchNext(String id) async {
    final WatchItem? item = findItem(id);
    if (item == null || item.status == WatchOptions.watchedStatus) return;
    _replaceItem(
      item.copyWith(
        watchNext: !item.watchNext,
        updatedAt: WatchItem.today(),
      ),
    );
    await _saveItemsAndNotify();
  }

  Future<String?> setSeasonPlan(String id, List<int> counts) async {
    final WatchItem? item = findItem(id);
    if (item == null || !item.isEpisodic) return 'Series/Anime only.';
    if (counts.isEmpty) return 'Add at least one season.';

    final List<int> safe = counts.map((int value) => value < 0 ? 0 : value).toList();
    if (item.currentSeason > safe.length) {
      return 'You currently have progress in season ${item.currentSeason}. Keep at least that many seasons.';
    }
    final int currentTotal = safe[item.currentSeason - 1];
    if (currentTotal > 0 && item.currentEpisode > currentTotal) {
      return 'Season ${item.currentSeason} cannot have fewer than ${item.currentEpisode} episodes because that is your current progress.';
    }

    _replaceItem(
      item.copyWith(
        seasonEpisodeCounts: safe,
        updatedAt: WatchItem.today(),
      ),
    );
    await _saveItemsAndNotify();
    return null;
  }

  Future<String?> setProgress({
    required String id,
    required int season,
    required int episode,
  }) async {
    final WatchItem? item = findItem(id);
    if (item == null || !item.isEpisodic) return 'Series/Anime only.';
    if (season < 1 || season > item.seasonCount) {
      return 'Season must be between 1 and ${item.seasonCount}.';
    }
    if (episode < 0) return 'Episode cannot be negative.';
    final int total = item.episodeCountForSeason(season);
    if (total > 0 && episode > total) {
      return 'Season $season only has $total episodes.';
    }

    final DateTime today = WatchItem.today();
    final bool completed = season == item.seasonCount && total > 0 && episode == total;
    _replaceItem(
      item.copyWith(
        currentSeason: season,
        currentEpisode: episode,
        status: completed
            ? WatchOptions.watchedStatus
            : (episode > 0 ? WatchOptions.watchingStatus : item.status),
        lastWatchedAt: episode > 0 ? today : item.lastWatchedAt,
        completedAt: completed ? today : item.completedAt,
        clearCompletedAt: !completed && item.status == WatchOptions.watchedStatus,
        watchNext: completed ? false : item.watchNext,
        updatedAt: today,
      ),
    );
    await _saveItemsAndNotify();
    return null;
  }

  Future<String> incrementEpisode(String id) async {
    final WatchItem? item = findItem(id);
    if (item == null || !item.isEpisodic) return 'No episodic title found.';
    if (item.status == WatchOptions.watchedStatus) return 'Already marked Watched.';

    int season = item.currentSeason;
    int episode = item.currentEpisode;
    final int total = item.episodeCountForSeason(season);

    if (total > 0 && episode >= total) {
      if (season >= item.seasonCount) {
        await setStatus(id, WatchOptions.watchedStatus);
        return 'Series completed.';
      }
      season += 1;
      episode = 1;
    } else {
      episode += 1;
    }

    final int newTotal = item.episodeCountForSeason(season);
    if (newTotal > 0 && episode > newTotal) {
      return 'Season $season only has $newTotal episodes.';
    }

    final DateTime today = WatchItem.today();
    final bool completed = season == item.seasonCount && newTotal > 0 && episode == newTotal;
    _replaceItem(
      item.copyWith(
        currentSeason: season,
        currentEpisode: episode,
        status: completed ? WatchOptions.watchedStatus : WatchOptions.watchingStatus,
        lastWatchedAt: today,
        completedAt: completed ? today : item.completedAt,
        clearCompletedAt: !completed && item.completedAt != null,
        watchNext: completed ? false : item.watchNext,
        updatedAt: today,
      ),
    );
    await _saveItemsAndNotify();
    return completed ? 'Final episode saved. Series completed.' : 'Progress saved: S$season E$episode.';
  }

  Future<String> completeSeason(String id) async {
    final WatchItem? item = findItem(id);
    if (item == null || !item.isEpisodic) return 'No episodic title found.';
    final int total = item.currentSeasonEpisodeCount;
    if (total <= 0) {
      return 'Set the episode count for season ${item.currentSeason} first.';
    }

    final DateTime today = WatchItem.today();
    final bool finalSeason = item.currentSeason == item.seasonCount;
    _replaceItem(
      item.copyWith(
        currentEpisode: total,
        status: finalSeason ? WatchOptions.watchedStatus : WatchOptions.watchingStatus,
        lastWatchedAt: today,
        completedAt: finalSeason ? today : item.completedAt,
        clearCompletedAt: !finalSeason && item.completedAt != null,
        watchNext: finalSeason ? false : item.watchNext,
        updatedAt: today,
      ),
    );
    await _saveItemsAndNotify();
    return finalSeason
        ? 'Season ${item.currentSeason} completed. Series marked Watched.'
        : 'Season ${item.currentSeason} completed.';
  }

  Future<void> markMovieWatched(String id) async {
    final WatchItem? item = findItem(id);
    if (item == null || !item.isMovie) return;
    final DateTime today = WatchItem.today();
    _replaceItem(
      item.copyWith(
        status: WatchOptions.watchedStatus,
        completedAt: today,
        lastWatchedAt: today,
        updatedAt: today,
        watchNext: false,
      ),
    );
    await _saveItemsAndNotify();
  }

  Future<void> deleteItem(String id) async {
    _items = _items.where((WatchItem item) => item.id != id).toList();
    await _saveItemsAndNotify();
  }

  Future<void> deleteAll() async {
    _items = <WatchItem>[];
    await _saveItemsAndNotify();
  }

  String exportBackupJson() => _backupService.createBackupJson(_items);

  int countBackupItems(String text) =>
      _backupService.parseBackupJson(text).items.length;

  Future<int> importBackup(String text) async {
    final BackupData imported = _backupService.parseBackupJson(text);
    _items = imported.items;
    await _saveItemsAndNotify();
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

  void _replaceItem(WatchItem replacement) {
    _items = _items
        .map((WatchItem item) => item.id == replacement.id ? replacement : item)
        .toList();
  }

  Future<void> _saveItemsAndNotify() async {
    _rebuildDerivedState();
    notifyListeners();
    await _storageService.saveItems(_items);
  }

  void _rebuildDerivedState() {
    _itemsView = List<WatchItem>.unmodifiable(_items);

    final Map<String, int> statusCounts = <String, int>{
      for (final String status in WatchOptions.statuses) status: 0,
    };
    final Map<String, int> categoryCounts = <String, int>{
      for (final String category in WatchOptions.categories) category: 0,
    };
    for (final WatchItem item in _items) {
      statusCounts[item.status] = (statusCounts[item.status] ?? 0) + 1;
      categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
    }
    _statusCounts = Map<String, int>.unmodifiable(statusCounts);
    _categoryCounts = Map<String, int>.unmodifiable(categoryCounts);

    final List<WatchItem> filtered = _items.where(_filter.matches).toList()
      ..sort(_compareByName);
    _visibleItems = List<WatchItem>.unmodifiable(filtered);

    final List<WatchItem> watching = _items
        .where((WatchItem item) => item.status == WatchOptions.watchingStatus)
        .toList()
      ..sort(_compareContinueWatching);
    _continueWatching = List<WatchItem>.unmodifiable(watching.take(20));

    final List<WatchItem> next = _items
        .where((WatchItem item) => item.watchNext && item.status != WatchOptions.watchedStatus)
        .toList()
      ..sort(_compareByUpdatedThenName);
    _watchNextItems = List<WatchItem>.unmodifiable(next.take(20));

    final List<WatchItem> completed = _items
        .where((WatchItem item) => item.completedAt != null)
        .toList()
      ..sort((WatchItem a, WatchItem b) {
        final int date = b.completedAt!.compareTo(a.completedAt!);
        return date != 0 ? date : _compareByName(a, b);
      });
    _recentlyCompleted = List<WatchItem>.unmodifiable(completed.take(12));
  }

  int _compareByName(WatchItem a, WatchItem b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

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
