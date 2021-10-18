import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helpful_components/helpful_components.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/utils.dart';
import '../utils/globals.dart';

Widget lockScreen() => LockScreen();

class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  static const __authorized = 'Authorized';
  static const __notAuthorized = 'Not Authorized';
  final _formKey = GlobalKey<FormState>();
  final LocalAuthentication auth = LocalAuthentication();
  SupportState _supportState = SupportState.unknown;
  String _authorized = __notAuthorized;
  Widget _body = Container();

  @override
  void initState() {
    super.initState();
    auth.isDeviceSupported().then(
          (isSupported) => setState(() => _supportState =
      isSupported ? SupportState.supported : SupportState.unsupported),
    );

    //Check if token is verified, if verified then no need to authenticate again and
    //re issue token.
    if (Storage.isTokenValid()) {
      _authorized = __authorized;
      Storage.reIssueToken();
    } else
      _authenticate();
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _authorized = 'Authenticating';
      });
      authenticated = await auth.authenticate(
        localizedReason:
        'Please authenticate the device to use the application!',
        useErrorDialogs: true,
        stickyAuth: true,
      );
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _authorized = "Error - ${e.message}";
      });
      showDialog(
        context: context,
        builder: (_) => CommonAlertDialog(
          _authorized,
          error: true,
          onPressed: () {
            WidgetsBinding.instance!.addPostFrameCallback((_) {
              if (Storage.mPinExists()) {
                setState(() {
                  _body = _mPin;
                });
                return;
              }
              FirebaseAuth.instance.signOut();
            });
            Navigator.pop(context);
          },
        ),
      );
      return;
    }
    if (!mounted) return;

    if (authenticated) Storage.reIssueToken();
    setState(
            () => _authorized = authenticated ? __authorized : __notAuthorized);
  }

  Widget get _mPin => Form(
    key: _formKey,
    child: TextFormField(
      style: Globals.kBodyText1Style,
      keyboardType: TextInputType.number,
      onFieldSubmitted: (text) {
        if (!(_formKey.currentState?.validate() ?? false)) return;
        showDialog(
          context: context,
          builder: (_) => FutureDialog<bool>(
            future: Storage.verifyMPin(text),
            hasData: (data) {
              if (data ?? false)
                return CommonAlertDialog(
                  'Successfully Verified mPin',
                  onPressed: () {
                    WidgetsBinding.instance!.addPostFrameCallback((_) {
                      setState(() {
                        _authorized = __authorized;
                      });
                    });
                    Navigator.pop(context);
                  },
                );
              return CommonAlertDialog(
                'Incorrect mPin',
                onPressed: () {
                  WidgetsBinding.instance!.addPostFrameCallback((_) {
                    setState(() {
                      _authorized = __notAuthorized;
                    });
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    return (_supportState != SupportState.supported) ||
        (_authorized == __authorized) ||
        (kIsWeb)
        ? Container()
        : GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Center(
          child: _body,
        ),
      ),
    );
  }
}
