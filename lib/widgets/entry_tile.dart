import 'package:flutter/material.dart';

import '../models/diary_entry.dart';
import '../utils/formatters.dart';
import 'entry_image.dart';

/// One row of the diary feed: thumbnail, caption, coordinates, time.
class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.imagePath,
    this.onTap,
  });

  final DiaryEntry entry;

  /// `entry.photoPath` resolved for this platform.
  final String imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final location = entry.location;
    return Card.filled(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: EntryImage(path: imagePath, cacheWidth: 252),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.caption.isEmpty ? 'Untitled' : entry.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    _IconLine(
                      icon: Icons.place_outlined,
                      text: location == null
                          ? 'Location unavailable'
                          : formatCoordinates(
                              location.latitude,
                              location.longitude,
                            ),
                      style: muted,
                    ),
                    const SizedBox(height: 2),
                    _IconLine(
                      icon: Icons.schedule,
                      text: formatTimestamp(entry.createdAt),
                      style: muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text, this.style});

  final IconData icon;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: style?.color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
