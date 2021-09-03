import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import './utils/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProviderScope(child: ModularApp(module: AppModule(), child: MyApp())));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: ColorsUtils.kBackgroundColor,
          elevation: 0.0,
          titleTextStyle: GoogleFonts.montserrat(),
          titleSpacing: 35,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: Globals.kElevatedButtonStyle,
        ),
        textTheme: ThemeData.dark().textTheme.copyWith(
              bodyText1: Globals.kBodyText1Style,
              bodyText2: Globals.kBodyText2Style,
            ),
        cardTheme: CardTheme(
          color: ColorsUtils.kElevationColor,
          shape: RoundedRectangleBorder(
            borderRadius: Globals.kBorderRadius,
          ),
        ),
        inputDecorationTheme: Globals.kInputDecorationTheme,
        scaffoldBackgroundColor: ColorsUtils.kBackgroundColor,
        brightness: Brightness.dark,
        accentColor: ColorsUtils.kSecondaryColor,
        primarySwatch: ColorsUtils.kSecondaryColor,
        primaryColor: ColorsUtils.kPrimaryColor,
        primaryColorLight: ColorsUtils.kTextColor,
        backgroundColor: ColorsUtils.kBackgroundColor,
      ),
      initialRoute: '/',
    ).modular();
  }
}
