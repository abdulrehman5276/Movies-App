import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:screen_brightness/screen_brightness.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _isFullScreen = false;
  bool _isLocked = false;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;
  double _brightness = 0.5;
  double _scale = 1.0;
  double _baseScale = 1.0;
  Timer? _hideTimer;

  // Gesture Feedback
  String _showText = "";
  IconData? _showIcon;
  bool _isFeedbackShowing = false;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/videos/testingvideo.mp4")
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    _initBrightness();
    _startHideTimer();
  }

  Future<void> _initBrightness() async {
    try {
      _brightness = await ScreenBrightness().current;
    } catch (e) {
      _brightness = 0.5;
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && !_isLocked) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    if (_isLocked) {
      setState(() => _showControls = !_showControls);
      _startHideTimer();
      return;
    }
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) _startHideTimer();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (_isLocked) return;
    setState(() {
      _playbackSpeed = 2.0;
      _controller.setPlaybackSpeed(2.0);
      _showFeedback("2x Speed", Icons.speed);
    });
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_isLocked) return;
    setState(() {
      _playbackSpeed = 1.0;
      _controller.setPlaybackSpeed(1.0);
      _hideFeedback();
    });
  }

  void _showFeedback(String text, IconData icon) {
    _feedbackTimer?.cancel();
    setState(() {
      _showText = text;
      _showIcon = icon;
      _isFeedbackShowing = true;
    });
    _feedbackTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isFeedbackShowing = false);
    });
  }

  void _hideFeedback() {
    setState(() => _isFeedbackShowing = false);
  }

  void _skip(Duration offset) {
    final newPos = _controller.value.position + offset;
    _controller.seekTo(newPos);
    _showFeedback(
      "${offset.inSeconds > 0 ? '+' : ''}${offset.inSeconds}s",
      offset.inSeconds > 0 ? Icons.forward_10 : Icons.replay_10,
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _feedbackTimer?.cancel();
    _controller.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onDoubleTapDown: (details) {
          if (_isLocked) return;
          if (details.localPosition.dx < size.width / 2) {
            _skip(const Duration(seconds: -10));
          } else {
            _skip(const Duration(seconds: 10));
          }
        },
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        onScaleStart: (details) {
          if (_isLocked) return;
          _baseScale = _scale;
        },
        onScaleUpdate: (details) async {
          if (_isLocked) return;

          // Pinch to Zoom (Two fingers or significantly varied scale)
          if (details.scale != 1.0) {
            setState(() {
              _scale = (_baseScale * details.scale).clamp(1.0, 3.0);
            });
            return;
          }

          // Handle Drags (Single finger)
          final delta = details.focalPointDelta;
          if (delta.dx.abs() > delta.dy.abs()) {
            // Horizontal Swipe - Seek
            final offset = Duration(seconds: (delta.dx / 5).toInt());
            final newPos = _controller.value.position + offset;
            _controller.seekTo(newPos);
            _showFeedback(_formatDuration(newPos), Icons.compare_arrows);
          } else {
            // Vertical Swipe - Volume / Brightness
            if (details.localFocalPoint.dx > size.width / 2) {
              // Volume (Right side)
              _volume = (_volume - delta.dy / 200).clamp(0.0, 1.0);
              _controller.setVolume(_volume);
              _showFeedback("${(_volume * 100).toInt()}%", Icons.volume_up);
            } else {
              // Brightness (Left side)
              _brightness = (_brightness - delta.dy / 200).clamp(0.0, 1.0);
              await ScreenBrightness().setScreenBrightness(_brightness);
              _showFeedback(
                "${(_brightness * 100).toInt()}%",
                Icons.brightness_6,
              );
            }
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video
            Transform.scale(
              scale: _scale,
              child: Center(
                child: _controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : const CircularProgressIndicator(color: Colors.blueAccent),
              ),
            ),

            // Gesture Overlay Feedback
            if (_isFeedbackShowing)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_showIcon, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      _showText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Lock Icon
            if (_showControls && _isLocked)
              Positioned(
                left: 10,
                child: IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.lock_outline, color: Colors.white),
                  onPressed: () => setState(() => _isLocked = false),
                ),
              ),

            // Main Controls
            if (_showControls && !_isLocked) ...[
              _buildTopBar(),
              _buildCenterControls(),
              _buildBottomBar(size),
              _buildLockTab(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLockTab() {
    return Positioned(
      left: 10,
      child: IconButton(
        iconSize: 32,
        icon: const Icon(Icons.lock_open_outlined, color: Colors.white70),
        onPressed: () {
          setState(() {
            _isLocked = true;
            _showControls = false;
          });
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Text(
            "Movie Player Pro",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
            onPressed: _toggleFullScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            iconSize: 32,
            icon: const Icon(Icons.skip_previous, color: Colors.white),
            onPressed: () {}, // Implement Prev
          ),
          const SizedBox(width: 8),
          IconButton(
            iconSize: 38,
            icon: const Icon(Icons.replay_10, color: Colors.white),
            onPressed: () => _skip(const Duration(seconds: -10)),
          ),
          const SizedBox(width: 12),
          IconButton(
            iconSize: 68,
            icon: Icon(
              _controller.value.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: Colors.blueAccent,
            ),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
          ),
          const SizedBox(width: 12),
          IconButton(
            iconSize: 38,
            icon: const Icon(Icons.forward_10, color: Colors.white),
            onPressed: () => _skip(const Duration(seconds: 10)),
          ),
          const SizedBox(width: 8),
          IconButton(
            iconSize: 32,
            icon: const Icon(Icons.skip_next, color: Colors.white),
            onPressed: () {}, // Implement Next
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Size size) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Column(
        children: [
          // Volume & Speed & Stop
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _volume == 0 ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _volume = _volume == 0 ? 1.0 : 0.0;
                    _controller.setVolume(_volume);
                  });
                },
              ),
              Expanded(
                child: Slider(
                  value: _volume,
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.white24,
                  onChanged: (v) {
                    setState(() {
                      _volume = v;
                      _controller.setVolume(v);
                    });
                  },
                ),
              ),
              TextButton(
                onPressed: _cycleSpeed,
                child: Text(
                  "${_playbackSpeed}x",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.redAccent),
                onPressed: () {
                  _controller.pause();
                  _controller.seekTo(Duration.zero);
                },
              ),
            ],
          ),
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_controller.value.position),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  _formatDuration(_controller.value.duration),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            colors: const VideoProgressColors(
              playedColor: Colors.blueAccent,
              bufferedColor: Colors.white24,
              backgroundColor: Colors.white10,
            ),
          ),
        ],
      ),
    );
  }

  void _cycleSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0)
        _playbackSpeed = 1.5;
      else if (_playbackSpeed == 1.5)
        _playbackSpeed = 2.0;
      else if (_playbackSpeed == 2.0)
        _playbackSpeed = 0.5;
      else
        _playbackSpeed = 1.0;
      _controller.setPlaybackSpeed(_playbackSpeed);
    });
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
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
