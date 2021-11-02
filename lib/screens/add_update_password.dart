import 'package:flutter/material.dart';
import 'package:flutter_password_strength/flutter_password_strength.dart';
import 'package:passman/utils/globals.dart';
import 'package:passman/utils/utils.dart';

class AddUpdatePassword extends StatefulWidget {
  static const route = '/add-update-password';

  const AddUpdatePassword({Key? key}) : super(key: key);

  @override
  _AddUpdatePasswordState createState() => _AddUpdatePasswordState();
}

class _AddUpdatePasswordState extends State<AddUpdatePassword> {
  final formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool hidePassword = true;

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Globals.kBackButton,
        title: Text('Add/Update Password'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: Globals.kScreenPadding,
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'URL',
                  ),
                  validator: Globals.kCommonValidator,
                ),
                Globals.kSizedBox,
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Username/Email',
                  ),
                  validator: Globals.kCommonValidator,
                ),
                Globals.kSizedBox,
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                      icon: Icon(hidePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                    ),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                  obscureText: hidePassword,
                  validator: Globals.kCommonValidator,
                ),
                Globals.kSizedBox,
                AnimatedOpacity(
                  opacity: _passwordController.text.isEmpty ? 0 : 1,
                  duration: Duration(milliseconds: 300),
                  child: FlutterPasswordStrength(
                    password: _passwordController.text,
                  ),
                ),
                Globals.kSizedBox,
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Description...',
                  ),
                  textInputAction: TextInputAction.newline,
                  minLines: 5,
                  maxLines: 5,
                  validator: Globals.kCommonValidator,
                ),
                Globals.kSizedBox,
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onSubmit,
        label: Text("Submit"),
      ),
    );
  }
}
