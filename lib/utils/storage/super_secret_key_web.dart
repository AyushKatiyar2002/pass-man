import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:passman/utils/storage/auth.dart';
import 'package:passman/utils/storage/super_secret_key.dart';

SuperSecretWeb get superSecret => SuperSecretWeb.instance;

class SuperSecretWeb extends SuperSecret {
  SuperSecretWeb._();

  static SuperSecretWeb? _instance;
  static const String superSecretBoxName = 'superSecretBox';
  static const String _superSecretKey = 'superSecretKey';
  static const String _superSecretMac = 'superSecretMac';
  static const String _superSecretNonce = 'superSecretNonce';

  static SuperSecretWeb get instance {
    if (_instance == null) _instance = SuperSecretWeb._();
    return _instance!;
  }

  List<int>? _superSecret;

  Future<List<int>> get value async {
    if (_superSecret != null) return _superSecret!;

    final _mPassKey = AuthStorage.mPassKey;
    if (_mPassKey == null) throw PlatformException(code: 'MPASS_NULL');

    final _box = Hive.box(superSecretBoxName);
    final _algorithm = AesGcm.with256bits();
    final _encryptedKey = List<int>.from(_box.get(_superSecretKey) ?? []);
    final _mac = List<int>.from(_box.get(_superSecretMac) ?? []);
    final _nonce = List<int>.from(_box.get(_superSecretNonce) ?? []);

    if (_encryptedKey.isEmpty || _mac.isEmpty || _nonce.isEmpty) {
      print("WARNING: Either no key or corrupted key (WEB)");
      print("Generating New Key (WEB)");

      final superSecret =
          await (await _algorithm.newSecretKey()).extractBytes();
      _superSecret = superSecret;
      final _secretBox =
          await _algorithm.encrypt(superSecret, secretKey: _mPassKey);
      _box.put(_superSecretKey, _secretBox.cipherText);
      _box.put(_superSecretMac, _secretBox.mac.bytes);
      _box.put(_superSecretNonce, _secretBox.nonce);
      return superSecret;
    }

    final _secretBox = SecretBox(
      _encryptedKey,
      nonce: _nonce,
      mac: Mac(_mac),
    );
    final superSecret =
        await _algorithm.decrypt(_secretBox, secretKey: _mPassKey);
    _superSecret = superSecret;
    return superSecret;
  }
}
