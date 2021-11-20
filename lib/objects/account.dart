import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/extensions/encryption.dart';
import 'package:passman/utils/utils.dart';
import 'package:uuid/uuid.dart';

class Account {
  static final __uuid = Uuid();
  static const typeName = 'account';

  Account({
    String? uuid,
    required this.url,
    required this.username,
    required this.password,
    DateTime? created,
    DateTime? updated,
    this.description = '',
  })  : assert(url.isNotEmpty && username.isNotEmpty && password.isNotEmpty),
        this.uuid = uuid ?? __uuid.v4(),
        created = created ?? updated ?? DateTime.now(),
        updated = updated ?? created ?? DateTime.now();

  factory Account.fromMap(Map<String, dynamic> _map) {
    assert(
        _map['uuid'] != null &&
            _map['url'] != null &&
            _map['username'] != null &&
            _map['password'] != null &&
            _map['updated'] != null,
        'SOME REQUIRED FIELD IS NULL');

    final created = DateTime.tryParse(_map['created'] ?? _map['updated'] ?? '');
    final updated = DateTime.tryParse(_map['updated']) ?? created;

    assert(updated != null, 'CORRUPTED TIMESTAMP');

    return Account(
      uuid: _map['uuid'],
      url: _map['url'],
      username: _map['username'],
      password: _map['password'],
      description: _map['description'] ?? '',
      created: created ?? updated,
      updated: updated,
    );
  }

  static Account get dummy => Account(
        username: 'dummy username',
        url: 'dummy url',
        password: 'dummy password',
      );

  final String uuid;
  final String url;
  final String username;
  final String password;
  final String description;
  final DateTime created;
  final DateTime updated;

  @override
  bool operator ==(Object other) =>
      other is Account &&
      other.runtimeType == runtimeType &&
      other.toString() == toString();

  @override
  int get hashCode => toString().hashCode;

  Map<String, String> get map => {
        'uuid': uuid,
        'url': url,
        'username': username,
        'password': password,
        'description': description,
        'created': created.toIso8601String(),
        'updated': updated.toIso8601String(),
      };

  @override
  String toString() => jsonEncode(map);

  Future<void> uploadToDatabase() async {
    await Database.instance.upload(await map.toEncObj(Account.typeName), uuid);
    await Deleted.instance.delete(uuid);
  }
}

class AccountNotifier extends StateNotifier<Account> {
  AccountNotifier(Account account) : super(account);

  AccountNotifier.fromMap(Map<String, String> map)
      : super(Account.fromMap(map));

  void update(Account account) {
    assert(account.uuid == state.uuid, 'Not same passwords');

    final temp = state.map;

    account
        .uploadToDatabase()
        .catchError((err) => state = Account.fromMap(temp));

    state = account;
  }
}
