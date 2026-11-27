import 'package:flutter/material.dart';

import '../models/diary_entry.dart';
import '../services/diary_services.dart';
import '../utils/formatters.dart';
import '../widgets/entry_image.dart';
import '../widgets/entry_tile.dart';
import 'new_entry_screen.dart';

/// Home screen: the scrollable feed of saved entries, newest first.
class DiaryFeedScreen extends StatefulWidget {
  const DiaryFeedScreen({super.key, required this.services});

  final DiaryServices services;

  @override
  State<DiaryFeedScreen> createState() => _DiaryFeedScreenState();
}

class _DiaryFeedScreenState extends State<DiaryFeedScreen> {
  List<DiaryEntry> _entries = const [];
  bool _loading = true;

  DiaryServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _services.repository.load();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _addEntry() async {
    final entry = await Navigator.push<DiaryEntry>(
      context,
      MaterialPageRoute(builder: (_) => NewEntryScreen(services: _services)),
    );
    if (entry == null || !mounted) return;
    final updated = [entry, ..._entries];
    setState(() => _entries = updated);
    final ok = await _services.repository.save(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          ok ? 'Entry saved' : 'Shown now, but storage is full - it will not survive a restart.',
        ),
      ),
    );
  }

  Future<void> _delete(DiaryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('The photo and its location will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final updated = _entries.where((e) => e.id != entry.id).toList();
    setState(() => _entries = updated);
    await _services.repository.save(updated);
    try {
      await _services.photos.delete(entry.photoPath);
    } catch (_) {
      // The entry is gone either way; a leftover file is harmless.
    }
  }

  void _showDetails(DiaryEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EntryDetails(
        entry: entry,
        imagePath: _services.photos.resolve(entry.photoPath),
        onDelete: () {
          Navigator.pop(context);
          _delete(entry);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Diary'),
        actions: [
          if (_entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_entries.length} '
                  '${_entries.length == 1 ? 'entry' : 'entries'}',
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('New entry'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? const _EmptyFeed()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: _entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return EntryTile(
                  key: ValueKey(entry.id),
                  entry: entry,
                  imagePath: _services.photos.resolve(entry.photoPath),
                  onTap: () => _showDetails(entry),
                );
              },
            ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.travel_explore,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('No entries yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Tap "New entry" to take a photo. It is tagged with your GPS '
              'position and kept on this device, even offline.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryDetails extends StatelessWidget {
  const _EntryDetails({
    required this.entry,
    required this.imagePath,
    required this.onDelete,
  });

  final DiaryEntry entry;
  final String imagePath;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = entry.location;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: EntryImage(path: imagePath),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              entry.caption.isEmpty ? 'Untitled' : entry.caption,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Saved: ${formatTimestamp(entry.createdAt, withSeconds: true)}',
            ),
            if (location == null)
              const Text('Location unavailable')
            else ...[
              Text(
                formatCoordinates(
                  location.latitude,
                  location.longitude,
                  fractionDigits: 6,
                ),
              ),
              Text('Accuracy: ${formatAccuracy(location.accuracy)}'),
              Text('Altitude: ${formatAltitude(location.altitude)}'),
              Text(
                'GPS time: '
                '${formatTimestamp(location.timestamp, withSeconds: true)}',
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete entry'),
            ),
          ],
        ),
      ),
    );
  }
}
