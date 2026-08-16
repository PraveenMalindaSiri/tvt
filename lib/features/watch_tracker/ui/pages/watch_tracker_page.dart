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
      if (mounted) _controller.setSearchQuery(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('TVtracker', style: TextStyle(fontWeight: FontWeight.w900)),
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
                  : IndexedStack(
                      index: _tabIndex,
                      children: <Widget>[
                        HomeTab(
                          controller: _controller,
                          onOpenItem: _openItem,
                          onEpisodeWatched: _episodeWatched,
                          onCompleteSeason: _completeSeason,
                          onMovieWatched: _movieWatched,
                        ),
                        LibraryTab(
                          controller: _controller,
                          searchController: _searchController,
                          onOpenItem: _openItem,
                          onToggleWatchNext: _toggleWatchNext,
                          onEpisodeWatched: _episodeWatched,
                          onCompleteSeason: _completeSeason,
                          onMovieWatched: _movieWatched,
                          onClearFilters: _clearFilters,
                        ),
                        StatsTab(
                          controller: _controller,
                          onExport: _exportBackup,
                          onImport: _openImportDialog,
                          onReloadDefault: _reloadDefaultBackup,
                          onDeleteAll: _deleteAll,
                        ),
                      ],
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
        onAdd: (String name, String category, bool watchNext, List<int> counts) {
          return _controller.addItem(
            name: name,
            category: category,
            status: WatchOptions.toWatchStatus,
            watchNext: watchNext,
            seasonEpisodeCounts: counts,
          );
        },
      ),
    );
    if (added == true) _showMessage('Added to To Watch.');
  }

  void _openItem(WatchItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WatchItemDetailPage(itemId: item.id, controller: _controller),
      ),
    );
  }

  Future<void> _episodeWatched(WatchItem item) async {
    final String message = await _controller.incrementEpisode(item.id);
    if (mounted) _showMessage(message);
  }

  Future<void> _completeSeason(WatchItem item) async {
    final String message = await _controller.completeSeason(item.id);
    if (mounted) _showMessage(message);
  }

  Future<void> _movieWatched(WatchItem item) async {
    await _controller.markMovieWatched(item.id);
    if (mounted) _showMessage('${item.name}: watched date saved.');
  }

  Future<void> _toggleWatchNext(WatchItem item) => _controller.toggleWatchNext(item.id);

  void _clearFilters() {
    if (_searchController.text.isNotEmpty) _searchController.clear();
    _searchDebounce?.cancel();
    _controller.clearFilters();
  }

  Future<void> _exportBackup() async {
    final bool? copied = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => ExportBackupDialog(jsonText: _controller.exportBackupJson()),
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
      if (!await _confirm('Import $count titles? This replaces the current local library.')) return false;
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
    if (_controller.items.isEmpty) return;
    if (!await _confirm('Delete the whole local library? Export a backup first if needed.')) return;
    await _controller.deleteAll();
    _clearFilters();
    _showMessage('All local tracker data deleted.');
  }

  Future<void> _reloadDefaultBackup() async {
    if (!await _confirm('Reload the bundled default backup? This replaces your current local library.')) return;
    try {
      final int count = await _controller.loadDefaultBackup();
      _clearFilters();
      _showMessage('Default backup loaded: $count titles.');
    } catch (error) {
      _showMessage('Could not load default backup: $error');
    }
  }

  Future<bool> _confirm(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext d) => AlertDialog(
            title: const Text('Confirm'),
            content: Text(message),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('OK')),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
