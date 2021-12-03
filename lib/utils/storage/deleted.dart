import 'package:hive_flutter/hive_flutter.dart';

///This box will contain all the deleted records uuids NOT encrypted.
///
///Note: These ids are/(should be) completely
///random, i.e not related with the actual content of records in anyway.
class Deleted {
  static const String boxName = 'deletedRecordsBox';
  static Deleted? _instance;

  Deleted._();

  static Deleted get instance {
    if (_instance == null) _instance = Deleted._();

    return _instance!;
  }

  DateTime? find(String id) => Hive.box(boxName).get(id) as DateTime?;

  Future<void> upload(String id, [DateTime? dateTime]) =>
      Hive.box(boxName).put(id, dateTime ?? DateTime.now());

  Future<void> delete(String id) => Hive.box(boxName).delete(id);
}
