import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;

  const VideoThumbnailWidget({super.key, required this.videoUrl});

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  String? _thumbnailPath;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _generateThumbnail();
    }
  }

  Future<void> _generateThumbnail() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      String url = widget.videoUrl;
      // Android emulator redirect
      if (url.contains('127.0.0.1')) {
        url = url.replaceAll('127.0.0.1', '10.0.2.2');
      } else if (url.contains('localhost')) {
        url = url.replaceAll('localhost', '10.0.2.2');
      }

      // Create a unique filename based on the URL
      final hash = md5.convert(utf8.encode(url)).toString();
      final tempDir = await getTemporaryDirectory();
      final thumbnailFile = File(p.join(tempDir.path, 'thumb_$hash.jpg'));

      // Check if already cached
      if (await thumbnailFile.exists()) {
        if (mounted) {
          setState(() {
            _thumbnailPath = thumbnailFile.path;
            _isLoading = false;
          });
        }
        return;
      }

      // Generate thumbnail
      // Note: video_thumbnail might struggle with Ngrok without headers,
      // but usually it can grab the first frame if it's a direct mp4 link.
      final path = await VideoThumbnail.thumbnailFile(
        video: url,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300, // Reduced size for faster loading
        quality: 50, // Reduced quality for faster loading
      );

      if (path != null && mounted) {
        // Rename or move to our hashed filename for better caching
        final generatedFile = File(path);
        await generatedFile.rename(thumbnailFile.path);

        setState(() {
          _thumbnailPath = thumbnailFile.path;
          _isLoading = false;
        });
      } else {
        throw Exception("Thumbnail generation failed");
      }
    } catch (e) {
      debugPrint("Thumbnail Error: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.white10,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.redAccent,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_hasError || _thumbnailPath == null) {
      return Container(
        color: Colors.black26,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white24,
            size: 40,
          ),
        ),
      );
    }

    return Image.file(
      File(_thumbnailPath!),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Center(child: Icon(Icons.error, color: Colors.white24));
      },
    );
  }
}
