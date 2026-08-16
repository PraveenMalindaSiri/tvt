import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.onLoadSeedItems,
    required this.onExportBackup,
    required this.onImportBackup,
    super.key,
  });

  final VoidCallback onLoadSeedItems;
  final VoidCallback onExportBackup;
  final VoidCallback onImportBackup;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < 820;
        final Widget title = _buildTitle();
        final Widget actions = _buildActions(narrow);

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[title, const SizedBox(height: 16), actions],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(child: title),
            const SizedBox(width: 18),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Offline • No database • Local device only',
          style: TextStyle(
            color: AppColors.successText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'TVtracker',
          style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, height: 1),
        ),
        SizedBox(height: 12),
        Text(
          'Track movies, series, and anime.',
          style: TextStyle(color: AppColors.mutedText),
        ),
      ],
    );
  }

  Widget _buildActions(bool narrow) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: narrow ? WrapAlignment.start : WrapAlignment.end,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: onLoadSeedItems,
          icon: const Icon(Icons.download),
          label: const Text('Load TV Time Import'),
        ),
        FilledButton.icon(
          onPressed: onExportBackup,
          icon: const Icon(Icons.upload_file),
          label: const Text('Export'),
        ),
        FilledButton.tonalIcon(
          onPressed: onImportBackup,
          icon: const Icon(Icons.file_open),
          label: const Text('Import'),
        ),
      ],
    );
  }
}
