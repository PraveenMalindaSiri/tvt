import 'package:flutter/material.dart';

import '../../../../core/constants/watch_options.dart';
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
    required this.onCompleteSeason,
    required this.onMovieWatched,
    required this.onClearFilters,
    super.key,
  });

  final WatchTrackerController controller;
  final TextEditingController searchController;
  final ValueChanged<WatchItem> onOpenItem;
  final ValueChanged<WatchItem> onToggleWatchNext;
  final ValueChanged<WatchItem> onEpisodeWatched;
  final ValueChanged<WatchItem> onCompleteSeason;
  final ValueChanged<WatchItem> onMovieWatched;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
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
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Expanded(child: Text('Library', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
              Text('${controller.visibleItems.length} titles', style: const TextStyle(color: AppColors.mutedText)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: controller.visibleItems.isEmpty
                ? const Center(child: Text('No titles match these filters.', style: TextStyle(color: AppColors.mutedText)))
                : ListView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: controller.visibleItems.length,
                    itemBuilder: (BuildContext context, int index) => _buildItem(controller.visibleItems[index]),
                  ),
          ),
          const SizedBox(height: 88),
        ],
      ),
    );
  }

  Widget _buildItem(WatchItem item) {
    final bool watched = item.status == WatchOptions.watchedStatus;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onOpenItem(item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: watched ? 'Completed titles cannot be Watch Next' : (item.watchNext ? 'Remove from Watch Next' : 'Add to Watch Next'),
                    onPressed: watched ? null : () => onToggleWatchNext(item),
                    icon: Icon(item.watchNext ? Icons.star : Icons.star_border),
                  ),
                  IconButton(onPressed: () => onOpenItem(item), icon: const Icon(Icons.chevron_right)),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(spacing: 7, runSpacing: 7, children: <Widget>[
                BadgeLabel(text: item.category),
                BadgeLabel(text: item.status),
                if (item.isEpisodic) BadgeLabel(text: item.progressLabel),
                if (item.watchNext) const BadgeLabel(text: 'Watch Next'),
              ]),
              if (item.isEpisodic) ...<Widget>[
                const SizedBox(height: 8),
                Text(item.structureLabel, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
              ],
              if (item.status == WatchOptions.watchingStatus) ...<Widget>[
                const SizedBox(height: 12),
                if (item.isEpisodic)
                  Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: () => onEpisodeWatched(item),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Episode'),
                    ),
                    OutlinedButton(
                      onPressed: () => onCompleteSeason(item),
                      child: const Text('Complete Season'),
                    ),
                  ])
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: () => onMovieWatched(item),
                      icon: const Icon(Icons.check),
                      label: const Text('Mark Watched'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
