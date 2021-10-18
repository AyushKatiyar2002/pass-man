import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:passman/utils/utils.dart';
import '../screens/screens.dart';

class AuthState extends StatefulWidget {
  static const route = '/';

  const AuthState({Key? key}) : super(key: key);

  @override
  _AuthStateState createState() => _AuthStateState();
}

class _AuthStateState extends State<AuthState> {
  User? user;

  @override
  void initState() {
    user = FirebaseAuth.instance.currentUser;

    // initDynamicLinks();

    FirebaseAuth.instance.userChanges().listen((event) {
      if (user == event) return;

      //if user is logged in, re-issue token and no-need to change screen, as it
      //will get changed after the animation.
      if (event != null) {
        Storage.reIssueToken();
        return;
      }
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
