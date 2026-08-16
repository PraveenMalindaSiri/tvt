import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/watch_item.dart';
import 'badge.dart';

class WatchItemTile extends StatelessWidget {
  const WatchItemTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final WatchItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool narrow = constraints.maxWidth < 620;
          final Widget titleAndBadges = _buildTitleAndBadges();
          final Widget actions = _buildActions();

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[titleAndBadges, const SizedBox(height: 10), actions],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: titleAndBadges),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitleAndBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            BadgeLabel(text: item.category),
            BadgeLabel(text: item.status),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        OutlinedButton(
          onPressed: onEdit,
          child: const Text('Edit'),
        ),
        FilledButton.tonal(
          onPressed: onDelete,
          style: FilledButton.styleFrom(
            foregroundColor: AppColors.dangerText,
            backgroundColor: AppColors.dangerSurface,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
