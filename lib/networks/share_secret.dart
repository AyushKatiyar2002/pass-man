import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/networks/secrets.dart';
import 'package:passman/objects/encrypted_object.dart';
import 'package:passman/objects/secret.dart';
import 'package:passman/utils/utils.dart';
import 'package:uuid/uuid.dart';

import 'account_syncer.dart';

class SharedKey {
  final String deviceId;
  final List<int> publicKey;
  final Future<List<int>> bytes;
  final DateTime created;
  final DateTime updated;

  SharedKey(
      {String? id,
      required this.publicKey,
      Future<List<int>>? bytes,
      DateTime? created,
      DateTime? updated})
      : this.deviceId = id ?? Uuid().v1(),
        this.bytes = bytes ?? Future.value(publicKey),
        this.created = created ?? updated ?? DateTime.now(),
        this.updated = updated ?? created ?? DateTime.now();

  factory SharedKey.fromMap(Map<String, dynamic> map,
      [Future<List<int>> Function(List<int> publicKey)? bytes]) {
    final publicKey = List<int>.from(map['publicKey']);
    final _bytes = (map['bytes'] != null)
        ? Future.value(List<int>.from(map['bytes']))
        : null;

    return SharedKey(
        id: map['id'],
        publicKey: publicKey,
        bytes: _bytes ?? (bytes ?? (_) => Future.value([]))(publicKey),
        created: DateTime.tryParse(map['created'] ?? ''),
        updated: DateTime.tryParse(map['updated'] ?? ''));
  }

  Map<String, dynamic> get map => {
        'id': deviceId,
        'publicKey': publicKey,
        'created': created.toIso8601String(),
        'updated': updated.toIso8601String(),
      };

  Future<Map<String, dynamic>> get fullMap async =>
      map..['bytes'] = await bytes;

  Future<SharedKey> get clone async => SharedKey.fromMap(await fullMap);
}

///Share Secret Network object is used to share your public secret on firestore
///database.
class SSNetwork extends ChangeNotifier {
  static final _firestore = FirebaseFirestore.instance;

  static final _loggedOutException =
      PlatformException(code: 'NO_FORMAT_LOGGED_OUT');

  static DocumentReference<Map<String, dynamic>> get _doc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw _loggedOutException;

    return AccountSyncer.collection
        .doc('$uid/${AccountSyncer.utilsSubCol}/shared_secrets');
  }

  static SSNetwork? _instance;
  static AutoDisposeChangeNotifierProvider<SSNetwork>? _provider;

  late final SimpleKeyPair keyPair;
  final Map<String, SharedKey> updatedSharedKeys = {}, allSharedKeys = {};
  StreamSubscription? _subscription;
  bool initialized = false;

  SSNetwork._();

  static AutoDisposeChangeNotifierProvider<SSNetwork> get instance {
    if (_provider == null)
      _provider = ChangeNotifierProvider.autoDispose((ref) {
        if (_instance == null) _instance = SSNetwork._();

        return _instance!;
      });

    return _provider!;
  }

  ///Should be called on logout only
  Future<void> cancel() async {
    await _subscription?.cancel();
    _instance = null;
  }

  Future<void> initialize() async {
    if (initialized) return;
    final algorithm = X25519();

    final keyPair = await algorithm.newKeyPair();
    this.keyPair = keyPair;

    final publicKey = await keyPair.extractPublicKey();

    if ((await _doc.get()).data() == null) await _doc.set({});

    await _firestore.runTransaction((transaction) async {
      _update(publicKey.bytes, transaction);
      SecretsNetwork.clear(transaction);
    });

    initialized = true;
    _sync();
  }

  static void _update(List<int> publicKey, Transaction transaction) =>
      transaction.update(_doc, {
        AuthStorage.deviceId: SharedKey(
          id: AuthStorage.deviceId,
          publicKey: publicKey,
        ).map,
      });

  static Stream<Map<String, dynamic>> get _stream =>
      _doc.snapshots().map((snapshot) => (snapshot.data() ?? {}));

  void _sync() {
    _subscription = _stream.listen((values) async {
      updatedSharedKeys.clear();
      // print('Our Device Id: ${AuthStorage.deviceId}');

      //adding or updating local shared keys
      values.forEach((key, value) {
        final sharedKey =
            SharedKey.fromMap(Map<String, dynamic>.from(value), _getSharedKey);

        final _listIsEq = ListEquality().equals;

        if (key == AuthStorage.deviceId) return;

        // print(
        //     'device id: $key shared key: ${sharedKey.publicKey.sublist(0, 5)}');

        if (!_listIsEq(sharedKey.publicKey, allSharedKeys[key]?.publicKey)) {
          updatedSharedKeys[key] = sharedKey;
          allSharedKeys[key] = sharedKey;
        }
      });

      if (updatedSharedKeys.isNotEmpty) notifyListeners();
    });
  }

  Future<List<int>> _getSharedKey(final List<int> remotePubicKey) async =>
      X25519()
          .sharedSecretKey(
            keyPair: keyPair,
            remotePublicKey:
                SimplePublicKey(remotePubicKey, type: KeyPairType.x25519),
          )
          .then((key) => key.extractBytes());

  Future<Set<String>> get toSetDocs async {
    final List<Future> futures = [];
    final res = Set<String>();

    updatedSharedKeys.forEach((deviceId, value) {
      futures.add((() async {
        final value = await SecretsNetwork.getDocRef(deviceId).get();
        if (value.data() == null) res.add(deviceId);
      })());
    });

    await Future.wait(futures);
    return res;
  }

  Future<void> upload(Transaction transaction, Set<String> toSet,
      Map<String, SharedKey> sharedKeys) async {
    final secrets = await Secrets.instance.all();
    // print('upload secret key, shared keys: ${sharedKeys.length}');
    // print('secrets length: ${secrets.length}');

    for (final deviceId in sharedKeys.keys) {
      final secretKey = sharedKeys[deviceId]!;

      Map<String, Map<String, dynamic>> toUpdate = {};
      final sharedSecret =
          Secret(bytes: (await Sha256().hash(await secretKey.bytes)).bytes);

      for (final key in secrets.keys) {
        final value = secrets[key]!;

        toUpdate[AuthStorage.deviceId] = (await EncryptedObject.create(
                value.toString().codeUnits, sharedSecret,
                created: value.created, updated: value.updated))
            .map;
      }

      if (toSet.contains(deviceId))
        transaction.update(SecretsNetwork.getDocRef(deviceId), toUpdate);
      else
        transaction.set(SecretsNetwork.getDocRef(deviceId), toUpdate);
    }
  }
}
