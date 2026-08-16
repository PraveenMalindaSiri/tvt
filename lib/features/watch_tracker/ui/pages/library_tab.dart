import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../controllers/watch_tracker_controller.dart';
import '../../models/watch_item.dart';
import '../widgets/app_panel.dart';
import '../widgets/badge.dart';
import '../widgets/filter_bar.dart';

class LibraryTab extends StatelessWidget {
  const LibraryTab({
    required this.controller,
    required this.searchController,
    required this.onOpenItem,
    required this.onToggleWatchNext,
    required this.onEpisodeWatched,
    required this.onMovieWatched,
    required this.onClearFilters,
    super.key,
  });

  final WatchTrackerController controller;
  final TextEditingController searchController;
  final ValueChanged<WatchItem> onOpenItem;
  final ValueChanged<WatchItem> onToggleWatchNext;
  final ValueChanged<WatchItem> onEpisodeWatched;
  final ValueChanged<WatchItem> onMovieWatched;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        children: <Widget>[
          AppPanel(
            child: FilterBar(
              searchController: searchController,
              filter: controller.filter,
              onCategoryChanged: controller.setCategoryFilter,
              onStatusChanged: controller.setStatusFilter,
              onClearFilters: onClearFilters,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: AppPanel(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Library',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        '${controller.visibleItems.length} shown',
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: controller.visibleItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No titles match these filters.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.mutedText),
                            ),
                          )
                        : Scrollbar(
                            child: ListView.separated(
                              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                              itemCount: controller.visibleItems.length,
                              separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                              itemBuilder: (BuildContext context, int index) {
                                return _buildItem(controller.visibleItems[index]);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 92),
        ],
      ),
    );
  }

  Widget _buildItem(WatchItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onOpenItem(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: <Widget>[
                        BadgeLabel(text: item.category),
                        BadgeLabel(text: item.status),
                        if (item.isEpisodic && item.currentEpisode > 0)
                          BadgeLabel(text: item.progressLabel),
                        if (item.watchNext) const BadgeLabel(text: 'Watch Next'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: item.watchNext ? 'Remove from Watch Next' : 'Add to Watch Next',
            onPressed: () => onToggleWatchNext(item),
            icon: Icon(item.watchNext ? Icons.star : Icons.star_border),
          ),
          if (item.status == 'Watching')
            if (item.isEpisodic)
              IconButton.filledTonal(
                tooltip: 'Watched next episode',
                onPressed: () => onEpisodeWatched(item),
                icon: const Icon(Icons.add),
              )
            else
              IconButton.filledTonal(
                tooltip: 'Mark watched',
                onPressed: () => onMovieWatched(item),
                icon: const Icon(Icons.check),
              ),
          IconButton(
            tooltip: 'Open details',
            onPressed: () => onOpenItem(item),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
