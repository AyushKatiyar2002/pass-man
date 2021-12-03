import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:passman/utils/storage/super_secret_key_web.dart';

Future<void> configureApp() async {
  setUrlStrategy(PathUrlStrategy());
  await Hive.openBox(SuperSecretWeb.superSecretBoxName);
}
