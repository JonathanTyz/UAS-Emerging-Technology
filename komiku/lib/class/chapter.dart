class Chapter {
  int id;
  int chapterNumber;
  String? title;
  List<ChapterPage>? pages;

  Chapter({
    required this.id,
    required this.chapterNumber,
    this.title,
    this.pages,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      chapterNumber: json['chapter_number'] is int
          ? json['chapter_number']
          : int.parse(json['chapter_number'].toString()),
      title: json['title']?.toString(),
    );
  }

  factory Chapter.fromDetailJson(Map<String, dynamic> json) {
    List<ChapterPage> pageList = [];
    if (json['pages'] != null) {
      pageList = List<ChapterPage>.from(
          (json['pages'] as List).map((p) => ChapterPage.fromJson(p)));
    }
    return Chapter(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      chapterNumber: json['chapter_number'] is int
          ? json['chapter_number']
          : int.parse(json['chapter_number'].toString()),
      title: json['title']?.toString(),
      pages: pageList,
    );
  }
}

class ChapterPage {
  int pageNumber;
  String image;

  ChapterPage({required this.pageNumber, required this.image});

  factory ChapterPage.fromJson(Map<String, dynamic> json) {
    return ChapterPage(
      pageNumber: json['page_number'] is int
          ? json['page_number']
          : int.parse(json['page_number'].toString()),
      image: json['image'].toString(),
    );
  }
}
