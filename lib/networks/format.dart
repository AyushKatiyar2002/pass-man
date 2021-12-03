import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:passman/networks/account_syncer.dart';
import 'package:uuid/uuid.dart';

///These functions are only to be used before checking that you are logged in
///and are connected to the internet.
///
///Make sure that the format exists before using any other functions.
abstract class Format {
  static final _loggedOutException =
      PlatformException(code: 'NO_FORMAT_LOGGED_OUT');

  static DocumentReference<Map<String, dynamic>> get _doc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw _loggedOutException;

    return AccountSyncer.collection.doc('$uid/${AccountSyncer.utilsSubCol}/format');
  }

  ///Check if the format doc exists and if not creates one.
  static Future<void> initialize() async {
    final snapshot = await _doc.get();
    if (snapshot.data() == null) await _doc.set({});
  }

  static Stream<Map<String, List<String>>> get stream {
    return _doc.snapshots().map((snapshot) {
      final data = snapshot.data();
      return _converter(data ?? {});
    });
  }

  static Future<Map<String, List<String>>> value(
      [Transaction? transaction]) async {
    final _convert = (snapshot) => _converter(snapshot.data() ?? {});

    if (transaction != null) {
      return transaction.get(_doc).then(_convert);
    }
    return _doc.get().then(_convert);
  }

  static Map<String, String> toAccountIdDocId(
      Map<String, List<String>> format) {
    Map<String, String> res = {};
    format.forEach((key, values) => values.forEach((val) => res[val] = key));
    return res;
  }

  static Map<String, List<String>> _converter(Map<String, dynamic> _map) {
    Map<String, List<String>> res = {};
    _map.forEach((key, val) => res[key] = List<String>.from(val));
    return res;
  }

  ///This function can be used to perform add, edit and delete all of them.
  ///
  /// In parameter [fileIds], provide a map where key will be the fileIds and
  /// the boolean value would be to delete or not the item.
  ///
  ///Here since we need to provide the [format] gotten using transaction, as in
  ///case of transaction we need to perform all read operations first, therefore
  ///they cannot be performed inside a same function.
  ///
  /// This function returns the [docId] used. This is helpful to get the
  /// auto selected value of [docId] used by the function.
  static Map<String, String> update(
    final Map<String, bool> fileIds,
    final Transaction transaction,
    final Map<String, List<String>> _format, {
    final int maxElementsInDoc = 20,
  }) {
    final format = deepClone(_format);
    final Map<String, List<String>> toUpdate = {};
    final Map<String, bool> done =
        fileIds.map((key, value) => MapEntry(key, false));
    final Map<String, String> docIds = {};
    List<List<dynamic>> lengths = [];

    for (final key in format.keys) {
      List<String> idsFound = [];
      int total = format[key]!.fold(0, (previousValue, element) {
        if (fileIds.containsKey(element)) {
          previousValue++;
          if (!done[element]!) {
            if (!fileIds[element]!) idsFound.add(element);

            docIds[element] = key;
            done[element] = true;
          }
        }
        return previousValue;
      });

      if (total > 0)
        format[key] = format[key]!
            .where((elem) => !fileIds.containsKey(elem))
            .toList()
          ..addAll(idsFound);

      toUpdate[key] = format[key]!;
      lengths.add([key, format[key]!.length]);
    }
    lengths.sort((first, second) => first[1].compareTo(second[1]));

    int i = 0;
    outerLoop:
    for (final key in done.keys) {
      if (done[key]!) continue;
      if (fileIds[key]!) continue;
      while (true) {
        while (i < lengths.length) {
          if (lengths[i][1] < maxElementsInDoc) {
            lengths[i][1]++;
            toUpdate[lengths[i][0]] = (toUpdate[lengths[i][0]] ?? [])..add(key);
            docIds[key] = lengths[i][0];
            continue outerLoop;
          }
          i++;
        }
        lengths.add([Uuid().v1(), 0]);
      }
    }

    transaction.update(_doc, toUpdate);
    return docIds;
  }

  static Map<String, List<String>> deepClone(Map<String, List<String>> format) {
    Map<String, List<String>> res = {};
    format.forEach((key, value) => res[key] = List<String>.from(value));
    return res;
  }
}
