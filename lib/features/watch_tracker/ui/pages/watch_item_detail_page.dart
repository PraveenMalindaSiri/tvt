import 'package:flutter/material.dart';

import '../../../../core/constants/watch_options.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/watch_tracker_controller.dart';
import '../../models/watch_history_entry.dart';
import '../../models/watch_item.dart';
import '../utils/watch_date_text.dart';
import '../widgets/app_panel.dart';
import '../widgets/badge.dart';

class WatchItemDetailPage extends StatelessWidget {
  const WatchItemDetailPage({
    required this.itemId,
    required this.controller,
    super.key,
  });

  final String itemId;
  final WatchTrackerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final WatchItem? item = controller.findItem(itemId);
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Title')),
            body: const Center(
              child: Text('This title is no longer in your library.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: <Widget>[
              IconButton(
                tooltip: 'Edit',
                onPressed: () => _editItem(context, item),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => _deleteItem(context, item),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.2,
                colors: <Color>[Color(0xFF1D4ED8), AppColors.background],
                stops: <double>[0.0, 0.38],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
              children: <Widget>[
                _header(item),
                const SizedBox(height: 14),
                AppPanel(child: _statusAndPriority(context, item)),
                const SizedBox(height: 14),
                if (item.isEpisodic)
                  AppPanel(child: _episodeProgress(context, item))
                else
                  AppPanel(child: _movieProgress(context, item)),
                const SizedBox(height: 14),
                AppPanel(child: _details(item)),
                const SizedBox(height: 14),
                AppPanel(child: _history(item)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(WatchItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.name,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            BadgeLabel(text: item.category),
            BadgeLabel(text: item.status),
            if (item.isEpisodic) BadgeLabel(text: item.progressLabel),
            if (item.watchNext) const BadgeLabel(text: 'Watch Next'),
          ],
        ),
      ],
    );
  }

  Widget _statusAndPriority(BuildContext context, WatchItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Library Status',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: item.status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: WatchOptions.statuses
              .map(
                (String value) =>
                    DropdownMenuItem<String>(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (String? value) {
            if (value != null) controller.setStatus(item.id, value);
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Watch Next'),
          subtitle: const Text(
            'Keep this title in the priority section on Home.',
          ),
          value: item.watchNext,
          onChanged: item.status == WatchOptions.watchedStatus
              ? null
              : (_) => controller.toggleWatchNext(item.id),
        ),
      ],
    );
  }

  Widget _episodeProgress(BuildContext context, WatchItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Episode Progress',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Text(
          item.progressLabel,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton.icon(
              onPressed: () => _recordEpisode(context, item),
              icon: const Icon(Icons.add),
              label: const Text('Watched Next Episode'),
            ),
            OutlinedButton.icon(
              onPressed: () => _setProgress(context, item),
              icon: const Icon(Icons.tune),
              label: const Text('Set Progress'),
            ),
            if (controller.historyForItem(item.id).isNotEmpty)
              TextButton.icon(
                onPressed: () => _undo(context, item),
                icon: const Icon(Icons.undo),
                label: const Text('Undo Last Watch'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _movieProgress(BuildContext context, WatchItem item) {
    final bool alreadyWatched = item.status == WatchOptions.watchedStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Movie Progress',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Text(
          alreadyWatched ? 'Watched' : 'Not watched yet',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton.icon(
              onPressed: () => _recordMovie(context, item),
              icon: const Icon(Icons.check),
              label: Text(alreadyWatched ? 'Watched Again' : 'Mark Watched'),
            ),
            if (controller.historyForItem(item.id).isNotEmpty)
              TextButton.icon(
                onPressed: () => _undo(context, item),
                icon: const Icon(Icons.undo),
                label: const Text('Undo Last Watch'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _details(WatchItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Details',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        _detailLine(
          'Added',
          item.addedAt == null
              ? 'Not available from old data'
              : shortDateTime(item.addedAt),
        ),
        _detailLine(
          'Last watched',
          item.lastWatchedAt == null
              ? 'Not recorded'
              : shortDateTime(item.lastWatchedAt),
        ),
        _detailLine(
          'Runtime',
          item.runtimeMinutes == null
              ? 'Not set'
              : '${item.runtimeMinutes} min',
        ),
      ],
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.mutedText),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _history(WatchItem item) {
    final List<WatchHistoryEntry> history = controller.historyForItem(item.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Recent History',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          const Text(
            'No detailed watch records yet.',
            style: TextStyle(color: AppColors.mutedText),
          )
        else
          ...history
              .take(10)
              .map(
                (WatchHistoryEntry entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.activityLabel),
                  subtitle: Text(shortDateTime(entry.watchedAt)),
                  trailing: entry.runtimeMinutes == null
                      ? null
                      : Text('${entry.runtimeMinutes} min'),
                ),
              ),
      ],
    );
  }

  Future<void> _recordEpisode(BuildContext context, WatchItem item) async {
    await controller.incrementEpisode(item.id);
    if (!context.mounted) return;
    _showMessage(context, '${item.name}: next episode saved.');
  }

  Future<void> _recordMovie(BuildContext context, WatchItem item) async {
    await controller.markMovieWatched(item.id);
    if (!context.mounted) return;
    _showMessage(context, '${item.name}: watch saved.');
  }

  Future<void> _undo(BuildContext context, WatchItem item) async {
    final bool undone = await controller.undoLastWatch(item.id);
    if (!context.mounted) return;
    _showMessage(
      context,
      undone ? 'Last watch record undone.' : 'Nothing to undo.',
    );
  }

  Future<void> _setProgress(BuildContext context, WatchItem item) async {
    final TextEditingController seasonController = TextEditingController(
      text: item.currentSeason.toString(),
    );
    final TextEditingController episodeController = TextEditingController(
      text: item.currentEpisode.toString(),
    );

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Set Progress'),
        content: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: seasonController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Season'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: episodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Episode'),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save == true) {
      final int season =
          int.tryParse(seasonController.text.trim()) ?? item.currentSeason;
      final int episode =
          int.tryParse(episodeController.text.trim()) ?? item.currentEpisode;
      await controller.setProgress(
        id: item.id,
        season: season,
        episode: episode,
      );
    }

    seasonController.dispose();
    episodeController.dispose();
  }

  Future<void> _editItem(BuildContext context, WatchItem item) async {
    final TextEditingController nameController = TextEditingController(
      text: item.name,
    );
    final TextEditingController runtimeController = TextEditingController(
      text: item.runtimeMinutes?.toString() ?? '',
    );
    String category = item.category;
    String status = item.status;

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => AlertDialog(
            title: const Text('Edit Title'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: WatchOptions.categories
                        .map(
                          (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) =>
                        setState(() => category = value ?? category),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: WatchOptions.statuses
                        .map(
                          (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) =>
                        setState(() => status = value ?? status),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: runtimeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: item.isMovie
                          ? 'Movie runtime (minutes)'
                          : 'Episode runtime (minutes)',
                      hintText: 'Optional',
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (save == true && nameController.text.trim().isNotEmpty) {
      final int? runtime = int.tryParse(runtimeController.text.trim());
      await controller.updateItem(
        id: item.id,
        name: nameController.text,
        category: category,
        status: status,
        runtimeMinutes: runtime,
        clearRuntimeMinutes: runtimeController.text.trim().isEmpty,
      );
    }

    nameController.dispose();
    runtimeController.dispose();
  }

  Future<void> _deleteItem(BuildContext context, WatchItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Title'),
        content: Text('Delete "${item.name}" from your library?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await controller.deleteItem(item.id);
    if (context.mounted) Navigator.pop(context);
  }

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
