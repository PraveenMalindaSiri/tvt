import '../../../core/constants/watch_options.dart';
import '../../../core/utils/id_generator.dart';

class WatchItem {
  const WatchItem({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    this.currentSeason = 1,
    this.currentEpisode = 0,
    this.runtimeMinutes,
    this.watchNext = false,
    this.addedAt,
    this.updatedAt,
    this.lastWatchedAt,
    this.watchedAt,
  });

  final String id;
  final String name;
  final String category;
  final String status;

  /// For Series/Anime this is the season containing [currentEpisode].
  final int currentSeason;

  /// Last watched episode in [currentSeason]. Zero means no progress recorded.
  final int currentEpisode;

  /// Optional runtime used for local watch-time statistics.
  /// For Series/Anime this is the normal episode runtime; for Movie it is the
  /// movie runtime.
  final int? runtimeMinutes;

  /// Simple priority flag used by the Watch Next section.
  final bool watchNext;

  /// Old v1 data does not contain these timestamps, so they intentionally stay
  /// null after migration instead of inventing dates.
  final DateTime? addedAt;
  final DateTime? updatedAt;
  final DateTime? lastWatchedAt;
  final DateTime? watchedAt;

  bool get isMovie => category == 'Movie';
  bool get isEpisodic => !isMovie;

  String get progressLabel {
    if (isMovie) return status;
    if (currentEpisode <= 0) return 'Not started';
    return 'S$currentSeason E$currentEpisode';
  }

  factory WatchItem.create({
    required String name,
    required String category,
    String status = WatchOptions.defaultStatus,
    bool watchNext = false,
  }) {
    final DateTime now = DateTime.now();
    return WatchItem(
      id: IdGenerator.create(),
      name: name.trim(),
      category: _safeCategory(category),
      status: _safeStatus(status),
      watchNext: watchNext,
      addedAt: now,
      updatedAt: now,
    );
  }

  factory WatchItem.fromJson(Map<String, dynamic> json) {
    return WatchItem(
      id: (json['id'] ?? IdGenerator.create()).toString(),
      name: (json['name'] ?? '').toString().trim(),
      category: _safeCategory(json['category']?.toString()),
      status: _safeStatus(json['status']?.toString()),
      currentSeason: _positiveInt(json['currentSeason'], fallback: 1),
      currentEpisode: _nonNegativeInt(json['currentEpisode']),
      runtimeMinutes: _nullablePositiveInt(json['runtimeMinutes']),
      watchNext: _boolValue(json['watchNext']),
      addedAt: _dateValue(json['addedAt']),
      updatedAt: _dateValue(json['updatedAt']),
      lastWatchedAt: _dateValue(json['lastWatchedAt']),
      watchedAt: _dateValue(json['watchedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'status': status,
      'currentSeason': currentSeason,
      'currentEpisode': currentEpisode,
      'runtimeMinutes': runtimeMinutes,
      'watchNext': watchNext,
      'addedAt': addedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastWatchedAt': lastWatchedAt?.toIso8601String(),
      'watchedAt': watchedAt?.toIso8601String(),
    };
  }

  WatchItem copyWith({
    String? id,
    String? name,
    String? category,
    String? status,
    int? currentSeason,
    int? currentEpisode,
    int? runtimeMinutes,
    bool clearRuntimeMinutes = false,
    bool? watchNext,
    DateTime? addedAt,
    DateTime? updatedAt,
    DateTime? lastWatchedAt,
    bool clearLastWatchedAt = false,
    DateTime? watchedAt,
    bool clearWatchedAt = false,
  }) {
    return WatchItem(
      id: id ?? this.id,
      name: name?.trim() ?? this.name,
      category: category == null ? this.category : _safeCategory(category),
      status: status == null ? this.status : _safeStatus(status),
      currentSeason: currentSeason == null
          ? this.currentSeason
          : (currentSeason < 1 ? 1 : currentSeason),
      currentEpisode: currentEpisode == null
          ? this.currentEpisode
          : (currentEpisode < 0 ? 0 : currentEpisode),
      runtimeMinutes:
          clearRuntimeMinutes ? null : (runtimeMinutes ?? this.runtimeMinutes),
      watchNext: watchNext ?? this.watchNext,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastWatchedAt: clearLastWatchedAt ? null : (lastWatchedAt ?? this.lastWatchedAt),
      watchedAt: clearWatchedAt ? null : (watchedAt ?? this.watchedAt),
    );
  }

  static String _safeCategory(String? value) {
    if (WatchOptions.categories.contains(value)) return value!;
    return WatchOptions.defaultCategory;
  }

  static String _safeStatus(String? value) {
    if (WatchOptions.statuses.contains(value)) return value!;
    return WatchOptions.fallbackStatus;
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

  static int? _nullablePositiveInt(dynamic value) {
    final int? parsed = _intValue(value);
    if (parsed == null || parsed <= 0) return null;
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
    return DateTime.tryParse(value.toString());
  }
}
