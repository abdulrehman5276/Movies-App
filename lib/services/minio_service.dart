import 'package:minio_new/minio.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:typed_data';

class MinioService {
  // CONFIGURATION: Update these with your MinIO server details
  static const String endpoint = '192.168.1.2';
  static const int port = 9000;
  static const String accessKey = 'minioadmin';
  static const String secretKey = 'minioadmin';
  static const String bucket = 'movies';

  late Minio _minio;

  MinioService() {
    _minio = Minio(
      endPoint: endpoint,
      port: port,
      useSSL: false,
      accessKey: accessKey,
      secretKey: secretKey,
    );
  }

  Future<String> uploadVideo(
    File file, {
    void Function(double)? onProgress,
  }) async {
    final String fileName = p.basename(file.path);
    final int fileSize = await file.length();

    // 1. Ensure bucket exists
    bool exists = await _minio.bucketExists(bucket);
    if (!exists) {
      await _minio.makeBucket(bucket);
    }

    // 2. Upload file
    final stream = file.openRead().cast<Uint8List>();
    await _minio.putObject(
      bucket,
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
    return 'http://$endpoint:$port/$bucket/$encodedFileName';
  }

  Future<void> deleteMedia(String fileName) async {
    await _minio.removeObject(bucket, fileName);
  }

  Future<bool> checkIfFileExists(String fileName) async {
    try {
      await _minio.statObject(bucket, fileName);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> listAllFiles() async {
    final List<String> files = [];
    final objectsStream = _minio.listObjects(bucket);
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
