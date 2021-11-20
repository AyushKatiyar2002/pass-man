import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/extensions/encryption.dart';
import 'package:passman/objects/account.dart';
import 'package:passman/objects/encrypted_object.dart';
import 'package:passman/utils/utils.dart';

typedef AccountProvider
    = AutoDisposeStateNotifierProvider<AccountNotifier, Account>;
typedef AccountsListProvider = AutoDisposeChangeNotifierProvider<AccountsList>;

class AccountsList extends ChangeNotifier {
  final Map<String, AccountProvider> accounts = {};
  final Map<String, EncryptedObject> encObjs;

  static AutoDisposeChangeNotifierProvider<AccountsList>? _provider;

  AccountsList._(
    List<Account> accounts, {
    Map<String, EncryptedObject>? encObjs,
  }) : this.encObjs = encObjs ?? {} {
    accounts.forEach((account) => add(
          account,
          notify: false,
          onlyInMemory: true,
        ));
    print('unDecrypted Accounts: ${this.encObjs.length}');
  }

  static Future<AccountsListProvider> get provider async {
    if (_provider == null) {
      final List<Account> accounts = [];
      final Map<String, EncryptedObject> encObjs = {};
      final _data = Database.instance.data;
      _data.removeWhere((key, elem) => elem.type != Account.typeName);

      // print('total secrets: ${Secrets.instance.allSecretsIds(debug: true)}');
      for (final key in _data.keys) {
        final elem = _data[key]!;
        // print('secret id: ${elem.secretId}');

        final secret = await Secrets.instance.getSecret(elem.secretId);
        if (secret == null) {
          encObjs[key] = elem;
          continue;
        }

        try {
          accounts.add(Account.fromMap(await elem.decryptToMap(secret)));
        } catch (err) {
          print('cannot initialize account: $key');
          print('err: $err');
          encObjs[key] = elem;
        }
      }

      _provider = ChangeNotifierProvider.autoDispose(
          (ref) => AccountsList._(accounts, encObjs: encObjs));
    }

    return _provider!;
  }

  void add(
    Account account, {
    bool notify = true,
    bool onlyInMemory = false,
  }) {
    assert(
        !accounts.containsKey(account.uuid), 'Same id password already exists');

    if (!onlyInMemory)
      account.uploadToDatabase().catchError((err) {
        print(err);
        remove(account, completeDelete: true);
      });
    accounts[account.uuid] =
        StateNotifierProvider.autoDispose<AccountNotifier, Account>(
      (ref) => AccountNotifier(account),
    );
    print("Account Added!");
    if (notify) notifyListeners();
  }

  void addEncObjs(String id, EncryptedObject encObj) {
    if (encObjs.containsKey(id)) return;
    encObjs[id] = encObj;
  }

  Future<void> reloadEncObjs() async {
    bool notify = false;

    for (final key in encObjs.keys) {
      try {
        final value = encObjs[key]!;
        final secret = await Secrets.instance.getSecret(value.secretId);
        if (secret == null) continue;

        final account = Account.fromMap(await value.decryptToMap(secret));
        encObjs.remove(key);
        add(account, notify: false);
        notify = true;
      } catch (err) {
        print('Cannot decrypt on reload for key: $key');
        print('err: $err');
      }
    }

    if (notify) notifyListeners();
  }

  void remove(Account account, {bool completeDelete = false}) {
    Database.instance
        .delete(account.uuid, completeDelete: completeDelete)
        .catchError((err) {
      print(err);
      add(account);
    });
    accounts.remove(account.uuid);
    print("Account Removed!");
    notifyListeners();
  }
}
