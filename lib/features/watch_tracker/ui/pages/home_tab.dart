import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../controllers/watch_tracker_controller.dart';
import '../../models/watch_item.dart';
import '../utils/watch_date_text.dart';
import '../widgets/app_panel.dart';
import '../widgets/badge.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    required this.controller,
    required this.onOpenItem,
    required this.onEpisodeWatched,
    required this.onCompleteSeason,
    required this.onMovieWatched,
    super.key,
  });

  final WatchTrackerController controller;
  final ValueChanged<WatchItem> onOpenItem;
  final ValueChanged<WatchItem> onEpisodeWatched;
  final ValueChanged<WatchItem> onCompleteSeason;
  final ValueChanged<WatchItem> onMovieWatched;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 110),
      children: <Widget>[
        const Text('What are you watching?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Update progress quickly, or choose something from Watch Next.', style: TextStyle(color: AppColors.mutedText)),
        const SizedBox(height: 16),
        _Section(
          title: 'Continue Watching',
          child: controller.continueWatching.isEmpty
              ? const _EmptyText('Nothing is marked as Watching yet.')
              : Column(children: controller.continueWatching.map((WatchItem item) => _continueTile(item)).toList()),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Watch Next',
          child: controller.watchNextItems.isEmpty
              ? const _EmptyText('Star titles in your library to keep them here.')
              : Column(children: controller.watchNextItems.map(_watchNextTile).toList()),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Recently Completed',
          child: controller.recentlyCompleted.isEmpty
              ? const _EmptyText('Completed titles with known dates will appear here.')
              : Column(children: controller.recentlyCompleted.map(_completedTile).toList()),
        ),
      ],
    );
  }

  Widget _continueTile(WatchItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onOpenItem(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Wrap(spacing: 7, runSpacing: 7, children: <Widget>[
                BadgeLabel(text: item.category),
                BadgeLabel(text: item.progressLabel),
                if (item.watchNext) const BadgeLabel(text: 'Watch Next'),
              ]),
              const SizedBox(height: 12),
              if (item.isEpisodic)
                Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                  FilledButton.icon(onPressed: () => onEpisodeWatched(item), icon: const Icon(Icons.add), label: const Text('Episode')),
                  OutlinedButton(onPressed: () => onCompleteSeason(item), child: const Text('Complete Season')),
                ])
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(onPressed: () => onMovieWatched(item), icon: const Icon(Icons.check), label: const Text('Mark Watched')),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _watchNextTile(WatchItem item) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${item.category} • ${item.status}${item.isEpisodic ? ' • ${item.progressLabel}' : ''}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => onOpenItem(item),
      );

  Widget _completedTile(WatchItem item) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(item.isMovie ? Icons.movie_outlined : Icons.check_circle_outline),
        title: Text(item.name),
        subtitle: Text('Completed ${shortDate(item.completedAt)}'),
        onTap: () => onOpenItem(item),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => AppPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          child,
        ]),
      );
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: const TextStyle(color: AppColors.mutedText)),
      );
}
