import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:passman/utils/utils.dart';

import 'screens/screens.dart';

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pass-Man',
      theme: ThemeData(
          appBarTheme: AppBarTheme(
            backgroundColor: ColorsUtils.kBackgroundColor,
            elevation: 0.0,
            titleTextStyle: Globals.kHeading2Style,
            titleSpacing: 35,
          ),
          snackBarTheme: SnackBarThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10.w)),
            ),
            contentTextStyle: Globals.kBodyText1Style,
            backgroundColor: ColorsUtils.kSecondaryColor,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: Globals.kElevatedButtonStyle,
          ),
          textTheme: ThemeData.dark().textTheme.copyWith(
                bodyText1: Globals.kBodyText1Style,
                bodyText2: Globals.kBodyText2Style,
                subtitle1:
                    Globals.kBodyText1Style, //For TextField default style
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
          primarySwatch: ColorsUtils.kSecondaryColor,
          primaryColor: ColorsUtils.kPrimaryColor,
          colorScheme: ColorScheme.dark(
            secondary: ColorsUtils.kSecondaryColor,
          ),
          primaryColorLight: ColorsUtils.kTextColor,
          backgroundColor: ColorsUtils.kBackgroundColor,
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            extendedTextStyle: Globals.kBodyText3Style,
          )),
      initialRoute: AuthState.route,
    ).modular();
  }
}
