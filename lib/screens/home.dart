import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:passman/screens/mpass.dart';
import 'package:passman/utils/globals.dart';

import 'lock_screen.dart'
    if (dart.library.io) 'lock_screen_mobile.dart'
    if (dart.library.html) 'lock_screen_web.dart';

class HomeScreen extends StatelessWidget {
  static const route = "/home";

  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text("Home"),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: FirebaseAuth.instance.signOut,
              ),
            ],
          ),
          drawer: Drawer(
            child: Column(
              children: [
                IconButton(
                  onPressed: () => Modular.to.pushNamed(MPassword.route),
                  icon: Icon(Icons.vpn_key),
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (_, i) => Card(
                child: Container(
                  width: double.infinity,
                  height: 100,
                  child: Center(
                    child: Text(
                      'Password',
                      style: TextStyle(fontSize: 4.w),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        lockScreen(),
      ],
    );
  }
}
