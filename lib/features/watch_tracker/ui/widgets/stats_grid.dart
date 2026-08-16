import 'package:flutter/material.dart';

import '../../../../core/constants/watch_options.dart';
import '../../controllers/watch_tracker_controller.dart';
import 'stat_card.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({required this.controller, super.key});

  final WatchTrackerController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compactLayout = constraints.maxWidth < 700;
        final int columnCount = compactLayout ? 2 : 4;

        final double cardHeight = compactLayout ? 100 : 94;

        final List<StatCard> cards = <StatCard>[
          StatCard(label: 'Total', value: controller.items.length),
          StatCard(
            label: 'Watched',
            value: controller.countByStatus(WatchOptions.statuses[0]),
          ),
          StatCard(
            label: 'Watching',
            value: controller.countByStatus(WatchOptions.statuses[1]),
          ),
          StatCard(
            label: 'To Watch',
            value: controller.countByStatus(WatchOptions.statuses[2]),
          ),
        ];

        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (BuildContext context, int index) => cards[index],
        );
      },
    );
  }
}
