import 'dart:convert';

import 'package:passman/objects/encrypted_object.dart';
import 'package:passman/objects/secret.dart';
import 'package:passman/utils/utils.dart';

extension MapEncObj on Map<String, dynamic> {
  Future<EncryptedObject> toEncObj([String? type]) async {
    final secret = await Secrets.instance.defaultSecret;
    print("Used secret id for encryption: ${secret.id}");
    return await EncryptedObject.create(
      jsonEncode(this).codeUnits,
      secret,
      type: type,
    );
  }
}

extension EncObjMap on EncryptedObject {
  Future<Map<String, dynamic>> decryptToMap(Secret secret,
      {bool force = false}) async {
    final data = await this.decryptData(secret, force: force);
    return Map<String, dynamic>.from(jsonDecode(String.fromCharCodes(data)));
  }
}
