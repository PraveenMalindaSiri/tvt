import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../controllers/watch_tracker_controller.dart';
import '../../models/watch_history_entry.dart';
import '../utils/watch_date_text.dart';
import '../widgets/app_panel.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({required this.controller, super.key});

  final WatchTrackerController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 92),
      child: AppPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Watch History',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Exact local watch records created by this version of the app.',
              style: TextStyle(color: AppColors.mutedText),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: controller.history.isEmpty
                  ? const Center(
                      child: Text(
                        'No detailed history yet. Your old v1 list did not contain exact watch timestamps.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    )
                  : Scrollbar(
                      child: ListView.separated(
                        itemCount: controller.history.length,
                        separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          return _historyRow(controller.history[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyRow(WatchHistoryEntry entry) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Icon(entry.isMovie ? Icons.movie_outlined : Icons.play_arrow),
      ),
      title: Text(entry.itemName),
      subtitle: Text('${entry.activityLabel}\n${shortDateTime(entry.watchedAt)}'),
      isThreeLine: true,
      trailing: entry.runtimeMinutes == null ? null : Text('${entry.runtimeMinutes} min'),
    );
  }
}
