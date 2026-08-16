class WatchOptions {
  const WatchOptions._();

  // v2 keeps richer title data and watch history. The v1 key is retained so
  // existing installs can migrate without losing the user's current list.
  static const String storageKey = 'simpleWatchTracker.items.v2';
  static const String historyStorageKey = 'simpleWatchTracker.history.v2';
  static const String legacyStorageKey = 'simpleWatchTracker.items.v1';

  static const String allFilter = 'All';

  static const String defaultCategory = 'Series';
  static const String defaultStatus = 'To Watch';
  static const String fallbackStatus = 'To Watch';

  static const String watchedStatus = 'Watched';
  static const String watchingStatus = 'Watching';
  static const String toWatchStatus = 'To Watch';

  static const List<String> categories = <String>[
    'Series',
    'Movie',
    'Anime',
  ];

  static const List<String> statuses = <String>[
    watchedStatus,
    watchingStatus,
    toWatchStatus,
  ];

  static const List<String> backupFields = <String>[
    'id',
    'name',
    'category',
    'status',
    'currentSeason',
    'currentEpisode',
    'runtimeMinutes',
    'watchNext',
    'addedAt',
    'updatedAt',
    'lastWatchedAt',
    'watchedAt',
  ];
}
