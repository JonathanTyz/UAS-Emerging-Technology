import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../class/chapter.dart';
import '../class/comment.dart';

class ReadPage extends StatefulWidget {
  final int chapterId;
  final int comicId;
  final String comicTitle;
  final int chapterNumber;

  const ReadPage({
    super.key,
    required this.chapterId,
    required this.comicId,
    required this.comicTitle,
    required this.chapterNumber,
  });

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  Chapter? _chapter;
  bool _loading = true;
  String _errorMsg = "";

  List<Comment> _comments = [];
  bool _loadingComments = true;

  final _commentController = TextEditingController();
  int _myRating = 0;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
    bacaChapter();
    bacaComments();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
  }

  Future<String> fetchChapter() async {
    final response = await http.post(
      Uri.parse("${baseUrl}chapter_detail.php"),
      body: {'chapter_id': widget.chapterId.toString()},
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to read API');
    }
  }

  void bacaChapter() {
    setState(() {
      _loading = true;
      _errorMsg = "";
    });
    fetchChapter().then((value) {
      Map json = jsonDecode(value);
      if (json['result'] == 'success') {
        _chapter = Chapter.fromDetailJson(json['data']);
      } else {
        _errorMsg = json['message'] ?? 'Chapter tidak ditemukan';
      }
      setState(() => _loading = false);
    }).catchError((e) {
      setState(() {
        _loading = false;
        _errorMsg = "Gagal memuat halaman komik";
      });
    });
  }

  Future<String> fetchComments() async {
    final response = await http.post(
      Uri.parse("${baseUrl}comment_list.php"),
      body: {'comic_id': widget.comicId.toString()},
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to read API');
    }
  }

  void bacaComments() {
    setState(() => _loadingComments = true);
    fetchComments().then((value) {
      Map json = jsonDecode(value);
      if (json['result'] == 'success') {
        _comments = List<Comment>.from(
            (json['data'] as List).map((c) => Comment.fromJson(c)));
      }
      setState(() => _loadingComments = false);
    }).catchError((e) {
      setState(() => _loadingComments = false);
    });
  }

  void _submitComment() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login terlebih dahulu')));
      return;
    }
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final response = await http.post(
      Uri.parse("${baseUrl}add_comment.php"),
      body: {
        'comic_id': widget.comicId.toString(),
        'user_id': _userId!,
        'content': text,
      },
    );
    if (response.statusCode == 200) {
      Map json = jsonDecode(response.body);
      if (json['result'] == 'success') {
        _commentController.clear();
        if (!mounted) return;
        FocusScope.of(context).unfocus();
        bacaComments();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Gagal mengirim komentar')));
      }
    }
  }

  void _submitRating(int rating) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login terlebih dahulu')));
      return;
    }
    setState(() => _myRating = rating);
    final response = await http.post(
      Uri.parse("${baseUrl}add_rating.php"),
      body: {
        'comic_id': widget.comicId.toString(),
        'user_id': _userId!,
        'rating': rating.toString(),
      },
    );
    if (response.statusCode == 200) {
      Map json = jsonDecode(response.body);
      if (json['result'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Terima kasih atas rating-nya!')));
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.comicTitle} - Ch. ${widget.chapterNumber}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_chapter == null || _chapter!.pages == null || _chapter!.pages!.isEmpty)
              ? Center(child: Text(_errorMsg.isNotEmpty ? _errorMsg : 'Belum ada halaman'))
              : ListView(
                  children: [
                    // gambar-gambar halaman komik, scroll vertikal
                    ..._chapter!.pages!.map((p) => Image.network(
                          "$baseUrl${p.image}",
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          errorBuilder: (c, e, s) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image),
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 300,
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(),
                            );
                          },
                        )),
                    const Divider(thickness: 6),

                    // Beri rating
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Beri Rating',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (index) {
                              final starIndex = index + 1;
                              return IconButton(
                                icon: Icon(
                                  starIndex <= _myRating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 32,
                                ),
                                onPressed: () => _submitRating(starIndex),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    // Komentar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Komentar',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _commentController,
                                  decoration: const InputDecoration(
                                    hintText: 'Tulis komentar...',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send, color: Colors.deepOrange),
                                onPressed: _submitComment,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _loadingComments
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              : _comments.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Text('Belum ada komentar'),
                                    )
                                  : Column(
                                      children: _comments
                                          .map((cm) => ListTile(
                                                leading: const CircleAvatar(child: Icon(Icons.person)),
                                                title: Text(cm.username,
                                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                                subtitle: Text(cm.content),
                                              ))
                                          .toList(),
                                    ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
