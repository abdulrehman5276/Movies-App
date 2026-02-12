class MediaModel {
  final String id;
  final String title;
  final String url;
  final String? description;
  final String? category;
  bool isFavorite;

  MediaModel({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    this.category,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'description': description,
      'category': category,
      'isFavorite': isFavorite,
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
    );
  }
}
