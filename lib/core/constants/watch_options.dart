class WatchOptions {
  const WatchOptions._();

  // v3 stores a compact per-title model. Older keys are retained for one-time
  // migration so existing installs keep their library.
  static const String storageKey = 'simpleWatchTracker.items.v3';
  static const String legacyV2StorageKey = 'simpleWatchTracker.items.v2';
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
    'seasonEpisodeCounts',
    'currentSeason',
    'currentEpisode',
    'watchNext',
    'addedAt',
    'lastWatchedAt',
    'completedAt',
    'updatedAt',
  ];
}
