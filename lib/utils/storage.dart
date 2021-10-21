import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:passman/extensions/hex.dart';

class Storage {
  //Hive Globals
  static const auth = 'authStateBox';
  static const passwordsBox = 'passwordsBox';
  static const _lastLoginKey = 'lastLogin';
  static const _mPassKey = 'mPass';
  static const _mPassSaltKey = 'mPassSalt';
  static const _mPassMacKey = 'mPassMac';
  static const _loginExpiryDuration = Duration(minutes: 30);

  static DateTime get _expiredDate =>
      DateTime.now().subtract(Duration(days: 1));

  static bool isTokenValid() =>
      DateTime.now().difference((Hive.box(auth)
          .get(_lastLoginKey, defaultValue: _expiredDate) as DateTime)) <
      _loginExpiryDuration;

  static void reIssueToken() {
    Hive.box(auth).put(_lastLoginKey, DateTime.now());
  }

  static Future<bool> verifyMPass(String mPass) async {
    final _box = Hive.box(auth);
    final _encryptedMPin = (_box.get(_mPassKey) as String).hexUnits;
    final _mac = (_box.get(_mPassMacKey) as String).hexUnits;
    final String salt = _box.get(_mPassSaltKey);

    final _rawKey = sha256.convert((mPass.hexString + salt).hexUnits);
    final _algorithm = AesGcm.with256bits();
    final _key = await _algorithm.newSecretKeyFromBytes(_rawKey.bytes);
    final _secretBox = SecretBox(
      _encryptedMPin,
      nonce: salt.hexUnits,
      mac: Mac(_mac),
    );
    try {
      final _mPin = String.fromCharCodes(await _algorithm.decrypt(
        _secretBox,
        secretKey: _key,
      ));
      return _mPin == mPass;
    } catch (err) {
      return false;
    }
  }

  static bool mPassExists() => Hive.box(auth).get(_mPassKey) != null;

  ///Save mPin(List<int>) and salt(String).
  ///mPin is in encrypted with AES-GCM form with key as SHA-256(mPin + Salt) and
  ///IV as salt.
  ///
  /// Note: salt is 96 bits long.
  static Future<void> setMPass(String mPass) async {
    //to generate a salt of 96 bits so that it can also be used as IV/nonce.
    final String salt = _randomHexString(12);
    final _rawKey = sha256.convert((mPass.hexString + salt).hexUnits);
    final _algorithm = AesGcm.with256bits();
    final _key = await _algorithm.newSecretKeyFromBytes(_rawKey.bytes);
    final _mPin = await _algorithm.encrypt(
      mPass.codeUnits,
      secretKey: _key,
      nonce: salt.hexUnits,
    );

    final _box = Hive.box(auth);

    _box.put(_mPassKey, _mPin.cipherText.hexString);
    _box.put(_mPassSaltKey, salt);
    _box.put(_mPassMacKey, _mPin.mac.bytes.hexString);
  }

  static void clearMPass() {
    final _box = Hive.box(auth);
    _box.delete(_mPassKey);
    _box.delete(_mPassSaltKey);
  }

  ///[length] should be in terms of 8 bits (1 byte).
  static String _randomHexString(int length) {
    var random = Random.secure();
    var values = List<int>.generate(length, (i) => random.nextInt(256));
    return values.hexString;
  }
}
