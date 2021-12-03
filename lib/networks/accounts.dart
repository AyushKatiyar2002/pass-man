import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:passman/extensions/encryption.dart';
import 'package:passman/networks/account_syncer.dart';
import 'package:passman/objects/account.dart';
import 'package:passman/objects/encrypted_object.dart';
import 'package:passman/utils/storage/secrets.dart';

///Before use check for internet connection, authentication and Also for the doc
///to exist.
class AccountsNetwork {
  static final _loggedOutException =
      PlatformException(code: 'NO_ACCOUNTS_LOGGED_OUT');

  static CollectionReference<Map<String, dynamic>> get _collection {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw _loggedOutException;

    return AccountSyncer.collection.doc(uid).collection('accounts');
  }

  static Future<Account?> account(String docId, String accountId) async =>
      values({
        docId: Set.from([accountId])
      }).then((res) => res[docId]);

  static Future<Map<String, Account?>> values(
      Map<String, Set<String>> accounts) async {
    Map<String, Account?> res = {};
    for (final key in accounts.keys) {
      final _doc = await doc(key);
      _doc.removeWhere((_key, value) => !accounts[key]!.contains(_key));
      res.addAll(_doc);
    }
    return res;
  }

  static Future<Map<String, Account?>> doc(String docId) =>
      _collection.doc(docId).get().then((snapshot) async {
        final _data = snapshot.data() ?? {};
        Map<String, Account?> res = {};
        for (final key in _data.keys)
          res[key] = await _convert(Map<String, dynamic>.from(_data[key]!));
        return res;
      });

  ///Can be used for add, edit and delete operations. To delete an account
  ///set the value as null in [encObjs].
  ///
  ///Here, [format] will be the format received at the beginning of the
  ///transaction, this is to check whether the docId already exists or not, and
  ///perform update accordingly.
  static void update(String docId, Map<String, EncryptedObject?> encObjs,
      Transaction transaction, Map<String, List<String>> format) {
    Map<String, dynamic> toUpdate = {};
    for (final key in encObjs.keys) {
      if (encObjs[key] == null)
        toUpdate[key] = FieldValue.delete();
      else
        toUpdate[key] = encObjs[key]?.map;
    }
    if (format.containsKey(docId)) {
      transaction.update(_collection.doc(docId), toUpdate);
      return;
    }
    //remove null values before setting the document
    for (final key in encObjs.keys) {
      if (encObjs[key] == null) toUpdate.remove(key);
    }
    transaction.set(_collection.doc(docId), toUpdate);
  }

  static Future<Account?> _convert(Map<String, dynamic> _encryptedMap) async {
    final encObj = EncryptedObject.fromMap(_encryptedMap);
    final secret = await Secrets.instance.getSecret(encObj.secretId);
    if (secret == null) return null;
    final _map = await encObj.decryptToMap(secret);
    return Account.fromMap(_map);
  }
}
