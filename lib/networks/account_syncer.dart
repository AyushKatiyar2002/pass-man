import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/networks/accounts.dart';
import 'package:passman/networks/changes.dart';
import 'package:passman/networks/deleted.dart';
import 'package:passman/networks/format.dart';
import 'package:passman/objects/accounts_list.dart';
import 'package:passman/objects/encrypted_object.dart';
import 'package:passman/utils/storage/deleted.dart';
import 'package:passman/utils/utils.dart';

class AccountSyncer {
  static final collection = FirebaseFirestore.instance.collection('data');
  static const utilsSubCol = 'utils';
  static const _delayDuration = Duration(milliseconds: 500);
  static const _maxDelayTimeoutCount = 5;

  final AutoDisposeProviderRef _ref;
  bool syncRunning = false;
  StreamSubscription? _subscription;

  static AccountSyncer? _instance;
  static AutoDisposeProvider<AccountSyncer>? _provider;

  AccountSyncer._(this._ref) {
    sync();
  }

  static Future<AutoDisposeProvider<AccountSyncer>> get instance async {
    if (_provider == null) {
      if (_instance == null) {
        await Future.wait([
          Changes.initialize(),
          Format.initialize(),
          DeletedNetworks.initialize(),
        ]);
      }
      _provider = Provider.autoDispose((ref) {
        if (_instance == null) _instance = AccountSyncer._(ref);
        return _instance!;
      });
    }

    return _provider!;
  }

  ///Should be called on logout only
  Future<void> dispose() async {
    await _subscription?.cancel();
    _instance = null;
  }

  void sync() {
    print("initialized sync");
    _subscription = Changes.stream.listen((changes) async {
      print("New Online Changes Available");
      final deletedOnline = DeletedNetworks.data;
      _ref.listen(await AccountsList.provider,
          (AccountsList accountsList) async {
        print("Accounts List Updated");
        _performSync(changes, accountsList, deletedOnline);
      }, fireImmediately: true);
    });
  }

  Future<void> _performSync(
      Map<String, DateTime> changes,
      AccountsList accountsList,
      Future<Map<String, DateTime>> deletedOnline) async {
    if (syncRunning) return;
    print('performing sync iteration');
    syncRunning = true;

    final accounts = accountsList.accounts;
    final List<String> toLocal = [], toOnline = [];
    final visitedAccounts = Set<String>();
    int delayCount = 0;

    for (final key in changes.keys) {
      visitedAccounts.add(key);
      final provider = accounts[key];
      if (provider == null) {
        if ((await deletedOnline).containsKey(key)) continue;
        var deletedTime = Deleted.instance.find(key);
        for (;
            delayCount < _maxDelayTimeoutCount && deletedTime == null;
            delayCount++) {
          await Future.delayed(_delayDuration);
          deletedTime = Deleted.instance.find(key);
        }
        if (deletedTime == null || changes[key]!.isAfter(deletedTime))
          toLocal.add(key);
        else
          toOnline.add(key);
        continue;
      }

      final account = _ref.read(provider);
      // print(
      //     'key: $key updated: ${account.updated} last changed: ${changes[key]}');
      if (changes[key]!.isAfter(account.updated))
        toLocal.add(key);
      else if (account.updated.isAfter(changes[key]!)) toOnline.add(key);
    }

    accounts.forEach((key, value) {
      if (visitedAccounts.contains(key)) return;
      toOnline.add(key);
    });

    final format = Format.value();
    await Future.wait([
      _syncToLocal(toLocal, deletedOnline, format),
      _syncToOnline(toOnline, format)
    ]);

    print('completing sync iteration');
    syncRunning = false;
    await Future.delayed(Duration(minutes: 1));
    if (syncRunning) return;
    _performSync(
      await Changes.value,
      _ref.read(await AccountsList.provider),
      DeletedNetworks.data,
    );
  }

  Future<void> _syncToLocal(
    List<String> keys,
    Future<Map<String, DateTime>> _deletedOnline,
    Future<Map<String, List<String>>> _format,
  ) async {
    print("performing sync to local: ${keys.length}");
    final deletedOnline = await _deletedOnline;
    final format = Format.toAccountIdDocId(await _format);
    final accountsList = _ref.read(await AccountsList.provider);
    Map<String, Set<String>> accountsToGet = {};
    for (final key in keys) {
      if (deletedOnline.containsKey(key)) {
        final accProvider = accountsList.accounts[key];
        if (accProvider == null) continue;
        accountsList.remove(_ref.read(accProvider));
        continue;
      }
      final docId = format[key];
      if (docId == null) continue;
      accountsToGet[docId] = (accountsToGet[docId] ?? Set())..add(key);
    }

    final accounts = await AccountsNetwork.values(accountsToGet);
    accounts.forEach((key, value) {
      if (value == null) return;
      if (accountsList.accounts[key] == null) {
        accountsList.add(value);
        return;
      }
      _ref.read(accountsList.accounts[key]!.notifier).update(value);
    });
  }

  Future<void> _syncToOnline(
    List<String> keys,
    Future<Map<String, List<String>>> _format,
  ) async {
    print('performing sync to online: ${keys.length}');
    final _accountsList = _ref.read(await AccountsList.provider);
    final toUpdateChanges = Map<String, DateTime>();
    final toUpdateFormat = Map<String, bool>();
    final toUpdateDelete = Map<String, DateTime?>();
    final accounts = Map<String, EncryptedObject?>();
    int delayCount = 0;

    final _delete = (String key, DateTime deletedTime) {
      toUpdateDelete[key] = deletedTime;
      toUpdateChanges[key] = deletedTime;
      toUpdateFormat[key] = true;
    };

    for (final key in keys) {
      var deletedTime = Deleted.instance.find(key);
      if (deletedTime != null) {
        _delete(key, deletedTime);
        continue;
      }
      toUpdateFormat[key] = false;
      toUpdateDelete[key] = null;
      final accProvider = _accountsList.accounts[key];
      if (accProvider == null) {
        for (;
            delayCount < _maxDelayTimeoutCount && deletedTime == null;
            delayCount++) {
          await Future.delayed(_delayDuration);
          deletedTime = Deleted.instance.find(key);
        }
        if (deletedTime == null)
          throw PlatformException(code: 'ACCOUNT_NOT_IN_DELETED');
        _delete(key, deletedTime);
        continue;
      }
      final account = _ref.read(accProvider);
      toUpdateChanges[key] = account.updated;
      var encObj = Database.instance.data[key];
      if (encObj == null) {
        for (;
            delayCount < _maxDelayTimeoutCount && encObj == null;
            delayCount++) {
          await Future.delayed(_delayDuration);
          encObj = Database.instance.data[key];
        }
        if (encObj == null)
          throw PlatformException(code: 'ACCOUNT_NOT_IN_DATABASE');
      }
      accounts[key] = encObj;
    }

    FirebaseFirestore.instance.runTransaction((transaction) async {
      Changes.update(toUpdateChanges, transaction);
      DeletedNetworks.update(toUpdateDelete, transaction);
      final docIds = Format.update(toUpdateFormat, transaction, await _format);
      final Map<String, Map<String, EncryptedObject?>> toUpdateAccounts = {};
      docIds.forEach((key, value) {
        final encObj = toUpdateFormat[key]! ? null : accounts[key]!;
        if (toUpdateAccounts[value] == null) toUpdateAccounts[value] = {};
        toUpdateAccounts[value]![key] = encObj;
      });
      for (final key in toUpdateAccounts.keys) {
        AccountsNetwork.update(
            key, toUpdateAccounts[key]!, transaction, await _format);
      }
    });
  }
}
