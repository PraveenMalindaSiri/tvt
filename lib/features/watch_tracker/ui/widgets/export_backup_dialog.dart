import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

class ExportBackupDialog extends StatelessWidget {
  const ExportBackupDialog({required this.jsonText, super.key});

  final String jsonText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Backup'),
      content: SizedBox(
        width: 680,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Copy this JSON and save it as your backup.'),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 360),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.panelLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonText,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: jsonText));
            if (context.mounted) Navigator.pop(context, true);
          },
          child: const Text('Copy'),
        ),
      ],
    );
  }
}
