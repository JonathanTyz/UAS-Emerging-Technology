    import 'package:flutter/material.dart';
    import 'main.dart';
    import 'package:shared_preferences/shared_preferences.dart';



    class Login extends StatefulWidget {
      const Login({super.key});
      @override

      State<StatefulWidget> createState() {
        return _LoginState();
      }
    }
    
    class _LoginState extends State<Login> {
      String username = "";
      String email = "";
      String password = "";
      @override
      void initState() {
        super.initState();
        checkLogin();
      }

      void checkLogin() async {
        final prefs = await SharedPreferences.getInstance();
        String? savedUser = prefs.getString("username");

        if (savedUser != null && savedUser.isNotEmpty) {
          active_user = savedUser;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyHomePage(title: "Memorigame")),
          );
        }
      }
    void doLogin() async {
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString("username", username);
        active_user = username;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage(title: "Memorigame")),
        );
      }

      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Login'),
          ),
          body: Container(
            height: 600,
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              border: Border.all(width: 1),
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 5)]),
              child: Column(children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Username',
                        hintText: 'Enter valid username'),
                        onChanged: (v) {
                          username = v;},
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                        hintText: 'Enter valid Email'),
                        onChanged: (v) {
                          email = v;},
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  //padding: EdgeInsets.symmetric(horizontal: 15),
                  child: TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                        hintText: 'Enter secure password'),
                        onChanged: (v) {
                          password = v;},
                  ),
                ),
                
                    Padding(
                    padding: EdgeInsets.all(10),
                    child: Container(
                      height: 50,
                      width: 300,
                      decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20)),
                      child: ElevatedButton(
                        onPressed: doLogin,
                        child: Text(
                          'Login',
                          style: TextStyle(fontSize: 25),
                        ),
                      ),
                    )),
              ]),
      ));
      }
    }
