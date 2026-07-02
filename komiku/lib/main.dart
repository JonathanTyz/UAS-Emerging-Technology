import 'package:flutter/material.dart';
import 'login.dart';
import 'package:shared_preferences/shared_preferences.dart';

String active_user = "";

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  String result = await checkUser();
  active_user = result; // Set user global
  runApp(const MyApp());
}

Future<String> checkUser() async {
  // Simulate a delay for checking the user
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('username') ?? '';
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Komiku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: active_user == "" ? const Login() : const MyHomePage(title: "Memorigame"),
      routes:{
        '/login': (context) => const Login(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  void doLogout() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("username");
      active_user = "";
      Navigator.pushReplacementNamed(
        context,
        '/login',
      );
    }

    
  Widget myDrawer()
  {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(active_user),
            accountEmail: const Text("Memorimage Player"),
          ),

          ListTile(
            title: const Text("High Score"),
            leading: const Icon(Icons.leaderboard),
            onTap: () {
              Navigator.pushNamed(context, '/highscore');
            },
          ),

          ListTile(
            title: const Text("Logout"),
            leading: const Icon(Icons.logout),
            onTap: doLogout,
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),

      drawer: myDrawer(),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            //tengahkan
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Text(
                "Selamat datang di Memorigame",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              const Text(
                "Cara bermain:\n"
                "Akan ditampilkan beberapa gambar yang hanya muncul beberapa detik.\n"
                "Player harus mengingat gambar tersebut sebelum hilang.\n"
                "Setelah itu, player memilih jawaban dari 4 gambar yang tersedia.\n"
                "Setiap round memiliki waktu 30 detik.\n"
                "Jika waktu habis, tidak ada poin yang didapat.",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/game');
                },
                child: const Text("Play Game"),
              ),
            ],
          ),
        )
      )
      );
    }
  }

  // void _incrementCounter() {
  //   setState(() {
  //     // This call to setState tells the Flutter framework that something has
  //     // changed in this State, which causes it to rerun the build method below
  //     // so that the display can reflect the updated values. If we changed
  //     // _counter without calling setState(), then the build method would not be
  //     // called again, and so nothing would appear to happen.
  //     _counter++;
  //   });
  // }

 