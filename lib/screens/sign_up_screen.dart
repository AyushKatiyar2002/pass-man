import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helpful_components/helpful_components.dart';
import 'package:passman/screens/home.dart';
import 'package:passman/screens/login.dart';
import 'package:passman/utils/globals.dart';

class SignUpScreen extends StatefulWidget {
  SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: ''),
      _email = TextEditingController(text: '');
  late Widget _screen;

  Widget _signUpScreen(User user) {
    _name.text = user.displayName ?? '';
    _email.text = user.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up', style: Globals.kHeading1Style),
      ),
      body: Padding(
        padding: Globals.kScreenPadding,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                style: Globals.kBodyText1Style,
                controller: _name,
                decoration: InputDecoration(hintText: 'Enter Name'),
                validator: Globals.kCommonValidator,
              ),
              SizedBox(height: 4.w),
              TextFormField(
                style: Globals.kBodyText1Style,
                controller: _email,
                decoration: InputDecoration(hintText: 'Enter Email'),
                validator: Globals.kCommonValidator,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            final __futures = [
              if (_name.text.isNotEmpty && user.displayName != _name.text)
                user.updateDisplayName(_name.text),
              if (_email.text.isNotEmpty && user.email != _email.text)
                user.updateEmail(_email.text),
            ];
            final _futures = Future.wait(__futures);
            await showDialog(
              context: context,
              builder: (_) => FutureDialog(
                future: _futures,
                hasData: (_) => CommonAlertDialog("Successfully Updated User"),
              ),
            );
          },
          label: Text(
            'Submit',
            style: Globals.kBodyText2Style,
          )),
    );
  }

  @override
  void initState() {
    final _user = FirebaseAuth.instance.currentUser;
    if (_user == null)
      _screen = LoginScreen();
    else if ((_user.email?.isEmpty ?? false) &&
        (_user.displayName?.isEmpty ?? false))
      _screen = _signUpScreen(_user);
    else
      _screen = HomeScreen();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _screen;
  }
}
