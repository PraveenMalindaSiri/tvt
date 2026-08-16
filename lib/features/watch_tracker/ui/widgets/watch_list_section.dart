import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/watch_item.dart';
import 'watch_item_tile.dart';

class WatchListSection extends StatelessWidget {
  const WatchListSection({
    required this.items,
    required this.hasAnyItems,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onDeleteAll,
    super.key,
  });

  static const int _eagerBuildLimit = 30;
  static const double _largeListHeight = 560;

  final List<WatchItem> items;
  final bool hasAnyItems;
  final ValueChanged<WatchItem> onEditItem;
  final ValueChanged<WatchItem> onDeleteItem;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildHeader(),
        const SizedBox(height: 12),
        if (items.isEmpty) _buildEmptyState() else _buildList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            'Your List',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: hasAnyItems ? onDeleteAll : null,
          icon: const Icon(Icons.delete_sweep),
          label: const Text('Delete All'),
          style: FilledButton.styleFrom(
            foregroundColor: AppColors.dangerText,
            backgroundColor: AppColors.dangerSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'No items yet. Add one or load your TV Time import.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.mutedText),
      ),
    );
  }

  Widget _buildList() {
    if (items.length <= _eagerBuildLimit) {
      return Column(
        children: <Widget>[
          for (int index = 0; index < items.length; index++) ...<Widget>[
            _buildTile(items[index]),
            if (index != items.length - 1) const Divider(color: AppColors.border),
          ],
        ],
      );
    }

    return SizedBox(
      height: _largeListHeight,
      child: Scrollbar(
        child: ListView.separated(
          primary: false,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          cacheExtent: 700,
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(color: AppColors.border),
          itemBuilder: (BuildContext context, int index) => _buildTile(items[index]),
        ),
      ),
    );
  }

  Widget _buildTile(WatchItem item) {
    return RepaintBoundary(
      child: WatchItemTile(
        key: ValueKey<String>(item.id),
        item: item,
        onEdit: () => onEditItem(item),
        onDelete: () => onDeleteItem(item),
      ),
    );
  }
}
