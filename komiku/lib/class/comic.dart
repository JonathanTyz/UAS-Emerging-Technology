import 'chapter.dart';

class Comic {
  int id;
  String title;
  String slug;
  String poster;
  String status;
  String? synopsis;
  String? author;
  double avgRating;
  int ratingCount;
  List<Chapter>? chapters;
  List<Map<String, dynamic>>? categories;

  Comic({
    required this.id,
    required this.title,
    required this.slug,
    required this.poster,
    required this.status,
    this.synopsis,
    this.author,
    this.avgRating = 0,
    this.ratingCount = 0,
    this.chapters,
    this.categories,
  });

  // dipakai untuk item di comic_list.php / comic_search.php (tanpa chapters)
  factory Comic.fromJson(Map<String, dynamic> json) {
    return Comic(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'].toString(),
      slug: json['slug'].toString(),
      poster: json['poster'].toString(),
      status: json['status']?.toString() ?? 'ongoing',
      avgRating: json['avg_rating'] != null
          ? double.parse(json['avg_rating'].toString())
          : 0,
      ratingCount: json['rating_count'] != null
          ? int.parse(json['rating_count'].toString())
          : 0,
    );
  }

  // dipakai untuk detail dari chapter_list.php (nested chapters + categories)
  factory Comic.fromDetailJson(Map<String, dynamic> json) {
    List<Chapter> chList = [];
    if (json['chapters'] != null) {
      chList = List<Chapter>.from(
          (json['chapters'] as List).map((c) => Chapter.fromJson(c)));
    }
    List<Map<String, dynamic>> catList = [];
    if (json['categories'] != null) {
      catList = List<Map<String, dynamic>>.from(json['categories']);
    }
    return Comic(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'].toString(),
      slug: json['slug'].toString(),
      poster: json['poster'].toString(),
      status: json['status']?.toString() ?? 'ongoing',
      synopsis: json['synopsis']?.toString() ?? '',
      author: json['author']?.toString(),
      avgRating: json['avg_rating'] != null
          ? double.parse(json['avg_rating'].toString())
          : 0,
      ratingCount: json['rating_count'] != null
          ? int.parse(json['rating_count'].toString())
          : 0,
      chapters: chList,
      categories: catList,
    );
  }
}
