import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../class/comic.dart';
import 'chapterlist_page.dart';

class ComicListPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const ComicListPage({super.key, required this.categoryId, required this.categoryName});

  @override
  State<ComicListPage> createState() => _ComicListPageState();
}

class _ComicListPageState extends State<ComicListPage> {
  List<Comic> _comics = [];
  bool _loading = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    bacaData();
  }

  Future<String> fetchData() async {
    final response = await http.post(
      Uri.parse("${baseUrl}comic_list.php"),
      body: {'category_id': widget.categoryId.toString()},
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to read API');
    }
  }

  void bacaData() {
    setState(() {
      _loading = true;
      _errorMsg = "";
    });
    fetchData().then((value) {
      Map json = jsonDecode(value);
      if (json['result'] == 'success') {
        _comics = List<Comic>.from(
            (json['data'] as List).map((c) => Comic.fromJson(c)));
      } else {
        _comics = [];
        _errorMsg = json['message'] ?? 'Belum ada komik';
      }
      setState(() {
        _loading = false;
      });
    }).catchError((e) {
      setState(() {
        _loading = false;
        _errorMsg = "Gagal memuat daftar komik";
      });
    });
  }

  Widget _ratingBadge(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, size: 16, color: Colors.amber),
        const SizedBox(width: 2),
        Text(rating > 0 ? rating.toStringAsFixed(1) : '-',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: RefreshIndicator(
        onRefresh: () async => bacaData(),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _comics.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text(_errorMsg)),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: _comics.length,
                    itemBuilder: (BuildContext ctxt, int index) {
                      final comic = _comics[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChapterListPage(
                                  comicId: comic.id,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: comic.poster.isNotEmpty
                                    ? Image.network(
                                        "$baseUrl${comic.poster}",
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image_not_supported),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comic.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    _ratingBadge(comic.avgRating),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
