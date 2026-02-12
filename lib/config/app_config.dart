class AppConfig {
  // To make it work from any internet:
  // 1. If using local MinIO, use a service like Ngrok: 'ngrok http 9000'
  // 2. Or use your public IP if you have port forwarding enabled.
  // 3. Or use a cloud storage provider.

  // Example for local network: '192.168.1.2'
  // Example for Ngrok: 'your-ngrok-id.ngrok-free.app' (remove http:// and port if using ngrok's default)

  static const String minioIp = 'elwanda-suberect-isabela.ngrok-free.dev';
  static const int minioPort = 443;
  static const bool useSSL = true;
  static const String bucket = 'movies';

  static String get minioEndpoint => minioIp;

  // Helper to get the full base URL (handles SSL and standard ports)
  static String get baseUrl {
    final scheme = useSSL ? 'https' : 'http';
    final portPart = (minioPort == 80 || minioPort == 443) ? '' : ':$minioPort';
    return '$scheme://$minioIp$portPart';
  }
}
