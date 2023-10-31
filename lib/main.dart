import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:passman/my_app.dart';

import './utils/utils.dart';
import 'config_app.dart' if (dart.library.html) 'config_app_web.dart';

void main() async {
  print("started main function");
  WidgetsFlutterBinding.ensureInitialized();
  await configureApp();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox(AuthStorage.auth);
  await Hive.openBox(Secrets.boxName);
  await Hive.openBox(Deleted.boxName);
  await Hive.openBox(Database.boxName);
  runApp(ProviderScope(child: ModularApp(module: AppModule(), child: MyApp())));
//abhishek22 edited
}
