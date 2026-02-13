import 'package:minio_new/minio.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:typed_data';
import 'package:movies_app/config/app_config.dart';

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

  Future<String> uploadVideo(
    File file, {
    void Function(double)? onProgress,
  }) async {
    final String fileName = p.basename(file.path);
    final int fileSize = await file.length();

    print("Uploading: $fileName ($fileSize bytes)");

    try {
      // 1. Ensure bucket exists
      print("Checking bucket: ${AppConfig.bucket}");
      bool exists = await _minio.bucketExists(AppConfig.bucket);
      if (!exists) {
        print("Creating bucket: ${AppConfig.bucket}");
        await _minio.makeBucket(AppConfig.bucket);
      }

      // 2. Upload file
      print("Starting PutObject...");
      final stream = file.openRead().cast<Uint8List>();
      await _minio.putObject(
        AppConfig.bucket,
        fileName,
        stream,
        size: fileSize,
        onProgress: (bytes) {
          if (onProgress != null) {
            onProgress(bytes / fileSize);
          }
        },
      );

      print("Upload complete: $fileName");
      // 3. Return the public URL
      final encodedFileName = Uri.encodeComponent(fileName);
      return '${AppConfig.baseUrl}/${AppConfig.bucket}/$encodedFileName';
    } catch (e, stack) {
      print("FATAL UPLOAD ERROR: $e");
      print(stack);
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

  Future<List<String>> listAllFiles() async {
    final List<String> files = [];
    final objectsStream = _minio.listObjects(AppConfig.bucket);
    await for (var result in objectsStream) {
      for (var obj in result.objects) {
        if (obj.key != null) {
          files.add(obj.key!);
        }
      }
    }
    return files;
  }
}
