import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_model.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'minio_service.dart';
import 'package:path/path.dart' as p;

class MediaProvider with ChangeNotifier {
  List<MediaModel> _mediaList = [];
  bool _isLoading = true;
  Set<String> _watchedIds = {};

  List<MediaModel> get mediaList {
    final sortedList = List<MediaModel>.from(_mediaList);
    sortedList.sort((a, b) {
      final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA); // Newest first
    });
    return sortedList;
  }

  List<MediaModel> get favorites =>
      mediaList.where((m) => m.isFavorite).toList();

  List<MediaModel> get downloads =>
      mediaList.where((m) => m.isDownloaded).toList();

  int get watchedCount => _watchedIds.length;
  bool get isLoading => _isLoading;

  MediaProvider() {
    loadMedia();
  }

  Future<void> addToWatched(String id) async {
    if (!_watchedIds.contains(id)) {
      _watchedIds.add(id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('watched_ids', _watchedIds.toList());
      notifyListeners();
    }
  }

  Future<void> refreshMedia() async {
    await Future.wait([
      loadMedia(showLoading: false),
      Future.delayed(const Duration(milliseconds: 800)),
    ]);
  }

  Future<void> loadMedia({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    final prefs = await SharedPreferences.getInstance();

    // Load Watched IDs
    final watched = prefs.getStringList('watched_ids');
    if (watched != null) {
      _watchedIds = watched.toSet();
    }

    final String? mediaData = prefs.getString('media_list');
    if (mediaData != null) {
      final List<dynamic> decoded = jsonDecode(mediaData);
      _mediaList = decoded.map((m) => MediaModel.fromJson(m)).toList();
    } else {
      // Default data
      _mediaList = [
        MediaModel(
          id: '1',
          title: "Movie.mp4",
          url: "http://192.168.1.2:9000/movies/Movie.mp4",
          category: 'Trending',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        MediaModel(
          id: '2',
          title: "WhatsApp Video 2026-02-11.mp4",
          url:
              "http://192.168.1.2:9000/movies/WhatsApp%20Video%202026-02-11%20at%2011.49.12%20AM.mp4",
          category: 'New Release',
          createdAt: DateTime.now(),
        ),
      ];
      await saveMedia();
    }

    _isLoading = false;
    notifyListeners();

    // Auto-sync with server after initial load
    await syncWithServer();
  }

  Future<void> syncWithServer() async {
    final minioService = MinioService();
    try {
      final serverFiles = await minioService.listAllFiles();
      bool changed = false;

      // 1. Remove items that are NOT on the server anymore
      _mediaList.removeWhere((item) {
        if (item.url.contains(MinioService.endpoint)) {
          final uri = Uri.parse(item.url);
          final fileName = Uri.decodeComponent(p.basename(uri.path));
          if (!serverFiles.contains(fileName)) {
            changed = true;
            return true;
          }
        }
        return false;
      });

      // 2. Add items that ARE on the server but NOT in our list
      for (final fileName in serverFiles) {
        final encodedName = Uri.encodeComponent(fileName);
        final expectedUrl =
            'http://${MinioService.endpoint}:${MinioService.port}/${MinioService.bucket}/$encodedName';

        // Check if this URL (or a decoded version of it) is already in our list
        bool alreadyExists = _mediaList.any(
          (m) =>
              m.url == expectedUrl ||
              Uri.decodeFull(m.url) == Uri.decodeFull(expectedUrl),
        );

        if (!alreadyExists) {
          // Detect category
          String category = 'Media';
          final ext = p.extension(fileName).toLowerCase();
          if (['.mp3', '.wav', '.m4a'].contains(ext)) {
            category = 'Songs';
          } else if (['.mp4', '.mov', '.mkv'].contains(ext)) {
            category = 'Movies';
          }

          _mediaList.add(
            MediaModel(
              id: DateTime.now().millisecondsSinceEpoch.toString() + fileName,
              title: p.basenameWithoutExtension(fileName),
              url: expectedUrl,
              category: category,
              createdAt: DateTime.now(),
            ),
          );
          changed = true;
        }
      }

      if (changed) {
        await saveMedia();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  Future<void> saveMedia() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _mediaList.map((m) => m.toJson()).toList(),
    );
    await prefs.setString('media_list', encoded);
  }

  Future<void> addMedia(MediaModel media) async {
    // Add new media with current timestamp
    final newMedia = MediaModel(
      id: media.id,
      title: media.title,
      url: media.url,
      description: media.description,
      category: media.category,
      isFavorite: media.isFavorite,
      isDownloaded: media.isDownloaded,
      createdAt: DateTime.now(),
    );
    _mediaList.add(newMedia);
    await saveMedia();
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _mediaList.indexWhere((m) => m.id == id);
    if (index != -1) {
      _mediaList[index].isFavorite = !_mediaList[index].isFavorite;
      await saveMedia();
      notifyListeners();
    }
  }

  Future<void> toggleDownloaded(String id, {bool? forceValue}) async {
    final index = _mediaList.indexWhere((m) => m.id == id);
    if (index != -1) {
      _mediaList[index].isDownloaded =
          forceValue ?? !_mediaList[index].isDownloaded;
      await saveMedia();
      notifyListeners();
    }
  }

  Future<void> deleteMedia(MediaModel media) async {
    try {
      // 1. Delete from MinIO if it's a MinIO URL
      if (media.url.contains(MinioService.endpoint)) {
        final minioService = MinioService();
        final uri = Uri.parse(media.url);
        final fileName = Uri.decodeComponent(p.basename(uri.path));
        await minioService.deleteMedia(fileName);
      }

      // 2. Remove from local list
      _mediaList.removeWhere((m) => m.id == media.id);
      await saveMedia();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> downloadMedia(MediaModel media, BuildContext context) async {
    try {
      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/${media.title}";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Starting download: ${media.title}')),
      );

      await dio.download(media.url, filePath);

      // Update downloaded status
      await toggleDownloaded(media.id, forceValue: true);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Downloaded to $filePath')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }
}
