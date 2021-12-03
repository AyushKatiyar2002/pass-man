import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:passman/networks/account_syncer.dart';

class DeletedNetworks {
  static final _loggedOutException =
      PlatformException(code: 'NO_FORMAT_LOGGED_OUT');

  static DocumentReference<Map<String, dynamic>> get _doc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw _loggedOutException;

    return AccountSyncer.collection.doc('$uid/${AccountSyncer.utilsSubCol}/deleted');
  }

  ///Check if the Changes Deleted Doc exists and if not creates one.
  static Future<void> initialize() async {
    final snapshot = await _doc.get();
    if (snapshot.data() == null) await _doc.set({});
  }

  static Future<Map<String, DateTime>> get data =>
      _doc.get().then((value) => Map<String, DateTime>.from((value.data() ?? {})
          .map((key, value) => MapEntry(key, DateTime.parse(value)))));

  static Future<DateTime?> account(String id) => data.then((_map) => _map[id]);

  ///Can be used for add, edit and delete operations. For delete set value for
  ///the respective key to null in [map].
  static void update(Map<String, DateTime?> map, Transaction transaction) {
    Map<String, dynamic> res = {};
    for (final key in map.keys) {
      if (map[key] == null)
        res[key] = FieldValue.delete();
      else
        res[key] = map[key]?.toIso8601String();
    }
    transaction.update(_doc, res);
  }
}
