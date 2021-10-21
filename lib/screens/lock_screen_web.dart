import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:helpful_components/helpful_components.dart';
import 'package:passman/utils/storage.dart';

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
    if (Storage.isTokenValid()) _authorized = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _authorized
        ? Container()
        : Scaffold(
            body: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 500),
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
                          bool verified = await Storage.verifyMPass(text);
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
                          Storage.reIssueToken();
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
