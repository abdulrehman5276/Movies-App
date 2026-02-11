import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:screen_brightness/screen_brightness.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen>
    with SingleTickerProviderStateMixin {
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
  bool _isInitialized = false;

  // Gesture Feedback
  String _showText = "";
  IconData? _showIcon;
  bool _isFeedbackShowing = false;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(
            Uri.parse(
              "https://dwpgnjixbmvyjaanhtlg.supabase.co/storage/v1/object/sign/Movies/WhatsApp%20Video%202026-02-11%20at%2011.49.12%20AM.mp4?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9mYmIwNjVjMy0xOWZjLTQ1MmMtYTgwYS0yZTk5ZGJkMGVlYjEiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJNb3ZpZXMvV2hhdHNBcHAgVmlkZW8gMjAyNi0wMi0xMSBhdCAxMS40OS4xMiBBTS5tcDQiLCJpYXQiOjE3NzA3OTY0MDYsImV4cCI6MTgwMjMzMjQwNn0.qFlZTWbA02AgUEpE_MSSwWDzQ7NHWHgQgDZXxD1KAAA",
            ),
          )
          ..initialize().then((_) {
            setState(() {
              _isInitialized = true;
            });
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
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) _startHideTimer();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (_isLocked) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _playbackSpeed = 2.0;
      _controller.setPlaybackSpeed(2.0);
      _showFeedback("2x Speed", Icons.speed_rounded);
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
    HapticFeedback.lightImpact();
    final newPos = _controller.value.position + offset;
    _controller.seekTo(newPos);
    _showFeedback(
      "${offset.inSeconds > 0 ? '+' : ''}${offset.inSeconds}s",
      offset.inSeconds > 0
          ? Icons.fast_forward_rounded
          : Icons.fast_rewind_rounded,
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

          if (details.scale != 1.0) {
            setState(() {
              _scale = (_baseScale * details.scale).clamp(1.0, 3.0);
            });
            return;
          }

          final delta = details.focalPointDelta;
          if (delta.dx.abs() > delta.dy.abs()) {
            final offset = Duration(seconds: (delta.dx / 5).toInt());
            final newPos = _controller.value.position + offset;
            _controller.seekTo(newPos);
            _showFeedback(
              _formatDuration(newPos),
              Icons.compare_arrows_rounded,
            );
          } else {
            if (details.localFocalPoint.dx > size.width / 2) {
              _volume = (_volume - delta.dy / 200).clamp(0.0, 1.0);
              _controller.setVolume(_volume);
              _showFeedback(
                "${(_volume * 100).toInt()}%",
                Icons.volume_up_rounded,
              );
            } else {
              _brightness = (_brightness - delta.dy / 200).clamp(0.0, 1.0);
              await ScreenBrightness().setScreenBrightness(_brightness);
              _showFeedback(
                "${(_brightness * 100).toInt()}%",
                Icons.brightness_6_rounded,
              );
            }
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Smooth Video Background
            AnimatedOpacity(
              opacity: _isInitialized ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeIn,
              child: Transform.scale(
                scale: _scale,
                child: Center(
                  child: _controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : const CircularProgressIndicator(
                          color: Colors.blueAccent,
                        ),
                ),
              ),
            ),

            // Entrance Loading Shimmer/Animation if not initialized
            if (!_isInitialized)
              const Center(
                child: Hero(
                  tag: 'video_loader',
                  child: CircularProgressIndicator(
                    color: Colors.blueAccent,
                    strokeWidth: 2,
                  ),
                ),
              ),

            // Smooth Gesture Overlay Feedback
            AnimatedOpacity(
              opacity: _isFeedbackShowing ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedScale(
                scale: _isFeedbackShowing ? 1.0 : 0.8,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      color: Colors.white.withValues(alpha: 0.1),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_showIcon, color: Colors.blueAccent, size: 50),
                          const SizedBox(height: 12),
                          Text(
                            _showText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Smooth Lock Indicator
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutBack,
              left: _showControls || _isLocked ? 20 : -60,
              child: _isLocked
                  ? _buildGlassButton(
                      icon: Icons.lock_rounded,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _isLocked = false);
                      },
                      isBig: true,
                    )
                  : const SizedBox.shrink(),
            ),

            // Main Controls Layer
            AnimatedOpacity(
              opacity: _showControls && !_isLocked ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: IgnorePointer(
                ignoring: !_showControls || _isLocked,
                child: Stack(
                  children: [
                    _buildTopBar(),
                    _buildCenterControls(),
                    _buildBottomBar(size),
                    _buildLockTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isBig = false,
    Color? color,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: IconButton(
            iconSize: isBig ? 32 : 24,
            icon: Icon(icon, color: color ?? Colors.white),
            onPressed: () {
              HapticFeedback.selectionClick();
              onPressed();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLockTab() {
    return Positioned(
      left: 20,
      top: MediaQuery.of(context).size.height / 2 - 25,
      child: _buildGlassButton(
        icon: Icons.lock_open_rounded,
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
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      top: _showControls ? 40 : -100,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                _buildGlassButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Now Playing",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                _buildGlassButton(
                  icon: _isFullScreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  onPressed: _toggleFullScreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Center(
      child: AnimatedScale(
        scale: _showControls ? 1.0 : 0.8,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGlassButton(
                icon: Icons.skip_previous_rounded,
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              _buildGlassButton(
                icon: Icons.replay_10_rounded,
                onPressed: () => _skip(const Duration(seconds: -10)),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                  _startHideTimer();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.3),
                        blurRadius: _controller.value.isPlaying ? 20 : 10,
                        spreadRadius: _controller.value.isPlaying ? 5 : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _buildGlassButton(
                icon: Icons.forward_10_rounded,
                onPressed: () => _skip(const Duration(seconds: 10)),
              ),
              const SizedBox(width: 12),
              _buildGlassButton(
                icon: Icons.skip_next_rounded,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(Size size) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      bottom: _showControls ? 30 : -200,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      _volume == 0
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          activeTrackColor: Colors.blueAccent,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.blueAccent,
                        ),
                        child: Slider(
                          value: _volume,
                          onChanged: (v) {
                            setState(() {
                              _volume = v;
                              _controller.setVolume(v);
                            });
                          },
                        ),
                      ),
                    ),
                    _buildGlassButton(
                      icon: Icons.speed_rounded,
                      onPressed: _cycleSpeed,
                    ),
                    const SizedBox(width: 8),
                    _buildGlassButton(
                      icon: Icons.stop_rounded,
                      onPressed: () {
                        _controller.pause();
                        _controller.seekTo(Duration.zero);
                      },
                      color: Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_controller.value.position),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDuration(_controller.value.duration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
          ),
        ),
      ),
    );
  }

  void _cycleSpeed() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else if (_playbackSpeed == 2.0) {
        _playbackSpeed = 0.5;
      } else {
        _playbackSpeed = 1.0;
      }
      _controller.setPlaybackSpeed(_playbackSpeed);
      _showFeedback("${_playbackSpeed}x", Icons.speed_rounded);
    });
  }

  void _toggleFullScreen() {
    HapticFeedback.mediumImpact();
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
