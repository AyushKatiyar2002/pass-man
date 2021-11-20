import 'package:flutter/material.dart';
import 'package:passman/screens/screens.dart';
import 'package:passman/utils/utils.dart';

extension WidgetAuth on Widget {
  Widget get auth {
    if (!AuthStorage.isTokenValid()) lockScreen();
    return this;
  }
}
