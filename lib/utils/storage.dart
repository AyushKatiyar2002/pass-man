import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Storage {
  //Hive Globals
  static const auth = 'authStateBox';
  static const passwordsBox = 'passwordsBox';
  static const _lastLoginKey = 'lastLogin';
  static const _mPinKey = 'mPin';
  static const _mPinSaltKey = 'mPinSalt';
  static const _mPinMacKey = 'mPinMac';
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

  static Future<bool> verifyMPin(String mPin) async {
    final _box = Hive.box(auth);
    final _encryptedMPin = List<int>.from(_box.get(_mPinKey));
    final _mac = List<int>.from(_box.get(_mPinMacKey));
    final String salt = _box.get(_mPinSaltKey);

    final _rawKey = sha256.convert(utf8.encode(mPin + salt));
    final _algorithm = AesGcm.with256bits();
    final _key = await _algorithm.newSecretKeyFromBytes(_rawKey.bytes);
    final _secretBox = SecretBox(
      _encryptedMPin,
      nonce: utf8.encode(salt),
      mac: Mac(_mac),
    );
    final _mPin = utf8.decode(await _algorithm.decrypt(
      _secretBox,
      secretKey: _key,
    ));
    return _mPin == mPin;
  }

  static bool mPinExists() => Hive.box(auth).get(_mPinKey) != null;

  ///Save mPin(List<int>) and salt(String).
  ///mPin is in encrypted with AES-GCM form with key as SHA-256(mPin + Salt) and
  ///IV as salt.
  ///
  /// Note: salt is 96 bits long.
  static Future<void> setMPin(String mPin) async {
    //to generate a salt of 96 bits.
    final String salt = _randomString(6);
    final _rawKey = sha256.convert(utf8.encode(mPin + salt));
    final _algorithm = AesGcm.with256bits();
    final _key = await _algorithm.newSecretKeyFromBytes(_rawKey.bytes);
    final _mPin = await _algorithm.encrypt(
      utf8.encode(mPin),
      secretKey: _key,
      nonce: utf8.encode(salt),
    );

    final _box = Hive.box(auth);
    _box.put(_mPinKey, _mPin.cipherText);
    _box.put(_mPinSaltKey, salt);
    _box.put(_mPinMacKey, _mPin.mac.bytes);
  }

  static void clearMPin() {
    final _box = Hive.box(auth);
    _box.delete(_mPinKey);
    _box.delete(_mPinSaltKey);
  }

  ///[length] should be in terms of 16 bits.
  static String _randomString(int length) {
    var random = Random.secure();
    var values = List<int>.generate(length, (i) => random.nextInt(255));
    return base64UrlEncode(values);
  }
}
