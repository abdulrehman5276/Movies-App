import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../services/media_provider.dart';

class VideoScreen extends StatefulWidget {
  final String mediaId;
  final String videoUrl;
  final String title;
  final Map<String, String>? httpHeaders; // Added for Cloud Storage Auth

  const VideoScreen({
    super.key,
    required this.mediaId,
    required this.videoUrl,
    required this.title,
    this.httpHeaders,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;
  bool _isFullScreen = false;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();

    // Add to watched history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MediaProvider>(
        context,
        listen: false,
      ).addToWatched(widget.mediaId);
    });
  }

  void _initializeVideo() {
    String url = widget.videoUrl;

    // Redirect local/localhost for Android Emulator
    if (url.contains('127.0.0.1')) {
      url = url.replaceAll('127.0.0.1', '10.0.2.2');
    } else if (url.contains('localhost')) {
      url = url.replaceAll('localhost', '10.0.2.2');
    }

    _controller =
        VideoPlayerController.networkUrl(
            Uri.parse(url),
            httpHeaders: widget.httpHeaders ?? {},
          )
          ..initialize()
              .then((_) {
                if (mounted) {
                  setState(() {
                    _isInitialized = true;
                    _errorMessage = null;
                  });
                  _controller.play();
                  _controller.setLooping(true);
                }
              })
              .catchError((error) {
                if (mounted) {
                  setState(() {
                    _errorMessage =
                        "Playback Error\n\nEnsure this is a direct video link.\n\n$error";
                    _isInitialized = false;
                  });
                }
              });
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullScreen
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              title: Text(widget.title),
              elevation: 0,
            ),
      body: Center(
        child: _errorMessage != null
            ? _buildErrorView()
            : _isInitialized
            ? _buildPlayerView()
            : _buildLoadingView(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.redAccent),
        SizedBox(height: 20),
        Text(
          "Streaming from cloud...",
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Colors.redAccent,
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isInitialized = false;
              });
              _initializeVideo();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Retry Connection"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerView() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, VideoPlayerValue value, child) {
              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.redAccent,
                      thumbColor: Colors.redAccent,
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: value.position.inSeconds.toDouble().clamp(
                        0,
                        value.duration.inSeconds.toDouble(),
                      ),
                      max: value.duration.inSeconds.toDouble(),
                      onChanged: (val) =>
                          _controller.seekTo(Duration(seconds: val.toInt())),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(value.position),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        _formatDuration(value.duration),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.replay_10,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => _controller.seekTo(
                  _controller.value.position - const Duration(seconds: 10),
                ),
              ),
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 60,
                ),
                onPressed: () => setState(
                  () => _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play(),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.forward_10,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => _controller.seekTo(
                  _controller.value.position + const Duration(seconds: 10),
                ),
              ),
              IconButton(
                icon: Icon(
                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: _toggleFullScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
