import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/extensions/extensions.dart';
import 'package:passman/networks/secrets.dart';
import 'package:passman/networks/share_secret.dart';
import 'package:passman/objects/accounts_list.dart';
import 'package:passman/objects/encrypted_object.dart';
import 'package:passman/utils/utils.dart';

class SecretSyncer {
  final AutoDisposeProviderRef _ref;
  Map<String, SecretKey> sharedSecrets;
  StreamSubscription? _subscription;

  static SecretSyncer? _instance;
  static AutoDisposeProvider<SecretSyncer>? _provider;

  SecretSyncer._(this._ref, {Map<String, SecretKey>? sharedSecrets})
      : sharedSecrets = sharedSecrets ?? {} {
    _sync();
  }

  static Future<AutoDisposeProvider<SecretSyncer>> get instance async {
    if (_provider == null) {
      _provider = Provider.autoDispose((ref) {
        if (_instance == null) _instance = SecretSyncer._(ref);

        return _instance!;
      });
    }

    return _provider!;
  }

  ///Should only be called on logout
  Future<void> dispose() async {
    await Future.wait([
      _subscription?.cancel() ?? Future.value(null),
      _ref.read(SSNetwork.instance).cancel(),
    ]);

    _instance = null;
  }

  void _sync() async {
    print('secret syncer started');
    Map<String, EncryptedObject> secretsMap = {};
    SSNetwork ssNetwork = _ref.read(SSNetwork.instance)..initialize();

    _subscription = SecretsNetwork.stream.listen((_secretsMap) {
      var _update = false;
      for (final key in _secretsMap.keys) {
        final value = _secretsMap[key]!;

        if (secretsMap.containsKey(key) &&
            secretsMap[key]!.updated == value.updated) continue;

        _update = true;
        break;
      }
      secretsMap.removeWhere((key, value) => !_secretsMap.containsKey(key));
      if (!_update) return;
      print('received_secrets updated');
      print('total received_secrets: ${_secretsMap.length}');
      secretsMap = _secretsMap;
      __sync(ssNetwork, secretsMap);
    });

    _ref.listen(SSNetwork.instance, (SSNetwork _ssNetwork) async {
      print('shared keys updated');
      print('total shared keys: ${ssNetwork.updatedSharedKeys.length}');
      ssNetwork = _ssNetwork; //probably is a useless line
      __sync(ssNetwork, secretsMap);
    });
  }

  Future<void> __sync(
      SSNetwork ssNetwork, Map<String, EncryptedObject> secretsMap) async {
    final sharedKeys = await ssNetwork.updatedSharedKeys.clone;
    await _toLocal(sharedKeys, secretsMap);
    // print('performed to local secrets sync');
    _toOnline(ssNetwork, sharedKeys);
    // print('performed to online secrets sync');
    _ref.read(await AccountsList.provider).reloadEncObjs();
  }

  Future<void> _toLocal(
    Map<String, SharedKey> sharedKeys,
    Map<String, EncryptedObject> secretsMap,
  ) async {
    final secrets = await SecretsNetwork.convert(secretsMap, sharedKeys);

    final List<Future> futures = [];

    for (final key in secrets.keys) {
      final value = secrets[key]!;

      final secret = await Secrets.instance.getSecret(value.id);
      if (secret != null) return;
      futures.add(Secrets.instance.add(value));
    }

    await Future.wait(futures);
  }

  Future<void> _toOnline(
      SSNetwork ssNetwork, Map<String, SharedKey> sharedKeys) async {
    final toSetDocs = await ssNetwork.toSetDocs;
    await FirebaseFirestore.instance.runTransaction(
        (transaction) => ssNetwork.upload(transaction, toSetDocs, sharedKeys));
  }
}
