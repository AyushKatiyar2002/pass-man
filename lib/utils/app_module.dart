import 'package:flutter_modular/flutter_modular.dart';
import 'package:passman/screens/screens.dart';

class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (_, __) => AuthState()),
        ChildRoute(HomeScreen.route, child: (_, __) => HomeScreen()),
      ];
}
