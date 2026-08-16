import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../controllers/watch_tracker_controller.dart';
import '../../models/watch_history_entry.dart';
import '../../models/watch_item.dart';
import '../utils/watch_date_text.dart';
import '../widgets/app_panel.dart';
import '../widgets/badge.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    required this.controller,
    required this.onOpenItem,
    required this.onEpisodeWatched,
    required this.onMovieWatched,
    super.key,
  });

  final WatchTrackerController controller;
  final ValueChanged<WatchItem> onOpenItem;
  final ValueChanged<WatchItem> onEpisodeWatched;
  final ValueChanged<WatchItem> onMovieWatched;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
      children: <Widget>[
        const Text(
          'What are you watching?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Continue quickly, or choose something from Watch Next.',
          style: TextStyle(color: AppColors.mutedText),
        ),
        const SizedBox(height: 18),
        _Section(
          title: 'Continue Watching',
          child: controller.continueWatching.isEmpty
              ? const _EmptyText('Nothing is marked as Watching yet.')
              : Column(
                  children: controller.continueWatching
                      .map((WatchItem item) => _continueTile(context, item))
                      .toList(),
                ),
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Watch Next',
          child: controller.watchNextItems.isEmpty
              ? const _EmptyText('Star titles in your library to keep them here.')
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: controller.watchNextItems
                      .map((WatchItem item) => _nextCard(context, item))
                      .toList(),
                ),
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Recently Watched',
          child: controller.recentHistory.isEmpty
              ? const _EmptyText(
                  'No detailed watch history recorded yet. New progress will appear here.',
                )
              : Column(
                  children: controller.recentHistory
                      .take(8)
                      .map(_historyTile)
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _continueTile(BuildContext context, WatchItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.panelLight,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onOpenItem(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Expanded(
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
                          BadgeLabel(text: item.progressLabel),
                          if (item.watchNext) const BadgeLabel(text: 'Watch Next'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (item.isEpisodic)
                  FilledButton.icon(
                    onPressed: () => onEpisodeWatched(item),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Episode'),
                  )
                else
                  FilledButton(
                    onPressed: () => onMovieWatched(item),
                    child: const Text('Watched'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nextCard(BuildContext context, WatchItem item) {
    return SizedBox(
      width: 250,
      child: Material(
        color: AppColors.panelLight,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onOpenItem(item),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    BadgeLabel(text: item.category),
                    BadgeLabel(text: item.status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _historyTile(WatchHistoryEntry entry) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(entry.isMovie ? Icons.movie_outlined : Icons.play_circle_outline),
      title: Text(entry.itemName),
      subtitle: Text('${entry.activityLabel} • ${shortDateTime(entry.watchedAt)}'),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: AppColors.mutedText)),
    );
  }
}
