import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/watch_options.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/watch_tracker_controller.dart';
import '../../models/watch_item.dart';
import '../../services/backup_service.dart';
import '../../services/watch_storage_service.dart';
import '../widgets/export_backup_dialog.dart';
import '../widgets/import_backup_dialog.dart';
import '../widgets/quick_add_dialog.dart';
import 'history_tab.dart';
import 'home_tab.dart';
import 'library_tab.dart';
import 'stats_tab.dart';
import 'watch_item_detail_page.dart';

class WatchTrackerPage extends StatefulWidget {
  const WatchTrackerPage({super.key});

  @override
  State<WatchTrackerPage> createState() => _WatchTrackerPageState();
}

class _WatchTrackerPageState extends State<WatchTrackerPage> {
  late final WatchTrackerController _controller;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = WatchTrackerController(
      storageService: const WatchStorageService(),
      backupService: const BackupService(),
    );
    _controller.init();
    _searchController.addListener(_syncSearchText);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_syncSearchText)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncSearchText() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _controller.setSearchQuery(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'TVtracker',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: <Widget>[
              IconButton(
                tooltip: 'Export backup',
                onPressed: _controller.isLoading ? null : _exportBackup,
                icon: const Icon(Icons.upload_file),
              ),
              PopupMenuButton<String>(
                onSelected: _handleMenu,
                itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'import',
                    child: ListTile(
                      leading: Icon(Icons.file_open),
                      title: Text('Import Backup'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'reload_default',
                    child: ListTile(
                      leading: Icon(Icons.restore),
                      title: Text('Reload Default Backup'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete_all',
                    child: ListTile(
                      leading: Icon(Icons.delete_sweep_outlined),
                      title: Text('Delete All Data'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.2,
                colors: <Color>[Color(0xFF1D4ED8), AppColors.background],
                stops: <double>[0.0, 0.38],
              ),
            ),
            child: SafeArea(
              top: false,
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1150),
                        child: IndexedStack(
                          index: _tabIndex,
                          children: <Widget>[
                            HomeTab(
                              controller: _controller,
                              onOpenItem: _openItem,
                              onEpisodeWatched: _episodeWatched,
                              onMovieWatched: _movieWatched,
                            ),
                            LibraryTab(
                              controller: _controller,
                              searchController: _searchController,
                              onOpenItem: _openItem,
                              onToggleWatchNext: _toggleWatchNext,
                              onEpisodeWatched: _episodeWatched,
                              onMovieWatched: _movieWatched,
                              onClearFilters: _clearFilters,
                            ),
                            HistoryTab(controller: _controller),
                            StatsTab(controller: _controller),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          floatingActionButton: _controller.isLoading
              ? null
              : FloatingActionButton.extended(
                  onPressed: _quickAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (int value) => setState(() => _tabIndex = value),
            destinations: const <NavigationDestination>[
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library), label: 'Library'),
              NavigationDestination(icon: Icon(Icons.history), label: 'History'),
              NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Stats'),
            ],
          ),
        );
      },
    );
  }

  Future<void> _quickAdd() async {
    final bool? added = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => QuickAddDialog(
        onAdd: (String name, String category, bool watchNext) {
          return _controller.addItem(
            name: name,
            category: category,
            status: WatchOptions.toWatchStatus,
            watchNext: watchNext,
          );
        },
      ),
    );

    if (added == true) {
      _showMessage('Added to To Watch.');
    }
  }

  void _openItem(WatchItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WatchItemDetailPage(
          itemId: item.id,
          controller: _controller,
        ),
      ),
    );
  }

  Future<void> _episodeWatched(WatchItem item) async {
    await _controller.incrementEpisode(item.id);
    if (!mounted) return;
    final WatchItem? updated = _controller.findItem(item.id);
    _showMessage(
      updated == null
          ? 'Episode saved.'
          : '${updated.name}: ${updated.progressLabel} saved.',
      actionLabel: 'Undo',
      action: () => _controller.undoLastWatch(item.id),
    );
  }

  Future<void> _movieWatched(WatchItem item) async {
    await _controller.markMovieWatched(item.id);
    if (!mounted) return;
    _showMessage(
      '${item.name}: watched.',
      actionLabel: 'Undo',
      action: () => _controller.undoLastWatch(item.id),
    );
  }

  Future<void> _toggleWatchNext(WatchItem item) async {
    await _controller.toggleWatchNext(item.id);
  }

  void _clearFilters() {
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    _searchDebounce?.cancel();
    _controller.clearFilters();
  }

  Future<void> _exportBackup() async {
    final String jsonText = _controller.exportBackupJson();
    final bool? copied = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => ExportBackupDialog(jsonText: jsonText),
    );
    if (copied == true) _showMessage('Backup JSON copied.');
  }

  Future<void> _openImportDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => ImportBackupDialog(onImport: _importBackupText),
    );
  }

  Future<bool> _importBackupText(String text) async {
    try {
      final int count = _controller.countBackupItems(text);
      final bool confirmed = await _confirm(
        'Import $count titles? This replaces the current library and detailed history.',
      );
      if (!confirmed) return false;

      await _controller.importBackup(text);
      _clearFilters();
      _showMessage('Backup imported.');
      return true;
    } catch (error) {
      _showMessage('Could not import JSON: $error');
      return false;
    }
  }

  Future<void> _deleteAll() async {
    if (_controller.items.isEmpty && _controller.history.isEmpty) return;
    final bool confirmed = await _confirm(
      'Delete the whole library and watch history? Export a backup first if needed.',
    );
    if (!confirmed) return;
    await _controller.deleteAll();
    _clearFilters();
    _showMessage('All local tracker data deleted.');
  }

  Future<void> _reloadDefaultBackup() async {
    final bool confirmed = await _confirm(
      'Reload the bundled default backup? This replaces the current library and watch history.',
    );
    if (!confirmed) return;

    try {
      final int count = await _controller.loadDefaultBackup();
      _clearFilters();
      _showMessage('Default backup loaded: $count titles.');
    } catch (error) {
      _showMessage('Could not load default backup: $error');
    }
  }

  Future<void> _handleMenu(String value) async {
    if (value == 'import') {
      await _openImportDialog();
    } else if (value == 'reload_default') {
      await _reloadDefaultBackup();
    } else if (value == 'delete_all') {
      await _deleteAll();
    }
  }

  Future<bool> _confirm(String message) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showMessage(
    String message, {
    String? actionLabel,
    VoidCallback? action,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: actionLabel == null || action == null
              ? null
              : SnackBarAction(label: actionLabel, onPressed: action),
        ),
      );
  }
}
