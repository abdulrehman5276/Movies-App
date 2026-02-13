import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../models/media_model.dart';
import '../services/media_provider.dart';
import 'package:marquee/marquee.dart';

enum RepeatMode { none, all, one }

class MusicPlayerScreen extends StatefulWidget {
  final List<MediaModel> playlist;
  final int initialIndex;

  const MusicPlayerScreen({
    super.key,
    required this.playlist,
    required this.initialIndex,
  });

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // New features state
  late List<MediaModel> _playlist;
  late int _currentIndex;
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.none;

  @override
  void initState() {
    super.initState();
    _playlist = List.from(widget.playlist);
    _currentIndex = widget.initialIndex;
    _audioPlayer = AudioPlayer();
    _setupAudio();
  }

  Future<void> _setupAudio() async {
    // Set up listeners first
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted && d != Duration.zero) setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (_repeatMode == RepeatMode.one) {
        _playCurrent();
      } else {
        _next();
      }
    });

    _playCurrent();
  }

  Future<void> _playCurrent() async {
    final song = _playlist[_currentIndex];
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setSourceUrl(song.url);
      await _audioPlayer.resume();

      Future.delayed(const Duration(seconds: 1), () async {
        final d = await _audioPlayer.getDuration();
        if (mounted && d != null && d != Duration.zero) {
          setState(() => _duration = d);
        }
      });
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  void _next() {
    setState(() {
      if (_isShuffle) {
        _currentIndex = (_currentIndex + 1) % _playlist.length;
      } else {
        if (_currentIndex < _playlist.length - 1) {
          _currentIndex++;
        } else if (_repeatMode == RepeatMode.all) {
          _currentIndex = 0;
        }
      }
    });
    _playCurrent();
  }

  void _previous() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = _playlist.length - 1;
      }
    });
    _playCurrent();
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffle = !_isShuffle;
      if (_isShuffle) {
        _playlist.shuffle();
      } else {
        _playlist = List.from(widget.playlist);
        _currentIndex = _playlist.indexOf(
          widget.playlist[widget.initialIndex],
        ); // This is simplified
      }
    });
  }

  void _toggleRepeat() {
    setState(() {
      _repeatMode =
          RepeatMode.values[(_repeatMode.index + 1) % RepeatMode.values.length];
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final currentSong = _playlist[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              currentSong.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: currentSong.isFavorite ? Colors.redAccent : Colors.white,
            ),
            onPressed: () {
              context.read<MediaProvider>().toggleFavorite(currentSong.id);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Album Art
              Container(
                height: screenHeight * 0.35,
                width: screenWidth * 0.8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.redAccent.withValues(alpha: 0.5),
                      Colors.black,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 150,
                  color: Colors.white24,
                ),
              ),

              // Title and Category
              Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: Marquee(
                      key: ValueKey(currentSong.id),
                      text: currentSong.title,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      scrollAxis: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      blankSpace: 20.0,
                      velocity: 50.0,
                      pauseAfterRound: const Duration(seconds: 1),
                      accelerationDuration: const Duration(seconds: 1),
                      accelerationCurve: Curves.linear,
                      decelerationDuration: const Duration(milliseconds: 500),
                      decelerationCurve: Curves.easeOut,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentSong.category ?? 'Song',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),

              // Progress Bar
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: Colors.redAccent,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      min: 0,
                      max: _duration.inSeconds.toDouble() > 0
                          ? _duration.inSeconds.toDouble()
                          : 1.0,
                      value: _position.inSeconds.toDouble().clamp(
                        0.0,
                        _duration.inSeconds.toDouble() > 0
                            ? _duration.inSeconds.toDouble()
                            : 1.0,
                      ),
                      onChanged: (value) async {
                        await _audioPlayer.seek(
                          Duration(seconds: value.toInt()),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: _isShuffle ? Colors.redAccent : Colors.white54,
                    ),
                    onPressed: _toggleShuffle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, size: 45),
                    onPressed: _previous,
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_isPlaying) {
                        _audioPlayer.pause();
                      } else {
                        _audioPlayer.resume();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 45),
                    onPressed: _next,
                  ),
                  IconButton(
                    icon: Icon(
                      _repeatMode == RepeatMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      color: _repeatMode != RepeatMode.none
                          ? Colors.redAccent
                          : Colors.white54,
                    ),
                    onPressed: _toggleRepeat,
                  ),
                ],
              ),
              // Extra spacer for bottom bar safety
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
