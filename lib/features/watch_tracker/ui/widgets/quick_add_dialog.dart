import 'package:flutter/material.dart';

import '../../../../core/constants/watch_options.dart';

class QuickAddDialog extends StatefulWidget {
  const QuickAddDialog({
    required this.onAdd,
    super.key,
  });

  final Future<void> Function(String name, String category, bool watchNext) onAdd;

  @override
  State<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<QuickAddDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _category = WatchOptions.defaultCategory;
  bool _watchNext = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quick Add'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _nameController,
              autofocus: true,
              enabled: !_saving,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Example: Bleach',
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: WatchOptions.categories
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (String? value) {
                      setState(() => _category = value ?? WatchOptions.defaultCategory);
                    },
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Watch Next'),
              subtitle: const Text('Pin this near the top of your backlog.'),
              value: _watchNext,
              onChanged: _saving ? null : (bool value) => setState(() => _watchNext = value),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Adding...' : 'Add to To Watch'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;

    setState(() => _saving = true);
    await widget.onAdd(name, _category, _watchNext);
    if (!mounted) return;
    Navigator.pop(context, true);
  }
}
