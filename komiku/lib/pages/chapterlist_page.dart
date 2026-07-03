import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../class/comic.dart';
import 'read_page.dart';

class ChapterListPage extends StatefulWidget {
  final int comicId;

  const ChapterListPage({super.key, required this.comicId});

  @override
  State<ChapterListPage> createState() => _ChapterListPageState();
}

class _ChapterListPageState extends State<ChapterListPage> {
  Comic? _comic;
  bool _loading = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    bacaData();
  }

  Future<String> fetchData() async {
    final response = await http.post(
      Uri.parse("${baseUrl}chapter_list.php"),
      body: {'comic_id': widget.comicId.toString()},
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
        _comic = Comic.fromDetailJson(json['data']);
      } else {
        _errorMsg = json['message'] ?? 'Komik tidak ditemukan';
      }
      setState(() {
        _loading = false;
      });
    }).catchError((e) {
      setState(() {
        _loading = false;
        _errorMsg = "Gagal memuat data komik";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_comic?.title ?? 'Detail Komik')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _comic == null
              ? Center(child: Text(_errorMsg))
              : RefreshIndicator(
                  onRefresh: () async => bacaData(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _comic!.poster.isNotEmpty
                                ? Image.network(
                                    "$baseUrl${_comic!.poster}",
                                    width: 110,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      width: 110,
                                      height: 150,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  )
                                : Container(
                                    width: 110,
                                    height: 150,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_comic!.title,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                if (_comic!.author != null)
                                  Text('oleh ${_comic!.author}',
                                      style: TextStyle(color: Colors.grey[600])),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 18, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(_comic!.avgRating > 0
                                        ? '${_comic!.avgRating.toStringAsFixed(1)} (${_comic!.ratingCount} rating)'
                                        : 'Belum ada rating'),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Chip(
                                  label: Text(_comic!.status == 'completed'
                                      ? 'Tamat'
                                      : 'Ongoing'),
                                  visualDensity: VisualDensity.compact,
                                ),
                                if (_comic!.categories != null && _comic!.categories!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Wrap(
                                      spacing: 6,
                                      children: _comic!.categories!
                                          .map((c) => Chip(
                                                label: Text(c['name'].toString()),
                                                visualDensity: VisualDensity.compact,
                                              ))
                                          .toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_comic!.synopsis != null && _comic!.synopsis!.isNotEmpty) ...[
                        const Text('Sinopsis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(_comic!.synopsis!),
                        const SizedBox(height: 20),
                      ],
                      const Text('Daftar Chapter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      if (_comic!.chapters == null || _comic!.chapters!.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('Belum ada chapter')),
                        )
                      else
                        ..._comic!.chapters!.map((ch) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.menu_book),
                                title: Text('Chapter ${ch.chapterNumber}'
                                    '${ch.title != null && ch.title!.isNotEmpty ? ' - ${ch.title}' : ''}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReadPage(
                                        chapterId: ch.id,
                                        comicId: widget.comicId,
                                        comicTitle: _comic!.title,
                                        chapterNumber: ch.chapterNumber,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }
}
