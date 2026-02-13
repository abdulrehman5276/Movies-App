import 'package:minio_new/minio.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:typed_data';
import 'package:movies_app/config/app_config.dart';
import 'package:flutter/foundation.dart';

class MinioService {
  late Minio _minio;

  MinioService() {
    print(
      "Initializing MinioService with Endpoint: ${AppConfig.minioIp}, Port: ${AppConfig.minioPort}, SSL: ${AppConfig.useSSL}",
    );
    _minio = Minio(
      endPoint: AppConfig.minioIp,
      // Some proxies like Ngrok work better when port is omitted for standard 443
      port: (AppConfig.minioPort == 443 || AppConfig.minioPort == 80)
          ? null
          : AppConfig.minioPort,
      useSSL: AppConfig.useSSL,
      accessKey: 'minioadmin',
      secretKey: 'minioadmin',
      region: 'us-east-1',
    );
  }

  static bool _bucketVerified = false;

  Future<String> uploadVideo(
    File file, {
    void Function(double)? onProgress,
  }) async {
    final String fileName = p.basename(file.path);
    final int fileSize = await file.length();

    debugPrint("MinioService: Uploading $fileName ($fileSize bytes)");

    try {
      // 1. Optimized Bucket check: only check once per app session or until success
      if (!_bucketVerified) {
        debugPrint("Verifying bucket: ${AppConfig.bucket}");
        bool exists = await _minio.bucketExists(AppConfig.bucket);
        if (!exists) {
          await _minio.makeBucket(AppConfig.bucket);
        }
        _bucketVerified = true;
      }

      // 2. Upload file using optimized stream handling
      final stream = file.openRead();

      await _minio.putObject(
        AppConfig.bucket,
        fileName,
        stream.cast<Uint8List>(),
        size: fileSize,
        onProgress: (bytes) {
          if (onProgress != null) {
            onProgress(bytes / fileSize);
          }
        },
      );

      debugPrint("Upload complete: $fileName");
      final encodedFileName = Uri.encodeComponent(fileName);
      return '${AppConfig.baseUrl}/${AppConfig.bucket}/$encodedFileName';
    } catch (e) {
      debugPrint("UPLOAD ERROR for $fileName: $e");
      // If bucket check failed, we might want to retry it next time
      if (e.toString().contains('Bucket')) {
        _bucketVerified = false;
      }
      rethrow;
    }
  }

  Future<void> deleteMedia(String fileName) async {
    try {
      print("MinioService: Deleting $fileName from ${AppConfig.bucket}");
      await _minio.removeObject(AppConfig.bucket, fileName);
      print("MinioService: Deleted successfully");
    } catch (e, stack) {
      print("FATAL DELETE ERROR: $e");
      print(stack);
      rethrow;
    }
  }

  Future<bool> checkIfFileExists(String fileName) async {
    try {
      await _minio.statObject(AppConfig.bucket, fileName);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listAllFilesWithMetadata() async {
    final List<Map<String, dynamic>> files = [];
    try {
      final objectsStream = _minio.listObjects(AppConfig.bucket);
      await for (var result in objectsStream) {
        for (var obj in result.objects) {
          if (obj.key != null) {
            files.add({'name': obj.key!, 'lastModified': obj.lastModified});
          }
        }
      }
    } catch (e) {
      print("Error listing files: $e");
    }
    return files;
  }
}
