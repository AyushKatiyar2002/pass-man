import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:passman/objects/secret.dart';

///This will be our common Encrypted Object which we will use to store
///different object maps' json encoded strings.
class EncryptedObject {
  static final defaultCipher = AesGcm.with256bits();

  ///This will be our encrypted value
  final SecretBox secretBox;
  final String secretId;
  final String? type;
  final Cipher cipher;
  final DateTime created, updated;

  EncryptedObject({
    required this.secretBox,
    required this.secretId,
    this.type,
    Cipher? cipher,
    DateTime? created,
    DateTime? updated,
  })  : this.cipher = defaultCipher,
        this.created = created ?? updated ?? DateTime.now(),
        this.updated = updated ?? created ?? DateTime.now();

  factory EncryptedObject.fromMap(Map<String, dynamic> map) => EncryptedObject(
        secretBox: SecretBox(
          List<int>.from(map['value']),
          nonce: List<int>.from(map['nonce']),
          mac: Mac(List<int>.from(map['mac'])),
        ),
        secretId: map['secretId'],
        cipher: getCipherFromString(map['cipher']),
        type: map['type'],
        created: DateTime.tryParse(map['created'] ?? ''),
        updated: DateTime.tryParse(map['updated'] ?? ''),
      );

  factory EncryptedObject.dummy() => EncryptedObject(
      secretBox: SecretBox([], nonce: [], mac: Mac([])), secretId: '');

  static Cipher? getCipherFromString(String? text) {
    if (text?.substring(0, 6) == 'AesGcm') return AesGcm.with256bits();
  }

  static Future<EncryptedObject> create(List<int> value, Secret secret,
      {Cipher? cipher,
      String? type,
      DateTime? created,
      DateTime? updated}) async {
    Cipher _cipher = cipher ?? defaultCipher;
    final secretBox = await _cipher.encrypt(
      value,
      secretKey: SecretKey(secret.bytes),
      nonce: _cipher.newNonce(),
    );

    return EncryptedObject(
      secretBox: secretBox,
      cipher: _cipher,
      secretId: secret.id,
      type: type,
      created: created,
      updated: updated,
    );
  }

  Future<List<int>> decryptData(Secret secret, {bool force = false}) async {
    if (secret.id != secretId && !force)
      throw PlatformException(code: "WRONG_SECRET");
    final data = await cipher.decrypt(
      secretBox,
      secretKey: SecretKey(secret.bytes),
    );
    return data;
  }

  Map<String, dynamic> get map => {
        'value': secretBox.cipherText,
        'nonce': secretBox.nonce,
        'mac': secretBox.mac.bytes,
        'secretId': secretId,
        'cipher': cipher.toString(),
        'type': type,
        'updated': updated.toIso8601String(),
        'created': created.toIso8601String(),
      };
}
