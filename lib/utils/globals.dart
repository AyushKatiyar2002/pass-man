import 'dart:math';
import 'dart:ui' show window;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';

import './utils.dart';

extension GlobalValue on num {
  double get w => (Globals.screenWidth * this) / 100;

  double get h => (Globals.rawScreenHeight * this) / 100;
}

abstract class Globals {
  //Screen Resolution
  static double get rawScreenHeight =>
      window.physicalSize.height / window.devicePixelRatio;

  static double get rawScreenWidth =>
      window.physicalSize.width / window.devicePixelRatio;

  static double get screenWidth => min(rawScreenWidth, webMaxWidth);

  static double get platformWidth => kIsWeb ? screenWidth : rawScreenWidth;

  //Constants from here
  static const double webMaxWidth = 500;

  static final ButtonStyle kElevatedButtonStyle = ElevatedButton.styleFrom(
    primary: ColorsUtils.kPrimaryColor,
    shape: RoundedRectangleBorder(
      borderRadius: kBorderRadius,
    ),
    textStyle: GoogleFonts.montserrat(
      fontSize: 4.w,
    ),
  );

  static final kBorderRadius = BorderRadius.circular(3.5.w);

  static final kBodyText1Style = GoogleFonts.montserrat(fontSize: 4.5.w);
  static final kBodyText2Style = GoogleFonts.montserrat(fontSize: 3.w);
  static final kBodyText3Style = GoogleFonts.montserrat(fontSize: 3.5.w);
  static final kHeading2Style = GoogleFonts.montserrat(fontSize: 5.w);
  static final kHeading1Style = GoogleFonts.montserrat(fontSize: 6.w);

  static final kInputDecorationTheme = InputDecorationTheme(
    fillColor: ColorsUtils.kElevationColor,
    filled: true,
    errorStyle: kBodyText2Style.copyWith(
      color: Colors.red,
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: kBorderRadius,
    ),
    hintStyle: kBodyText1Style,
  );

  static final kSizedBox = SizedBox(
    height: Globals.screenWidth * 0.04,
  );

  static const kScreenPadding = const EdgeInsets.all(20);

  static final kBackButton = IconButton(
    onPressed: () {
      Modular.to.pop();
    },
    icon: Icon(Icons.chevron_left),
  );

  static final String? Function(String?) kFieldRequiredValidator = (_) {
    if (_?.isEmpty ?? true) return 'This Field is required';
  };
}
