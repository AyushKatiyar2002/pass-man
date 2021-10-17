import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:passman/utils/globals.dart';
import '../screens/screens.dart';

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
        LockScreen(),
      ],
    );
  }
}
