import '../../../core/constants/watch_options.dart';
import '../../../core/utils/id_generator.dart';

class WatchItem {
  const WatchItem({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    this.seasonEpisodeCounts = const <int>[],
    this.currentSeason = 1,
    this.currentEpisode = 0,
    this.watchNext = false,
    this.addedAt,
    this.lastWatchedAt,
    this.completedAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String category;
  final String status;

  /// Episode totals for seasons 1..N. A value of 0 means the total is unknown.
  /// Movies always use an empty list.
  final List<int> seasonEpisodeCounts;
  final int currentSeason;
  final int currentEpisode;
  final bool watchNext;

  /// Dates are normalized to the local calendar day. The UI intentionally does
  /// not show time-of-day data.
  final DateTime? addedAt;
  final DateTime? lastWatchedAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  bool get isMovie => category == 'Movie';
  bool get isEpisodic => !isMovie;
  int get seasonCount => isMovie ? 0 : seasonEpisodeCounts.length;

  int episodeCountForSeason(int season) {
    if (!isEpisodic || season < 1 || season > seasonEpisodeCounts.length) {
      return 0;
    }
    return seasonEpisodeCounts[season - 1];
  }

  int get currentSeasonEpisodeCount => episodeCountForSeason(currentSeason);
  bool get hasKnownCurrentSeasonTotal => currentSeasonEpisodeCount > 0;

  bool get isAtKnownFinalEpisode {
    if (!isEpisodic || seasonCount == 0) return false;
    final int total = currentSeasonEpisodeCount;
    return currentSeason == seasonCount && total > 0 && currentEpisode >= total;
  }

  String get progressLabel {
    if (isMovie) return status;
    final int total = currentSeasonEpisodeCount;
    if (total > 0) return 'S$currentSeason E$currentEpisode / $total';
    return 'S$currentSeason E$currentEpisode';
  }

  String get structureLabel {
    if (isMovie) return 'Movie';
    if (seasonEpisodeCounts.isEmpty) return 'Season counts not set';
    final String seasons = seasonEpisodeCounts.length == 1
        ? '1 season'
        : '${seasonEpisodeCounts.length} seasons';
    final bool allUnknown = seasonEpisodeCounts.every((int count) => count <= 0);
    if (allUnknown) return '$seasons • episode totals unknown';
    return '$seasons • ${seasonEpisodeCounts.map((int count) => count > 0 ? count : '?').join(' / ')} eps';
  }

  factory WatchItem.create({
    required String name,
    required String category,
    String status = WatchOptions.defaultStatus,
    bool watchNext = false,
    List<int> seasonEpisodeCounts = const <int>[],
  }) {
    final DateTime today = _today();
    final String safeCategory = _safeCategory(category);
    final bool movie = safeCategory == 'Movie';
    final List<int> counts = movie
        ? const <int>[]
        : _safeSeasonCounts(seasonEpisodeCounts.isEmpty ? const <int>[0] : seasonEpisodeCounts);

    return WatchItem(
      id: IdGenerator.create(),
      name: name.trim(),
      category: safeCategory,
      status: _safeStatus(status),
      seasonEpisodeCounts: counts,
      watchNext: watchNext,
      addedAt: today,
      updatedAt: today,
    );
  }

  factory WatchItem.fromJson(Map<String, dynamic> json) {
    final String category = _safeCategory(json['category']?.toString());
    final int currentSeason = _positiveInt(json['currentSeason'], fallback: 1);
    final int currentEpisode = _nonNegativeInt(json['currentEpisode']);

    List<int> counts = _seasonCountsValue(json['seasonEpisodeCounts']);
    if (category == 'Movie') {
      counts = const <int>[];
    } else if (counts.isEmpty) {
      // v1/v2 did not know season totals. Preserve progress and leave totals
      // unknown until the user edits the season structure.
      counts = List<int>.filled(currentSeason < 1 ? 1 : currentSeason, 0);
    } else if (counts.length < currentSeason) {
      counts = <int>[...counts, ...List<int>.filled(currentSeason - counts.length, 0)];
    }

    final String status = _safeStatus(json['status']?.toString());
    DateTime? completedAt = _dateValue(json['completedAt']);
    completedAt ??= _dateValue(json['watchedAt']); // v2 movie field
    final DateTime? legacyLastWatched = _dateValue(json['lastWatchedAt']);
    if (completedAt == null && status == WatchOptions.watchedStatus) {
      completedAt = legacyLastWatched;
    }

    return WatchItem(
      id: (json['id'] ?? IdGenerator.create()).toString(),
      name: (json['name'] ?? '').toString().trim(),
      category: category,
      status: status,
      seasonEpisodeCounts: List<int>.unmodifiable(counts),
      currentSeason: currentSeason,
      currentEpisode: currentEpisode,
      watchNext: _boolValue(json['watchNext']) && status != WatchOptions.watchedStatus,
      addedAt: _dateValue(json['addedAt']),
      lastWatchedAt: legacyLastWatched,
      completedAt: completedAt,
      updatedAt: _dateValue(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'status': status,
      'seasonEpisodeCounts': seasonEpisodeCounts,
      'currentSeason': currentSeason,
      'currentEpisode': currentEpisode,
      'watchNext': watchNext,
      'addedAt': _dateText(addedAt),
      'lastWatchedAt': _dateText(lastWatchedAt),
      'completedAt': _dateText(completedAt),
      'updatedAt': _dateText(updatedAt),
    };
  }

  WatchItem copyWith({
    String? id,
    String? name,
    String? category,
    String? status,
    List<int>? seasonEpisodeCounts,
    int? currentSeason,
    int? currentEpisode,
    bool? watchNext,
    DateTime? addedAt,
    DateTime? lastWatchedAt,
    bool clearLastWatchedAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? updatedAt,
  }) {
    final String nextCategory = category == null ? this.category : _safeCategory(category);
    return WatchItem(
      id: id ?? this.id,
      name: name?.trim() ?? this.name,
      category: nextCategory,
      status: status == null ? this.status : _safeStatus(status),
      seasonEpisodeCounts: nextCategory == 'Movie'
          ? const <int>[]
          : List<int>.unmodifiable(
              _safeSeasonCounts(seasonEpisodeCounts ?? this.seasonEpisodeCounts),
            ),
      currentSeason: currentSeason == null
          ? this.currentSeason
          : (currentSeason < 1 ? 1 : currentSeason),
      currentEpisode: currentEpisode == null
          ? this.currentEpisode
          : (currentEpisode < 0 ? 0 : currentEpisode),
      watchNext: watchNext ?? this.watchNext,
      addedAt: _dateOnly(addedAt ?? this.addedAt),
      lastWatchedAt: clearLastWatchedAt
          ? null
          : _dateOnly(lastWatchedAt ?? this.lastWatchedAt),
      completedAt: clearCompletedAt
          ? null
          : _dateOnly(completedAt ?? this.completedAt),
      updatedAt: _dateOnly(updatedAt ?? this.updatedAt),
    );
  }

  static DateTime today() => _today();

  static String _safeCategory(String? value) {
    if (WatchOptions.categories.contains(value)) return value!;
    return WatchOptions.defaultCategory;
  }

  static String _safeStatus(String? value) {
    if (WatchOptions.statuses.contains(value)) return value!;
    return WatchOptions.fallbackStatus;
  }

  static List<int> _safeSeasonCounts(List<int> counts) {
    if (counts.isEmpty) return const <int>[0];
    return counts.map((int value) => value < 0 ? 0 : value).toList(growable: false);
  }

  static List<int> _seasonCountsValue(dynamic value) {
    if (value is! List) return <int>[];
    return value
        .map((dynamic item) => _intValue(item) ?? 0)
        .map((int item) => item < 0 ? 0 : item)
        .toList(growable: false);
  }

  static int _positiveInt(dynamic value, {required int fallback}) {
    final int? parsed = _intValue(value);
    if (parsed == null || parsed < 1) return fallback;
    return parsed;
  }

  static int _nonNegativeInt(dynamic value) {
    final int? parsed = _intValue(value);
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

  static int? _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static bool _boolValue(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  static DateTime? _dateValue(dynamic value) {
    if (value == null) return null;
    final DateTime? parsed = DateTime.tryParse(value.toString());
    return _dateOnly(parsed?.toLocal());
  }

  static DateTime? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime _today() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String? _dateText(DateTime? value) {
    if (value == null) return null;
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
