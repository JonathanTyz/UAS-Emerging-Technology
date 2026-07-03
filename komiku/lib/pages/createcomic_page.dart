import 'dart:convert';
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

class _CreateComicPageState extends State<CreateComicPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  String _title = "";
  String _synopsis = "";
  String _status = "ongoing";

  XFile? _posterFile;
  List<XFile> _pageFiles = [];

  List<Category> _categories = [];
  final Set<int> _selectedCategoryIds = {};
  bool _loadingCategories = true;

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
      // fallthrough
    }
    setState(() => _loadingCategories = false);
  }

  Future<void> _pickPoster() async {
    final XFile? img = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1000);
    if (img != null) {
      setState(() => _posterFile = img);
    }
  }

  Future<void> _pickPages() async {
    final List<XFile> imgs = await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1200);
    if (imgs.isNotEmpty) {
      setState(() => _pageFiles = imgs);
    }
  }

  Future<void> _submit() async {
    if (_posterFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Poster wajib dipilih')));
      return;
    }
    if (_pageFiles.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Minimal 1 halaman komik wajib diisi')));
      return;
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
      final posterBytes = await File(_posterFile!.path).readAsBytes();
      final posterBase64 = base64Encode(posterBytes);
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
      final chapterId = json['chapter_id'];

      for (int i = 0; i < _pageFiles.length; i++) {
        setState(() {
          _progressText = "Mengunggah halaman ${i + 1} dari ${_pageFiles.length}...";
        });
        final pageBytes = await File(_pageFiles[i].path).readAsBytes();
        final pageBase64 = base64Encode(pageBytes);

        final pageResponse = await http.post(
          Uri.parse("${baseUrl}add_chapter_page.php"),
          body: {
            'comic_id': comicId.toString(),
            'chapter_id': chapterId.toString(),
            'page_number': (i + 1).toString(),
            'image': pageBase64,
          },
        );
        if (pageResponse.statusCode != 200) {
          throw Exception('Gagal mengunggah halaman ${i + 1}');
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
                  // Poster
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
                      child: _posterFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(_posterFile!.path), fit: BoxFit.cover),
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

                  Row(
                    children: [
                      const Text('Isi Komik (Chapter 1)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _pickPages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: Text(_pageFiles.isEmpty
                            ? 'Pilih Gambar'
                            : 'Ganti (${_pageFiles.length})'),
                      ),
                    ],
                  ),
                  _pageFiles.isEmpty
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
                            itemCount: _pageFiles.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.file(
                                        File(_pageFiles[index].path),
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
                                        child: Text('${index + 1}',
                                            style: const TextStyle(fontSize: 11, color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
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
