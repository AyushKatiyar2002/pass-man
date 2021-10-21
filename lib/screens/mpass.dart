import 'package:flutter/material.dart';
import 'package:passman/utils/storage.dart';

class MPassword extends StatefulWidget {
  static const route = '/m_password';

  const MPassword({Key? key}) : super(key: key);

  @override
  State<MPassword> createState() => _MPasswordState();
}

class _MPasswordState extends State<MPassword> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                textAlign: TextAlign.center,
                decoration: InputDecoration(hintText: 'Set MPassword'),
                onFieldSubmitted: (text) async {
                  try {
                    await Storage.setMPass(text);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Successfully Set MPassword'),
                          ],
                        ),
                      ),
                    );
                  } catch (err) {
                    print(err);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
