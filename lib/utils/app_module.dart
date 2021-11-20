import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:passman/extensions/extensions.dart';
import 'package:passman/screens/screens.dart';
import 'package:passman/utils/storage/storage.dart';

class AppModule extends Module {
  static const kLockScreenRoute = '/lock';

  @override
  List<ModularRoute> get routes => [
        ChildRoute(MPassword.route, child: (_, __) => MPassword()),
        ChildRoute(AuthState.route, child: (_, __) => AuthState()),
        ChildRoute(AddUpdateNote.route, child: (_, __) => AddUpdateNote().auth),
        ChildRoute(AddUpdateAccount.route,
            child: (_, __) => AddUpdateAccount(account: __.data).auth),
        ChildRoute(HomeScreen.route, child: (_, __) {
          print('trying opening home screen');
          print('need mPassCache: ${kIsWeb && AuthStorage.mPassKey == null}');
          if (kIsWeb && AuthStorage.mPassKey == null) {
            if (AuthStorage.mPassExists()) return lockScreen();
            return MPassword();
          }
          return HomeScreen().auth;
        }),
        ChildRoute(kLockScreenRoute, child: (_, __) => lockScreen()),
      ];
}
