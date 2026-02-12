class MediaModel {
  final String id;
  final String title;
  final String url;
  final String? description;
  final String? category;
  bool isFavorite;
  bool isDownloaded;
  final DateTime? createdAt;

  MediaModel({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    this.category,
    this.isFavorite = false,
    this.isDownloaded = false,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'description': description,
      'category': category,
      'isFavorite': isFavorite,
      'isDownloaded': isDownloaded,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'],
      title: json['title'],
      url: json['url'],
      description: json['description'],
      category: json['category'],
      isFavorite: json['isFavorite'] ?? false,
      isDownloaded: json['isDownloaded'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
