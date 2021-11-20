import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:helpful_components/helpful_components.dart';
import 'package:passman/utils/utils.dart';

import 'home.dart';

Widget lockScreen() => LockScreenWeb();

class LockScreenWeb extends StatefulWidget {
  const LockScreenWeb({Key? key}) : super(key: key);

  @override
  _LockScreenWebState createState() => _LockScreenWebState();
}

class _LockScreenWebState extends State<LockScreenWeb> {
  bool _authorized = false;

  @override
  void initState() {
    if (AuthStorage.isTokenValid() && AuthStorage.mPassKey != null)
      _authorized = true;
    if (!AuthStorage.mPassExists()) _authorized = true;
    if (_authorized) AuthStorage.reIssueToken();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_authorized)
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        Modular.to.popAndPushNamed(HomeScreen.route);
      });
    return _authorized
        ? Container()
        : Scaffold(
            body: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: Globals.webMaxWidth),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                    child: Center(
                      child: TextField(
                        textAlign: TextAlign.center,
                        decoration:
                            InputDecoration(hintText: 'Enter M-Password'),
                        onSubmitted: (text) async {
                          bool verified = await AuthStorage.verifyMPass(text);
                          if (!verified) {
                            showDialog(
                              context: context,
                              builder: (_) => CommonAlertDialog(
                                'Wrong M-Password',
                                error: false,
                              ),
                            );
                            return;
                          }
                          AuthStorage.reIssueToken();
                          await showDialog(
                            context: context,
                            builder: (_) => CommonAlertDialog(
                              'Successfully Verified M-Password',
                            ),
                          );
                          setState(() => _authorized = true);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}
