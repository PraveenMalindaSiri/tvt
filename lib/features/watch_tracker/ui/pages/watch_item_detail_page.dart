import 'package:flutter/material.dart';

import '../../../../core/constants/watch_options.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/watch_tracker_controller.dart';
import '../../models/watch_item.dart';
import '../utils/watch_date_text.dart';
import '../widgets/app_panel.dart';
import '../widgets/badge.dart';

class WatchItemDetailPage extends StatelessWidget {
  const WatchItemDetailPage({required this.itemId, required this.controller, super.key});

  final String itemId;
  final WatchTrackerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final WatchItem? item = controller.findItem(itemId);
        if (item == null) {
          return Scaffold(appBar: AppBar(title: const Text('Title')), body: const Center(child: Text('This title is no longer in your library.')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: <Widget>[
              IconButton(tooltip: 'Edit title', onPressed: () => _editItem(context, item), icon: const Icon(Icons.edit_outlined)),
              IconButton(tooltip: 'Delete', onPressed: () => _deleteItem(context, item), icon: const Icon(Icons.delete_outline)),
            ],
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(center: Alignment.topLeft, radius: 1.2, colors: <Color>[Color(0xFF1D4ED8), AppColors.background], stops: <double>[0.0, 0.38]),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 40),
              children: <Widget>[
                Text(item.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                  BadgeLabel(text: item.category),
                  BadgeLabel(text: item.status),
                  if (item.isEpisodic) BadgeLabel(text: item.progressLabel),
                  if (item.watchNext) const BadgeLabel(text: 'Watch Next'),
                ]),
                const SizedBox(height: 14),
                AppPanel(child: _statusPanel(item)),
                const SizedBox(height: 12),
                if (item.isEpisodic) AppPanel(child: _episodePanel(context, item)) else AppPanel(child: _moviePanel(context, item)),
                const SizedBox(height: 12),
                AppPanel(child: _datePanel(item)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusPanel(WatchItem item) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text('Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: item.status,
            decoration: const InputDecoration(labelText: 'Library status'),
            items: WatchOptions.statuses.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
            onChanged: (String? value) {
              if (value != null) controller.setStatus(item.id, value);
            },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Watch Next'),
            value: item.watchNext,
            onChanged: item.status == WatchOptions.watchedStatus ? null : (_) => controller.toggleWatchNext(item.id),
          ),
        ],
      );

  Widget _episodePanel(BuildContext context, WatchItem item) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text('Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(item.progressLabel, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(item.structureLabel, style: const TextStyle(color: AppColors.mutedText)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
            FilledButton.icon(onPressed: item.status == WatchOptions.watchedStatus ? null : () => _recordEpisode(context, item), icon: const Icon(Icons.add), label: const Text('Episode')),
            OutlinedButton(onPressed: item.status == WatchOptions.watchedStatus ? null : () => _completeSeason(context, item), child: const Text('Complete Season')),
            OutlinedButton.icon(onPressed: () => _setProgress(context, item), icon: const Icon(Icons.tune), label: const Text('Set Progress')),
            OutlinedButton.icon(onPressed: () => _editSeasonPlan(context, item), icon: const Icon(Icons.format_list_numbered), label: const Text('Edit Seasons')),
          ]),
          if (item.seasonEpisodeCounts.any((int count) => count == 0)) ...<Widget>[
            const SizedBox(height: 10),
            const Text('“?” / unknown season totals are allowed for imported titles. Set the totals to enforce exact episode limits.', style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
          ],
        ],
      );

  Widget _moviePanel(BuildContext context, WatchItem item) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text('Movie', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(item.status == WatchOptions.watchedStatus ? 'Watched' : 'Not watched yet', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () => _recordMovie(context, item), icon: const Icon(Icons.check), label: Text(item.status == WatchOptions.watchedStatus ? 'Update Watched Date to Today' : 'Mark Watched')),
        ],
      );

  Widget _datePanel(WatchItem item) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text('Dates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _line('Added', item.addedAt == null ? 'Unknown' : shortDate(item.addedAt)),
          if (item.status == WatchOptions.watchingStatus) _line('Last progress', item.lastWatchedAt == null ? 'Unknown' : shortDate(item.lastWatchedAt)),
          _line('Completed', item.completedAt == null ? 'Not completed' : shortDate(item.completedAt)),
        ],
      );

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: <Widget>[SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.mutedText))), Expanded(child: Text(value))]),
      );

  Future<void> _recordEpisode(BuildContext context, WatchItem item) async {
    final String message = await controller.incrementEpisode(item.id);
    if (context.mounted) _message(context, message);
  }

  Future<void> _completeSeason(BuildContext context, WatchItem item) async {
    final String message = await controller.completeSeason(item.id);
    if (context.mounted) _message(context, message);
  }

  Future<void> _recordMovie(BuildContext context, WatchItem item) async {
    await controller.markMovieWatched(item.id);
    if (context.mounted) _message(context, '${item.name}: watched date saved.');
  }

  Future<void> _setProgress(BuildContext context, WatchItem item) async {
    final TextEditingController season = TextEditingController(text: item.currentSeason.toString());
    final TextEditingController episode = TextEditingController(text: item.currentEpisode.toString());
    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext d) => AlertDialog(
        title: const Text('Set Progress'),
        content: Row(children: <Widget>[
          Expanded(child: TextField(controller: season, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Season (1-${item.seasonCount})'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: episode, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Episode'))),
        ]),
        actions: <Widget>[TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Save'))],
      ),
    );
    if (save == true) {
      final String? error = await controller.setProgress(id: item.id, season: int.tryParse(season.text) ?? item.currentSeason, episode: int.tryParse(episode.text) ?? item.currentEpisode);
      if (context.mounted && error != null) _message(context, error);
    }
    season.dispose();
    episode.dispose();
  }

  Future<void> _editSeasonPlan(BuildContext context, WatchItem item) async {
    final TextEditingController countController = TextEditingController(text: item.seasonCount.toString());
    final List<TextEditingController> eps = item.seasonEpisodeCounts.map((int value) => TextEditingController(text: value == 0 ? '' : value.toString())).toList();

    final List<int>? result = await showDialog<List<int>>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          void resize(String value) {
            final int count = (int.tryParse(value) ?? 1).clamp(1, 50).toInt();
            while (eps.length < count) eps.add(TextEditingController());
            while (eps.length > count) eps.removeLast().dispose();
            setState(() {});
          }
          return AlertDialog(
            title: const Text('Edit Seasons'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(children: <Widget>[
                  TextField(controller: countController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Number of seasons'), onChanged: resize),
                  const SizedBox(height: 12),
                  ...List<Widget>.generate(eps.length, (int i) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: TextField(controller: eps[i], keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Season ${i + 1} episodes', hintText: 'blank = unknown')),
                  )),
                ]),
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, eps.map((TextEditingController c) => int.tryParse(c.text.trim()) ?? 0).toList()), child: const Text('Save')),
            ],
          );
        },
      ),
    );

    if (result != null) {
      final String? error = await controller.setSeasonPlan(item.id, result);
      if (context.mounted) _message(context, error ?? 'Season structure saved.');
    }
    countController.dispose();
    for (final TextEditingController c in eps) c.dispose();
  }

  Future<void> _editItem(BuildContext context, WatchItem item) async {
    final TextEditingController name = TextEditingController(text: item.name);
    String category = item.category;
    String status = item.status;
    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext d) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          title: const Text('Edit Title'),
          content: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'Category'), items: WatchOptions.categories.map((String v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(), onChanged: (String? v) => setState(() => category = v ?? category)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(initialValue: status, decoration: const InputDecoration(labelText: 'Status'), items: WatchOptions.statuses.map((String v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(), onChanged: (String? v) => setState(() => status = v ?? status)),
          ])),
          actions: <Widget>[TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Save'))],
        ),
      ),
    );
    if (save == true) {
      final String? error = await controller.updateItem(id: item.id, name: name.text, category: category, status: status);
      if (context.mounted && error != null) _message(context, error);
    }
    name.dispose();
  }

  Future<void> _deleteItem(BuildContext context, WatchItem item) async {
    final bool? yes = await showDialog<bool>(context: context, builder: (BuildContext d) => AlertDialog(title: const Text('Delete Title'), content: Text('Delete "${item.name}"?'), actions: <Widget>[TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete'))]));
    if (yes != true) return;
    await controller.deleteItem(item.id);
    if (context.mounted) Navigator.pop(context);
  }

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(SnackBar(content: Text(text)));
  }
}
