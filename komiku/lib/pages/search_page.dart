import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../class/comic.dart';
import 'chapterlist_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Comic> _results = [];
  bool _loading = false;
  bool _searched = false;
  String _errorMsg = "";
  String _keyword = "";

  Future<String> fetchData(String keyword) async {
    final response = await http.post(
      Uri.parse("${baseUrl}comic_search.php"),
      body: {'judul': keyword},
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to read API');
    }
  }

  void bacaData(String keyword) {
    if (keyword.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _searched = true;
      _errorMsg = "";
    });
    fetchData(keyword).then((value) {
      Map json = jsonDecode(value);
      if (json['result'] == 'success') {
        _results = List<Comic>.from(
            (json['data'] as List).map((c) => Comic.fromJson(c)));
      } else {
        _results = [];
        _errorMsg = json['message'] ?? 'Komik tidak ditemukan';
      }
      setState(() => _loading = false);
    }).catchError((e) {
      setState(() {
        _loading = false;
        _errorMsg = "Gagal mencari komik";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          autofocus: true,
          style: const TextStyle(color: Colors.black),
          decoration: const InputDecoration(
            hintText: 'Cari judul komik...',
            hintStyle: TextStyle(color: Colors.black54),
            border: InputBorder.none,
          ),
          onChanged: (value) => _keyword = value,
          onFieldSubmitted: (value) => bacaData(value),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => bacaData(_keyword),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_searched
              ? const Center(child: Text('Ketik judul komik untuk mencari'))
              : _results.isEmpty
                  ? Center(child: Text(_errorMsg))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (BuildContext ctxt, int index) {
                        final comic = _results[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: comic.poster.isNotEmpty
                                ? Image.network(
                                    "$baseUrl${comic.poster}",
                                    width: 48,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.broken_image),
                                  )
                                : Container(
                                    width: 48,
                                    height: 64,
                                    color: Colors.grey[300],
                                  ),
                          ),
                          title: Text(comic.title),
                          subtitle: Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(comic.avgRating > 0
                                  ? comic.avgRating.toStringAsFixed(1)
                                  : '-'),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChapterListPage(comicId: comic.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
