import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'category_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _username = "";
  String _password = "";
  String _errorLogin = "";
  bool _loading = false;

  void doLogin() async {
    setState(() {
      _loading = true;
      _errorLogin = "";
    });
    try {
      final response = await http.post(
        Uri.parse("${baseUrl}login.php"),
        body: {'username': _username, 'password': _password},
      );
      if (response.statusCode == 200) {
        Map json = jsonDecode(response.body);
        if (json['result'] == 'success') {
          final data = json['data'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', data['id'].toString());
          await prefs.setString('username', data['username'].toString());
          await prefs.setString('name', data['name'].toString());
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const CategoryPage()),
          );
        } else {
          setState(() {
            _errorLogin = json['message'] ?? 'Login gagal';
          });
        }
      } else {
        throw Exception('Failed to read API');
      }
    } catch (e) {
      setState(() {
        _errorLogin = "Tidak dapat terhubung ke server";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Icon(Icons.menu_book, size: 72, color: Colors.deepOrange),
                  const SizedBox(height: 8),
                  const Text(
                    'Komiku',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _username = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      _password = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password harus diisi';
                      }
                      return null;
                    },
                  ),
                  if (_errorLogin.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _errorLogin,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'usn: jonathanw',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'pwd: 123',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            if (_formKey.currentState != null &&
                                !_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Harap isian diperbaiki')),
                              );
                            } else {
                              doLogin();
                            }
                          },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
