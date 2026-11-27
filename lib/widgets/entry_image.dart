import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shows a saved diary photo from wherever it lives on this platform:
/// a file on Android/iOS, a `data:` URL (or blob URL) on the web.
class EntryImage extends StatefulWidget {
  const EntryImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  final String path;
  final BoxFit fit;

  /// Decode at this width to keep thumbnails cheap.
  final int? cacheWidth;

  @override
  State<EntryImage> createState() => _EntryImageState();
}

class _EntryImageState extends State<EntryImage> {
  Uint8List? _dataBytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(EntryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _decode();
  }

  void _decode() {
    _dataBytes = null;
    if (widget.path.startsWith('data:')) {
      try {
        _dataBytes = UriData.parse(widget.path).contentAsBytes();
      } catch (_) {
        _dataBytes = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _dataBytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: widget.fit,
        cacheWidth: widget.cacheWidth,
        errorBuilder: _broken,
      );
    }
    if (kIsWeb) {
      return Image.network(
        widget.path,
        fit: widget.fit,
        cacheWidth: widget.cacheWidth,
        errorBuilder: _broken,
      );
    }
    return Image.file(
      File(widget.path),
      fit: widget.fit,
      cacheWidth: widget.cacheWidth,
      errorBuilder: _broken,
    );
  }

  Widget _broken(BuildContext context, Object error, StackTrace? stack) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: scheme.outline),
      ),
    );
  }
}
