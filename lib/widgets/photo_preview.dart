import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Live preview of the photo that was just taken or picked, in a rounded
/// container. Shows a camera placeholder until there is a photo.
class PhotoPreview extends StatelessWidget {
  const PhotoPreview({super.key, required this.photo, this.onTap});

  final XFile? photo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = this.photo;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: scheme.surfaceContainerHighest,
          child: InkWell(
            onTap: onTap,
            child: photo == null
                ? _Placeholder(color: scheme.onSurfaceVariant)
                : _image(photo, scheme),
          ),
        ),
      ),
    );
  }

  Widget _image(XFile photo, ColorScheme scheme) {
    Widget broken(BuildContext context, Object error, StackTrace? stack) =>
        Center(child: Icon(Icons.broken_image_outlined, color: scheme.outline));
    // dart:io File does not exist in the browser; there the picker returns a
    // blob: URL instead of a file path.
    if (kIsWeb) {
      return Image.network(
        photo.path,
        key: const ValueKey('photo-preview-image'),
        fit: BoxFit.cover,
        errorBuilder: broken,
      );
    }
    return Image.file(
      File(photo.path),
      key: const ValueKey('photo-preview-image'),
      fit: BoxFit.cover,
      errorBuilder: broken,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, size: 64, color: color),
        const SizedBox(height: 8),
        Text(
          'No photo yet',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          'Take one with the camera or pick from the gallery',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
