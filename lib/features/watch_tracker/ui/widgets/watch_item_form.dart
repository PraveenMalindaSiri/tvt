import 'package:flutter/material.dart';

import '../../../../core/constants/watch_options.dart';
import 'responsive_field.dart';

class WatchItemForm extends StatelessWidget {
  const WatchItemForm({
    required this.nameController,
    required this.nameFocus,
    required this.selectedCategory,
    required this.selectedStatus,
    required this.isEditing,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onSubmit,
    required this.onCancelEdit,
    super.key,
  });

  static final List<DropdownMenuItem<String>> _categoryItems = WatchOptions.categories
      .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
      .toList(growable: false);

  static final List<DropdownMenuItem<String>> _statusItems = WatchOptions.statuses
      .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
      .toList(growable: false);

  final TextEditingController nameController;
  final FocusNode nameFocus;
  final String selectedCategory;
  final String selectedStatus;
  final bool isEditing;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < 760;
        final List<ResponsiveField> fields = <ResponsiveField>[
          ResponsiveField(
            flex: 2,
            child: TextField(
              controller: nameController,
              focusNode: nameFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Example: Bleach',
              ),
            ),
          ),
          ResponsiveField(
            child: DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categoryItems,
              onChanged: onCategoryChanged,
            ),
          ),
          ResponsiveField(
            child: DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _statusItems,
              onChanged: onStatusChanged,
            ),
          ),
          ResponsiveField(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton(
                  onPressed: onSubmit,
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
                if (isEditing)
                  OutlinedButton(
                    onPressed: onCancelEdit,
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ),
        ];

        if (narrow) return _buildColumn(fields);
        return _buildRow(fields);
      },
    );
  }

  Widget _buildColumn(List<ResponsiveField> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: fields
          .map(
            (ResponsiveField field) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: field,
            ),
          )
          .toList(),
    );
  }

  Widget _buildRow(List<ResponsiveField> fields) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: fields
          .map(
            (ResponsiveField field) => Expanded(
              flex: field.flex,
              child: Padding(
                padding: const EdgeInsets.only(right: 15),
                child: field,
              ),
            ),
          )
          .toList(),
    );
  }
}
