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
  final _commentFocusNode = FocusNode();
  int _myRating = 0;
  String? _userId;

  int? _replyingToId;
  String? _replyingToUsername;

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

  List<Comment> get _topLevelComments =>
      _comments.where((c) => c.parentId == null).toList();

  List<Comment> _repliesOf(int parentId) {
    final list = _comments.where((c) => c.parentId == parentId).toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  void _startReply(Comment cm) {
    if (_userId != null && cm.userId.toString() == _userId) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membalas komentar sendiri')));
      return;
    }
    setState(() {
      _replyingToId = cm.parentId ?? cm.id;
      _replyingToUsername = cm.username;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyingToUsername = null;
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

    final body = {
      'comic_id': widget.comicId.toString(),
      'user_id': _userId!,
      'content': text,
    };
    if (_replyingToId != null) {
      body['parent_id'] = _replyingToId.toString();
    }

    final response = await http.post(
      Uri.parse("${baseUrl}add_comment.php"),
      body: body,
    );
    if (response.statusCode == 200) {
      Map json = jsonDecode(response.body);
      if (json['result'] == 'success') {
        _commentController.clear();
        if (!mounted) return;
        FocusScope.of(context).unfocus();
        setState(() {
          _replyingToId = null;
          _replyingToUsername = null;
        });
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
    _commentFocusNode.dispose();
    super.dispose();
  }

  Widget _buildCommentTile(Comment cm, {bool isReply = false}) {
    final isOwnComment = _userId != null && cm.userId.toString() == _userId;
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40 : 0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: isReply ? 14 : 20,
          child: const Icon(Icons.person),
        ),
        title: Text(cm.username, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cm.content),
            const SizedBox(height: 4),
            if (!isOwnComment)
              GestureDetector(
                onTap: () => _startReply(cm),
                child: const Text('Balas',
                    style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Komentar',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          if (_replyingToId != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text('Membalas ke $_replyingToUsername',
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                  GestureDetector(
                                    onTap: _cancelReply,
                                    child: const Icon(Icons.close, size: 16),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _commentController,
                                  focusNode: _commentFocusNode,
                                  decoration: InputDecoration(
                                    hintText: _replyingToId != null
                                        ? 'Tulis balasan...'
                                        : 'Tulis komentar...',
                                    border: const OutlineInputBorder(),
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
                              : _topLevelComments.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Text('Belum ada komentar'),
                                    )
                                  : Column(
                                      children: _topLevelComments.map((cm) {
                                        final replies = _repliesOf(cm.id);
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildCommentTile(cm),
                                            ...replies.map(
                                                (r) => _buildCommentTile(r, isReply: true)),
                                            const Divider(),
                                          ],
                                        );
                                      }).toList(),
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