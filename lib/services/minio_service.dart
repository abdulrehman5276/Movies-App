import 'package:minio_new/minio.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:typed_data';
import 'package:movies_app/config/app_config.dart';

class MinioService {
  late Minio _minio;

  MinioService() {
    _minio = Minio(
      endPoint: AppConfig.minioIp,
      port: AppConfig.minioPort,
      useSSL: AppConfig.useSSL,
      accessKey: 'minioadmin',
      secretKey: 'minioadmin',
    );
  }

  Future<String> uploadVideo(
    File file, {
    void Function(double)? onProgress,
  }) async {
    final String fileName = p.basename(file.path);
    final int fileSize = await file.length();

    // 1. Ensure bucket exists
    bool exists = await _minio.bucketExists(AppConfig.bucket);
    if (!exists) {
      await _minio.makeBucket(AppConfig.bucket);
    }

    // 2. Upload file
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

    // 3. Return the public URL
    final encodedFileName = Uri.encodeComponent(fileName);
    return '${AppConfig.baseUrl}/${AppConfig.bucket}/$encodedFileName';
  }

  Future<void> deleteMedia(String fileName) async {
    await _minio.removeObject(AppConfig.bucket, fileName);
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
