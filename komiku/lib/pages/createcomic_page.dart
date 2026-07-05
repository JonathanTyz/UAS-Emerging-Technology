import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../class/category.dart';
import 'chapterlist_page.dart';

class CreateComicPage extends StatefulWidget {
  const CreateComicPage({super.key});

  @override
  State<CreateComicPage> createState() => _CreateComicPageState();
}

class _ChapterData {
  final TextEditingController titleController = TextEditingController();
  List<Uint8List> pageBytes = [];
}

class _CreateComicPageState extends State<CreateComicPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  String _title = "";
  String _synopsis = "";
  String _status = "ongoing";

  Uint8List? _posterBytes;

  List<Category> _categories = [];
  final Set<int> _selectedCategoryIds = {};
  bool _loadingCategories = true;

  final List<_ChapterData> _chapters = [_ChapterData()];

  bool _submitting = false;
  String _progressText = "";

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await http.get(Uri.parse("${baseUrl}category_list.php"));
      if (response.statusCode == 200) {
        Map json = jsonDecode(response.body);
        if (json['result'] == 'success') {
          setState(() {
            _categories = List<Category>.from(
                (json['data'] as List).map((c) => Category.fromJson(c)));
            _loadingCategories = false;
          });
          return;
        }
      }
    } catch (e) {
    }
    setState(() => _loadingCategories = false);
  }

  Future<void> _pickPoster() async {
  final image = await _picker.pickImage(
  source: ImageSource.gallery,
);

  if (image != null) {
    final bytes = await image.readAsBytes();

    setState(() {
      _posterBytes = bytes;
    });
  }
}

  Future<void> _replacePages(int chapterIndex) async {
    final images = await _picker.pickMultiImage();

    if (images.isNotEmpty) {
      List<Uint8List> list = [];
      for (var img in images) {
        list.add(await img.readAsBytes());
      }

      setState(() {
        _chapters[chapterIndex].pageBytes = list;
      });
    }
  }

  Future<void> _addPages(int chapterIndex) async {
    final images = await _picker.pickMultiImage();

    if (images.isNotEmpty) {
      List<Uint8List> list = [];
      for (var img in images) {
        list.add(await img.readAsBytes());
      }

      setState(() {
        _chapters[chapterIndex].pageBytes.addAll(list);
      });
    }
  }

  void _addChapter() {
    setState(() {
      _chapters.add(_ChapterData());
    });
  }

  void _removeChapter(int chapterIndex) {
    setState(() {
      _chapters.removeAt(chapterIndex);
    });
  }

  Future<void> _submit() async {
    if (_posterBytes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Poster wajib dipilih')));
      return;
    }
    for (int i = 0; i < _chapters.length; i++) {
      if (_chapters[i].pageBytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chapter ${i + 1} minimal harus punya 1 halaman')));
        return;
      }
    }
    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih minimal 1 kategori')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Silakan login terlebih dahulu')));
      return;
    }

    setState(() {
      _submitting = true;
      _progressText = "Mengunggah poster & data komik...";
    });

    try {
      final posterBytes = _posterBytes;
      final posterBase64 = base64Encode(posterBytes!);
      final categoriesParam = _selectedCategoryIds.join(",");

      final response = await http.post(
        Uri.parse("${baseUrl}add_comic.php"),
        body: {
          'user_id': userId,
          'title': _title,
          'synopsis': _synopsis,
          'status': _status,
          'poster': posterBase64,
          'categories': categoriesParam,
          'chapter_title': _chapters[0].titleController.text,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to read API');
      }
      Map json = jsonDecode(response.body);
      if (json['result'] != 'success') {
        throw Exception(json['message'] ?? 'Gagal membuat komik');
      }

      final comicId = json['comic_id'];
      final firstChapterId = json['chapter_id'];

      final firstPages = _chapters[0].pageBytes;
      for (int i = 0; i < firstPages.length; i++) {
        setState(() {
          _progressText = "Mengunggah halaman ${i + 1} dari ${firstPages.length} (Chapter 1)...";
        });
        final pageBase64 = base64Encode(firstPages[i]);

        final pageResponse = await http.post(
          Uri.parse("${baseUrl}add_chapter_page.php"),
          body: {
            'comic_id': comicId.toString(),
            'chapter_id': firstChapterId.toString(),
            'page_number': (i + 1).toString(),
            'image': pageBase64,
          },
        );
        if (pageResponse.statusCode != 200) {
          throw Exception('Gagal mengunggah halaman ${i + 1}');
        }
      }

      for (int c = 1; c < _chapters.length; c++) {
        final pages = _chapters[c].pageBytes;
        String? chapterId;

        for (int i = 0; i < pages.length; i++) {
          setState(() {
            _progressText =
                "Mengunggah halaman ${i + 1} dari ${pages.length} (Chapter ${c + 1})...";
          });
          final pageBase64 = base64Encode(pages[i]);

          final body = <String, String>{
            'comic_id': comicId.toString(),
            'page_number': (i + 1).toString(),
            'image': pageBase64,
          };
          if (chapterId == null) {
            body['chapter_title'] = _chapters[c].titleController.text;
          } else {
            body['chapter_id'] = chapterId;
          }

          final pageResponse = await http.post(
            Uri.parse("${baseUrl}add_chapter_page.php"),
            body: body,
          );
          if (pageResponse.statusCode != 200) {
            throw Exception('Gagal mengunggah halaman ${i + 1} chapter ${c + 1}');
          }
          Map pageJson = jsonDecode(pageResponse.body);
          if (pageJson['result'] != 'success') {
            throw Exception(pageJson['message'] ?? 'Gagal mengunggah halaman ${i + 1} chapter ${c + 1}');
          }
          chapterId ??= pageJson['chapter_id'].toString();
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Komik berhasil dibuat!')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChapterListPage(comicId: comicId)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _progressText = "";
        });
      }
    }
  }

  Widget _buildChapterFields(int index) {
    final chapter = _chapters[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: chapter.titleController,
          decoration: const InputDecoration(
            labelText: "Judul Chapter",
            border: OutlineInputBorder(),
          ),
        ),
        Row(
          children: [
            Text('Isi Komik (Chapter ${index + 1})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_chapters.length > 1)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeChapter(index),
                tooltip: 'Hapus chapter ini',
              ),
            TextButton.icon(
              onPressed: () => _replacePages(index),
              icon: const Icon(Icons.photo_library),
              label: const Text('Ganti Halaman'),
            ),
            TextButton.icon(
              onPressed: () => _addPages(index),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Halaman'),
            ),
          ],
        ),
        chapter.pageBytes.isEmpty
            ? Container(
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Belum ada halaman dipilih'),
              )
            : SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: chapter.pageBytes.length,
                  itemBuilder: (context, pageIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(
                              chapter.pageBytes[pageIndex],
                              width: 90,
                              height: 130,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            left: 4,
                            top: 4,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.black54,
                              child: Text('${pageIndex + 1}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Komik')),
      body: _submitting
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_progressText),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GestureDetector(
                    onTap: _pickPoster,
                    child: Container(
                      height: 180,
                      width: 130,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: _posterBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _posterBytes!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 36),
                                SizedBox(height: 4),
                                Text('Pilih Poster', textAlign: TextAlign.center),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Judul Komik',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _title = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Judul harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Sinopsis',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    keyboardType: TextInputType.multiline,
                    minLines: 3,
                    maxLines: 6,
                    onChanged: (value) => _synopsis = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Sinopsis harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                      DropdownMenuItem(value: 'completed', child: Text('Tamat')),
                    ],
                    onChanged: (value) {
                      setState(() => _status = value ?? 'ongoing');
                    },
                  ),
                  const SizedBox(height: 20),

                  const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _loadingCategories
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        )
                      : Wrap(
                          spacing: 8,
                          children: _categories.map((cat) {
                            final selected = _selectedCategoryIds.contains(cat.id);
                            return FilterChip(
                              label: Text(cat.name),
                              selected: selected,
                              onSelected: (value) {
                                setState(() {
                                  if (value) {
                                    _selectedCategoryIds.add(cat.id);
                                  } else {
                                    _selectedCategoryIds.remove(cat.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 20),

                  for (int i = 0; i < _chapters.length; i++) _buildChapterFields(i),

                  OutlinedButton.icon(
                    onPressed: _addChapter,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Chapter'),
                  ),

                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState != null &&
                          !_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Harap isian diperbaiki')));
                      } else {
                        _submit();
                      }
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Buat Komik'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}