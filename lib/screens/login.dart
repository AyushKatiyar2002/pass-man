import 'package:flutter_modular/flutter_modular.dart';
import 'package:passman/screens/authstate.dart';

import '../utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import '../utils/globals.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      onSignup: onSignUp,
      onLogin: onLogin,
      title: 'PASSMAN',
      userType: LoginUserType.email,
      theme: LoginTheme(
        primaryColor: ColorsUtils.kPrimaryColor,
        pageColorDark: ColorsUtils.kBackgroundColor,
        pageColorLight: ColorsUtils.kBackgroundColor,
        bodyStyle: GoogleFonts.roboto(
          color: ColorsUtils.kTextColor,
        ),
        textFieldStyle: GoogleFonts.montserrat(
          color: ColorsUtils.kTextColor,
        ),
        titleStyle: GoogleFonts.montserrat(
          fontSize: 4.w,
        ),
        buttonTheme: LoginButtonTheme(
          backgroundColor: ColorsUtils.kPrimaryColor,
        ),
      ),
      onRecoverPassword: resetPassword,
      onSubmitAnimationCompleted: () {
        Modular.to.pushNamed(AuthState.route);
      },
    );
  }

  Future<String?>? onSignUp(LoginData data) async {
    print('Trying to sign in');
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: data.name, password: data.password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'The account already exists for this email.';
      }
    } catch (e) {
      print(e);
    }
    print('Successfully Signed Up');
  }

  Future<String?>? onLogin(LoginData data) async {
    print("trying to log in");
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: data.name, password: data.password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided for that user.';
      }
      throw e;
    }
  }

  Future<String?>? resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (err) {
      if (err.code == 'invalid-email') return 'Invalid Email';
      if (err.code == 'user-not-found') return 'No User exists with this email';
    }
  }
}
