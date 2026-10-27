import 'package:flutter/material.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';

class MemoryDetailsSheet extends StatelessWidget {
  const MemoryDetailsSheet({required this.media, super.key});

  final MediaFile media;

  @override
  Widget build(BuildContext context) {
    final latitude = media.locationLatitude;
    final longitude = media.locationLongitude;
    final hasLocation =
        latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
    final material = MaterialLocalizations.of(context);
    final date = media.createdAt.toLocal();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.lang.memoryDetailsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: context.lang.memoryDetailsCapturedAt,
              value:
                  '${material.formatFullDate(date)} · ${material.formatTimeOfDay(TimeOfDay.fromDateTime(date))}',
            ),
            if (media.sizeInBytes != null)
              _DetailRow(
                icon: Icons.data_usage,
                label: context.lang.fileSize,
                value: formatBytes(media.sizeInBytes!),
              ),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: context.lang.memoryDetailsLocation,
              value: hasLocation
                  ? '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}'
                  : media.locationStatus == 'pending'
                  ? context.lang.memoryDetailsLocationPending
                  : context.lang.memoryDetailsNoLocation,
            ),
            if (hasLocation)
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: TextButton.icon(
                  icon: const Icon(Icons.map_outlined),
                  label: Text(context.lang.memoryDetailsOpenMap),
                  onPressed: () => Navigator.pop(context, media),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              SelectableText(value),
            ],
          ),
        ),
      ],
    ),
  );
}
