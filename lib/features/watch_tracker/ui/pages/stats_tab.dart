import 'package:flutter/material.dart';

import '../../../../core/constants/watch_options.dart';
import '../../controllers/watch_tracker_controller.dart';
import '../utils/watch_date_text.dart';
import '../widgets/app_panel.dart';
import '../widgets/stat_card.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({required this.controller, super.key});

  final WatchTrackerController controller;

  @override
  Widget build(BuildContext context) {
    final List<StatCard> cards = <StatCard>[
      StatCard(label: 'Total Titles', value: controller.items.length),
      StatCard(
        label: 'Watched',
        value: controller.countByStatus(WatchOptions.watchedStatus),
      ),
      StatCard(
        label: 'Watching',
        value: controller.countByStatus(WatchOptions.watchingStatus),
      ),
      StatCard(
        label: 'To Watch',
        value: controller.countByStatus(WatchOptions.toWatchStatus),
      ),
      StatCard(label: 'Episodes Tracked', value: controller.episodesWatched),
      StatCard(label: 'Watched Movies', value: controller.watchedMovies),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
      children: <Widget>[
        const Text(
          'Stats',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int columns = constraints.maxWidth < 650 ? 2 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 100,
              ),
              itemBuilder: (_, int index) => cards[index],
            );
          },
        ),
        const SizedBox(height: 14),
        AppPanel(
          child: Row(
            children: <Widget>[
              const Icon(Icons.schedule, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Tracked Watch Time',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      compactDuration(controller.watchTimeMinutes),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Only records with a known runtime are included.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
