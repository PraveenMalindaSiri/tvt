import 'package:flutter/material.dart';

import '../../../../core/constants/watch_options.dart';
import '../../models/watch_filter.dart';
import 'responsive_field.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    required this.searchController,
    required this.filter,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onClearFilters,
    super.key,
  });

  static final List<DropdownMenuItem<String>> _categoryFilterItems = <String>[
    WatchOptions.allFilter,
    ...WatchOptions.categories,
  ]
      .map(
        (String value) => DropdownMenuItem<String>(
          value: value,
          child: Text(value == WatchOptions.allFilter ? 'All categories' : value),
        ),
      )
      .toList(growable: false);

  static final List<DropdownMenuItem<String>> _statusFilterItems = <String>[
    WatchOptions.allFilter,
    ...WatchOptions.statuses,
  ]
      .map(
        (String value) => DropdownMenuItem<String>(
          value: value,
          child: Text(value == WatchOptions.allFilter ? 'All statuses' : value),
        ),
      )
      .toList(growable: false);

  final TextEditingController searchController;
  final WatchFilter filter;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < 760;
        final List<ResponsiveField> fields = <ResponsiveField>[
          ResponsiveField(
            flex: 2,
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          ResponsiveField(
            child: DropdownButtonFormField<String>(
              value: filter.category,
              decoration: const InputDecoration(labelText: 'Category filter'),
              items: _categoryFilterItems,
              onChanged: onCategoryChanged,
            ),
          ),
          ResponsiveField(
            child: DropdownButtonFormField<String>(
              value: filter.status,
              decoration: const InputDecoration(labelText: 'Status filter'),
              items: _statusFilterItems,
              onChanged: onStatusChanged,
            ),
          ),
          ResponsiveField(
            child: OutlinedButton.icon(
              onPressed: filter.hasActiveFilters ? onClearFilters : null,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
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
