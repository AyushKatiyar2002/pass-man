import 'package:passman/extensions/hex.dart';
import 'package:passman/utils/storage/super_secret_key.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

SuperSecretMobile get superSecret => SuperSecretMobile.instance;

class SuperSecretMobile extends SuperSecret {
  SuperSecretMobile._();

  static SuperSecretMobile? _instance;
  static const String _superSecretKey = 'superSecretKey';

  List<int>? _superSecret;

  static SuperSecretMobile get instance {
    if (_instance == null) _instance = SuperSecretMobile._();
    return _instance!;
  }

  Future<List<int>> get value async {
    if (_superSecret != null) return _superSecret!;

    final _storage = FlutterSecureStorage();
    var superSecret = (await _storage.read(key: _superSecretKey))?.hexUnits;

    if (superSecret == null) {
      print("WARNING: Either no key or corrupted key");
      print("Generating New Key");

      superSecret = await generateKey();
      await _storage.write(key: _superSecretKey, value: superSecret.hexString);
    }

    _superSecret = superSecret;
    return superSecret;
  }
}
