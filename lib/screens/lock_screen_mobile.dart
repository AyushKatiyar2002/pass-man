import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:helpful_components/helpful_components.dart';
import 'package:local_auth/local_auth.dart';
import 'package:passman/screens/home.dart';

import '../utils/globals.dart';
import '../utils/utils.dart';

Widget lockScreen() => LockScreen();

enum _SupportState {
  unknown,
  supported,
  unsupported,
}

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
  _SupportState _supportState = _SupportState.unknown;
  String _authorized = __notAuthorized;
  Widget _body = Container();

  @override
  void initState() {
    super.initState();
    auth.isDeviceSupported().then(
          (isSupported) => setState(() => _supportState = isSupported
              ? _SupportState.supported
              : _SupportState.unsupported),
        );

    //Check if token is verified, if verified then no need to authenticate again and
    //re issue token.
    if (AuthStorage.isTokenValid()) {
      _authorized = __authorized;
      AuthStorage.reIssueToken();
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
              if (AuthStorage.mPassExists()) {
                setState(() => _body = _mPass);
                return;
              }
              print("M-Pass Does not exist");
              FirebaseAuth.instance.signOut();
            });
            Navigator.pop(context);
          },
        ),
      );
      return;
    }
    if (!mounted) return;

    if (authenticated) AuthStorage.reIssueToken();
    setState(
        () => _authorized = authenticated ? __authorized : __notAuthorized);
  }

  Widget get _mPass => Form(
        key: _formKey,
        child: TextFormField(
          style: Globals.kBodyText1Style,
          onFieldSubmitted: (text) {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            showDialog(
              context: context,
              builder: (_) => FutureDialog<bool>(
                future: AuthStorage.verifyMPass(text),
                hasData: (data) {
                  if (data ?? false)
                    return CommonAlertDialog(
                      'Successfully Verified mPass',
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
                    'Incorrect mPass',
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
    if (_authorized == __authorized)
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        Modular.to.pushReplacementNamed(HomeScreen.route);
      });
    return Scaffold(
      body: (_supportState != _SupportState.supported) ||
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
            ),
    );
  }
}
