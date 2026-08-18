import 'package:flutter/material.dart';

import '../../../../core/constants/watch_options.dart';
import '../../controllers/watch_tracker_controller.dart';
import '../widgets/app_panel.dart';
import '../widgets/stat_card.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({
    required this.controller,
    required this.onExport,
    required this.onImport,
    required this.onReloadDefault,
    required this.onDeleteAll,
    super.key,
  });

  final WatchTrackerController controller;
  final VoidCallback onExport;
  final VoidCallback onImport;
  final VoidCallback onReloadDefault;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    final List<StatCard> cards = <StatCard>[
      StatCard(label: 'Total Titles', value: controller.items.length),
      StatCard(label: 'Watched', value: controller.countByStatus(WatchOptions.watchedStatus)),
      StatCard(label: 'Watching', value: controller.countByStatus(WatchOptions.watchingStatus)),
      StatCard(label: 'To Watch', value: controller.countByStatus(WatchOptions.toWatchStatus)),
      StatCard(label: 'Movies', value: controller.countByCategory('Movie')),
      StatCard(label: 'Anime', value: controller.countByCategory('Anime')),
      StatCard(label: 'Series', value: controller.countByCategory('Series')),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 110),
      children: <Widget>[
        const Text('Stats', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int columns = constraints.maxWidth < 650 ? 2 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 102,
              ),
              itemBuilder: (_, int index) => cards[index],
            );
          },
        ),
        const SizedBox(height: 14),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Backup & Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Export or restore your offline library.', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 14),
              FilledButton.icon(onPressed: onExport, icon: const Icon(Icons.upload_file), label: const Text('Export Backup')),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(onPressed: onImport, icon: const Icon(Icons.file_open), label: const Text('Import Backup')),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: onReloadDefault, icon: const Icon(Icons.restore), label: const Text('Reload Bundled Default Backup')),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: onDeleteAll, icon: const Icon(Icons.delete_sweep_outlined), label: const Text('Delete All Local Data')),
            ],
          ),
        ),
      ],
    );
  }
}
