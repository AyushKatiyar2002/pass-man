import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/screens.dart';

class AuthState extends StatefulWidget {
  const AuthState({Key? key}) : super(key: key);

  @override
  _AuthStateState createState() => _AuthStateState();
}

class _AuthStateState extends State<AuthState> {
  User? user;

  @override
  void initState() {
    // initDynamicLinks();
    FirebaseAuth.instance.userChanges().listen((event) {
      if (user == event) return;
      safeSetState(() => user = event);
    });
    super.initState();
  }

  void safeSetState(void Function() fn) {
    if (!mounted) return;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      setState(fn);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return LoginScreen();
    return (user!.displayName?.isEmpty ?? true) ? SignUpScreen() : HomeScreen();
  }
}
