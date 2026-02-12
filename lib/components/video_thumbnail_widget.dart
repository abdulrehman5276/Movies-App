import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;

  const VideoThumbnailWidget({super.key, required this.videoUrl});

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller.dispose();
      _isInitialized = false;
      _hasError = false;
      _initializePreview();
    }
  }

  Future<void> _initializePreview() async {
    String url = widget.videoUrl;
    // Android emulator redirect
    if (url.contains('127.0.0.1')) {
      url = url.replaceAll('127.0.0.1', '10.0.2.2');
    } else if (url.contains('localhost')) {
      url = url.replaceAll('localhost', '10.0.2.2');
    }

    _controller = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await _controller.initialize();
      // Seek to 1 second to avoid black first frame
      await _controller.seekTo(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Thumbnail Error: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
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

    if (!_isInitialized) {
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

    return IgnorePointer(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
  }
}
