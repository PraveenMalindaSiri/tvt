import 'package:flutter/material.dart';

class ImportBackupDialog extends StatefulWidget {
  const ImportBackupDialog({
    required this.onImport,
    super.key,
  });

  final Future<bool> Function(String text) onImport;

  @override
  State<ImportBackupDialog> createState() => _ImportBackupDialogState();
}

class _ImportBackupDialogState extends State<ImportBackupDialog> {
  final TextEditingController _textController = TextEditingController();
  bool _isImporting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Backup'),
      content: SizedBox(
        width: 680,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Paste a JSON backup here. It can be either an array or an object with an items array.'),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              minLines: 8,
              maxLines: 14,
              enabled: !_isImporting,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                hintText: '{ "items": [...] }',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isImporting ? null : _handleImport,
          child: Text(_isImporting ? 'Importing...' : 'Import'),
        ),
      ],
    );
  }

  Future<void> _handleImport() async {
    setState(() => _isImporting = true);
    final bool imported = await widget.onImport(_textController.text);
    if (!mounted) return;
    setState(() => _isImporting = false);
    if (imported) Navigator.pop(context);
  }
}
