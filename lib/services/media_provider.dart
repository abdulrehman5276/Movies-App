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

  List<MediaModel> get mediaList => _mediaList;
  List<MediaModel> get favorites =>
      _mediaList.where((m) => m.isFavorite).toList();
  bool get isLoading => _isLoading;

  MediaProvider() {
    loadMedia();
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
        ),
        MediaModel(
          id: '2',
          title: "WhatsApp Video 2026-02-11.mp4",
          url:
              "http://192.168.1.2:9000/movies/WhatsApp%20Video%202026-02-11%20at%2011.49.12%20AM.mp4",
          category: 'New Release',
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
          final fileName = p.basename(Uri.parse(item.url).path);
          if (!serverFiles.contains(fileName)) {
            changed = true;
            return true;
          }
        }
        return false;
      });

      // 2. Add items that ARE on the server but NOT in our list
      for (final fileName in serverFiles) {
        final expectedUrl =
            'http://${MinioService.endpoint}:${MinioService.port}/${MinioService.bucket}/$fileName';

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
    _mediaList.add(media);
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

  Future<void> deleteMedia(MediaModel media) async {
    try {
      // 1. Delete from MinIO if it's a MinIO URL
      if (media.url.contains(MinioService.endpoint)) {
        final minioService = MinioService();
        final fileName = p.basename(Uri.parse(media.url).path);
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
      // For mobile, maybe use external storage or gallery saver
      // For this demo, we'll save to app docs and show a message
      final filePath = "${dir.path}/${media.title}";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Starting download: ${media.title}')),
      );

      await dio.download(media.url, filePath);

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
