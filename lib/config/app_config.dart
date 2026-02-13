import 'package:http/http.dart' as http;

class AppConfig {
  static const String localIp = '192.168.1.2'; // Your server's local IP
  static const String globalIp = 'elwanda-suberect-isabela.ngrok-free.dev';

  static String _activeIp = globalIp;
  static bool _useSSL = true;
  static int _activePort = 443;

  static const String bucket = 'movies';

  static String get minioIp => _activeIp;
  static int get minioPort => _activePort;
  static bool get useSSL => _useSSL;

  static String get minioEndpoint => _activeIp;

  static String get baseUrl {
    final scheme = _useSSL ? 'https' : 'http';
    final portPart = (_activePort == 80 || _activePort == 443)
        ? ''
        : ':$_activePort';
    return '$scheme://$_activeIp$portPart';
  }

  /// Checks if the local server is reachable.
  /// If reachable, use local IP for better speed.
  /// Otherwise, fallback to Ngrok for global access.
  static Future<void> checkConnection() async {
    print("--- Connection Check Started ---");
    try {
      final localUrl = 'http://$localIp:9000/minio/health/live';
      print("Testing Local: $localUrl");

      final response = await http
          .get(Uri.parse(localUrl))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        _activeIp = localIp;
        _activePort = 9000;
        _useSSL = false;
        print("RESULT: Local Connection SUCCESS. IP: $_activeIp");
      } else {
        _useSSL = true;
        _activeIp = globalIp;
        _activePort = 443;
        print(
          "RESULT: Local Connection FAILED (Status ${response.statusCode}). Using Global: $_activeIp",
        );
      }
    } catch (e) {
      _useSSL = true;
      _activeIp = globalIp;
      _activePort = 443;
      print("RESULT: Local Connection ERROR ($e). Using Global: $_activeIp");
    }
    print("--- Connection Check Finished ---");
  }
}
