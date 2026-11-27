import 'package:flutter/material.dart';

import '../models/geo_fix.dart';
import '../utils/formatters.dart';

/// GPS block of the new-entry form: "Fetch GPS" button, spinner while
/// waiting, then latitude / longitude / accuracy / altitude / time.
class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.fix,
    required this.loading,
    required this.onFetch,
    this.message,
    this.isLastKnown = false,
  });

  final GeoFix? fix;
  final bool loading;
  final VoidCallback? onFetch;

  /// Why there is no fix (denied, GPS off, timeout...).
  final String? message;
  final bool isLastKnown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fix = this.fix;
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.my_location, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Location', style: theme.textTheme.titleMedium),
                ),
                OutlinedButton.icon(
                  onPressed: loading ? null : onFetch,
                  icon: const Icon(Icons.gps_fixed, size: 18),
                  label: const Text('Fetch GPS'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Getting a high-accuracy GPS fix...'),
                  ],
                ),
              )
            else if (fix != null) ...[
              _Row(
                label: 'Latitude',
                value: formatLatitude(fix.latitude, fractionDigits: 6),
              ),
              _Row(
                label: 'Longitude',
                value: formatLongitude(fix.longitude, fractionDigits: 6),
              ),
              _Row(label: 'Accuracy', value: formatAccuracy(fix.accuracy)),
              _Row(label: 'Altitude', value: formatAltitude(fix.altitude)),
              _Row(
                label: 'Timestamp',
                value: formatTimestamp(fix.timestamp, withSeconds: true),
              ),
              if (isLastKnown)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Live fix timed out - showing the last known position.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
            ] else
              Text(
                message ??
                    'No coordinates yet. Tap Fetch GPS, or take a photo and '
                        'the location is fetched automatically.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: message == null
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
