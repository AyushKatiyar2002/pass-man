import 'package:flutter_modular/flutter_modular.dart';
import 'package:passman/screens/screens.dart';

class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute(MPassword.route, child: (_, __) => MPassword()),
        ChildRoute(AuthState.route, child: (_, __) => AuthState()),
      ];
}
