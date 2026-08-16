import '../../../core/utils/id_generator.dart';

class WatchHistoryEntry {
  const WatchHistoryEntry({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.type,
    required this.watchedAt,
    required this.previousStatus,
    this.season,
    this.episode,
    this.runtimeMinutes,
    this.previousSeason,
    this.previousEpisode,
  });

  static const String episodeType = 'episode';
  static const String movieType = 'movie';

  final String id;
  final String itemId;
  final String itemName;
  final String category;
  final String type;
  final DateTime watchedAt;
  final int? season;
  final int? episode;
  final int? runtimeMinutes;

  // These fields make the most recent action safely undoable.
  final String previousStatus;
  final int? previousSeason;
  final int? previousEpisode;

  bool get isEpisode => type == episodeType;
  bool get isMovie => type == movieType;

  String get activityLabel {
    if (isEpisode && season != null && episode != null) {
      return 'S$season E$episode';
    }
    return 'Movie watched';
  }

  factory WatchHistoryEntry.episode({
    required String itemId,
    required String itemName,
    required String category,
    required int season,
    required int episode,
    required String previousStatus,
    required int previousSeason,
    required int previousEpisode,
    int? runtimeMinutes,
    DateTime? watchedAt,
  }) {
    return WatchHistoryEntry(
      id: IdGenerator.create(),
      itemId: itemId,
      itemName: itemName,
      category: category,
      type: episodeType,
      watchedAt: watchedAt ?? DateTime.now(),
      season: season,
      episode: episode,
      runtimeMinutes: runtimeMinutes,
      previousStatus: previousStatus,
      previousSeason: previousSeason,
      previousEpisode: previousEpisode,
    );
  }

  factory WatchHistoryEntry.movie({
    required String itemId,
    required String itemName,
    required String category,
    required String previousStatus,
    int? runtimeMinutes,
    DateTime? watchedAt,
  }) {
    return WatchHistoryEntry(
      id: IdGenerator.create(),
      itemId: itemId,
      itemName: itemName,
      category: category,
      type: movieType,
      watchedAt: watchedAt ?? DateTime.now(),
      runtimeMinutes: runtimeMinutes,
      previousStatus: previousStatus,
    );
  }

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WatchHistoryEntry(
      id: (json['id'] ?? IdGenerator.create()).toString(),
      itemId: (json['itemId'] ?? '').toString(),
      itemName: (json['itemName'] ?? '').toString().trim(),
      category: (json['category'] ?? 'Series').toString(),
      type: (json['type'] ?? episodeType).toString(),
      watchedAt: DateTime.tryParse((json['watchedAt'] ?? '').toString()) ??
          DateTime.now(),
      season: _intValue(json['season']),
      episode: _intValue(json['episode']),
      runtimeMinutes: _intValue(json['runtimeMinutes']),
      previousStatus: (json['previousStatus'] ?? 'Watching').toString(),
      previousSeason: _intValue(json['previousSeason']),
      previousEpisode: _intValue(json['previousEpisode']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'category': category,
      'type': type,
      'watchedAt': watchedAt.toIso8601String(),
      'season': season,
      'episode': episode,
      'runtimeMinutes': runtimeMinutes,
      'previousStatus': previousStatus,
      'previousSeason': previousSeason,
      'previousEpisode': previousEpisode,
    };
  }

  static int? _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
