import 'package:flutter/material.dart';

import '../../../../core/constants/watch_options.dart';

class QuickAddDialog extends StatefulWidget {
  const QuickAddDialog({required this.onAdd, super.key});

  final Future<void> Function(
    String name,
    String category,
    bool watchNext,
    List<int> seasonEpisodeCounts,
  ) onAdd;

  @override
  State<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<QuickAddDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _seasonCountController = TextEditingController(text: '1');
  final List<TextEditingController> _episodeControllers = <TextEditingController>[
    TextEditingController(),
  ];
  String _category = WatchOptions.defaultCategory;
  bool _watchNext = false;
  bool _saving = false;

  bool get _isMovie => _category == 'Movie';

  @override
  void dispose() {
    _nameController.dispose();
    _seasonCountController.dispose();
    for (final TextEditingController controller in _episodeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setSeasonCount(String value) {
    final int count = (int.tryParse(value) ?? 1).clamp(1, 50).toInt();
    while (_episodeControllers.length < count) {
      _episodeControllers.add(TextEditingController());
    }
    while (_episodeControllers.length > count) {
      _episodeControllers.removeLast().dispose();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Title'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _nameController,
                autofocus: true,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: WatchOptions.categories
                    .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                    .toList(),
                onChanged: _saving
                    ? null
                    : (String? value) => setState(() => _category = value ?? WatchOptions.defaultCategory),
              ),
              if (!_isMovie) ...<Widget>[
                const SizedBox(height: 14),
                TextField(
                  controller: _seasonCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Number of seasons',
                    helperText: 'You can change this later from the title details.',
                  ),
                  onChanged: _setSeasonCount,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Episodes per season', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                ...List<Widget>.generate(
                  _episodeControllers.length,
                  (int index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: _episodeControllers[index],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Season ${index + 1} episodes',
                        hintText: '0 / blank = unknown',
                      ),
                    ),
                  ),
                ),
              ],
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Watch Next'),
                subtitle: const Text('Pin this in your priority list.'),
                value: _watchNext,
                onChanged: _saving ? null : (bool value) => setState(() => _watchNext = value),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Adding...' : 'Add')),
      ],
    );
  }

  Future<void> _save() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;
    final List<int> counts = _isMovie
        ? const <int>[]
        : _episodeControllers
            .map((TextEditingController c) => int.tryParse(c.text.trim()) ?? 0)
            .map((int value) => value < 0 ? 0 : value)
            .toList();
    setState(() => _saving = true);
    await widget.onAdd(name, _category, _watchNext, counts);
    if (!mounted) return;
    Navigator.pop(context, true);
  }
}
