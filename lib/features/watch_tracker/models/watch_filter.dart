import '../../../core/constants/watch_options.dart';
import 'watch_item.dart';

class WatchFilter {
  const WatchFilter({
    this.searchQuery = '',
    this.category = WatchOptions.allFilter,
    this.status = WatchOptions.allFilter,
  });

  final String searchQuery;
  final String category;
  final String status;

  bool get hasActiveFilters {
    return searchQuery.trim().isNotEmpty ||
        category != WatchOptions.allFilter ||
        status != WatchOptions.allFilter;
  }

  bool matches(WatchItem item) {
    final String cleanQuery = searchQuery.trim().toLowerCase();
    final bool matchesSearch = cleanQuery.isEmpty || item.name.toLowerCase().contains(cleanQuery);
    final bool matchesCategory = category == WatchOptions.allFilter || item.category == category;
    final bool matchesStatus = status == WatchOptions.allFilter || item.status == status;

    return matchesSearch && matchesCategory && matchesStatus;
  }

  WatchFilter copyWith({
    String? searchQuery,
    String? category,
    String? status,
  }) {
    return WatchFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      status: status ?? this.status,
    );
  }
}
