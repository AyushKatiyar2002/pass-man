import 'package:helpful_components/helpful_components.dart';

import '../utils/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifyEmailScreen extends StatelessWidget {
  VerifyEmailScreen(User user, {Key? key})
      : this._user = user,
        this._actionCodeSettings = getActionCodeSettings(user),
        super(key: key);

  final User _user;
  final ActionCodeSettings _actionCodeSettings;

  static ActionCodeSettings getActionCodeSettings(User user) =>
      ActionCodeSettings(
        url: 'https://www.medicine.vishnuworld.com/?email=${user.email}',
        dynamicLinkDomain: 'clsvishnuworld.page.link',
        androidPackageName: 'com.vishnuworld.classroom',
        handleCodeInApp: true,
      );

  @override
  Widget build(BuildContext context) {
    return LoadingScreen<void>(
      future: _user.sendEmailVerification(_actionCodeSettings),
      func: (_) => Scaffold(
        appBar: AppBar(title: Text('Verify Email')),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Center(
            child: Column(
              children: [
                Text(
                  "Verification Mail Sent",
                  style: GoogleFonts.montserrat(),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text('Go Back'),
                  style: Globals.kElevatedButtonStyle,
                  onPressed: FirebaseAuth.instance.signOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
