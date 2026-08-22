import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CachedNetworkImage extends StatefulWidget {
  const CachedNetworkImage({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  @override
  State<CachedNetworkImage> createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<CachedNetworkImage> {
  File? _imageFile;
  bool _isLoading = true;
  dynamic _error;
  static bool _hasCleanedUp = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cacheDir = await getTemporaryDirectory();
      final urlHash = md5.convert(utf8.encode(widget.imageUrl)).toString();
      final file = File('${cacheDir.path}/custom_cached_image_$urlHash');

      if (!_hasCleanedUp) {
        _hasCleanedUp = true;
        unawaited(_cleanupOldFiles(cacheDir)); // Run asynchronously
      }

      if (file.existsSync()) {
        if (mounted) {
          setState(() {
            _imageFile = file;
            _isLoading = false;
          });
        }
        return;
      }

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(widget.imageUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        await response.pipe(file.openWrite());
        if (mounted) {
          setState(() {
            _imageFile = file;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cleanupOldFiles(Directory cacheDir) async {
    try {
      final files = cacheDir.listSync();
      final now = DateTime.now();
      for (final f in files) {
        if (f is File && f.path.contains('custom_cached_image_')) {
          final stat = f.statSync();
          if (now.difference(stat.modified).inDays >= 7) {
            await f.delete();
          }
        }
      }
    } catch (_) {
      // Ignore cleanup errors
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      if (widget.placeholder != null) {
        return widget.placeholder!(context, widget.imageUrl);
      }
      return SizedBox(width: widget.width, height: widget.height);
    }

    if (_error != null || _imageFile == null) {
      if (widget.errorWidget != null) {
        return widget.errorWidget!(context, widget.imageUrl, _error);
      }
      return SizedBox(width: widget.width, height: widget.height);
    }

    return Image.file(
      _imageFile!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        if (widget.errorWidget != null) {
          return widget.errorWidget!(context, widget.imageUrl, error);
        }
        return SizedBox(width: widget.width, height: widget.height);
      },
    );
  }
}
