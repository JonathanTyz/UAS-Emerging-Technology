import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../class/category.dart';
import 'comiclist_page.dart';
import 'search_page.dart';
import 'createcomic_page.dart';
import 'login_page.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Category> _categories = [];
  bool _loading = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    bacaData();
  }

  Future<String> fetchData() async {
    final response = await http.get(Uri.parse("${baseUrl}category_list.php"));
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
        _categories = List<Category>.from(
            (json['data'] as List).map((c) => Category.fromJson(c)));
      } else {
        _categories = [];
        _errorMsg = json['message'] ?? 'Tidak ada kategori';
      }
      setState(() {
        _loading = false;
      });
    }).catchError((e) {
      setState(() {
        _loading = false;
        _errorMsg = "Gagal memuat kategori";
      });
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // ikon berbeda tiap kategori supaya lebih enak dilihat
  IconData _iconFor(String slug) {
    switch (slug) {
      case 'action':
        return Icons.flash_on;
      case 'komedi':
        return Icons.emoji_emotions;
      case 'horor':
        return Icons.dark_mode;
      case 'romance':
        return Icons.favorite;
      case 'slice-of-life':
        return Icons.coffee;
      case 'fantasy':
        return Icons.auto_awesome;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Komik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const SearchPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const CreateComicPage()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Buat Komik'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => bacaData(),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text(_errorMsg)),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (BuildContext ctxt, int index) {
                      final cat = _categories[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ComicListPage(
                                  categoryId: cat.id,
                                  categoryName: cat.name,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_iconFor(cat.slug), size: 40, color: Colors.deepOrange),
                              const SizedBox(height: 8),
                              Text(cat.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
