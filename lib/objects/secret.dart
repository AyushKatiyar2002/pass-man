import 'dart:convert';

import 'package:uuid/uuid.dart';

class Secret {
  final List<int> bytes;
  final String id;
  final DateTime created;
  final DateTime updated;

  Secret({
    String? id,
    required this.bytes,
    DateTime? created,
    DateTime? updated,
  })  : this.id = id ?? Uuid().v4(),
        this.created = created ?? DateTime.now(),
        this.updated = updated ?? DateTime.now();

  factory Secret.fromMap(Map<String, dynamic> map) {
    return Secret(
      id: map['id'],
      bytes: List<int>.from(map['bytes']),
      created: DateTime.tryParse(map['created'] ?? ''),
      updated: DateTime.tryParse(map['updated'] ?? ''),
    );
  }

  Map<String, dynamic> get map => {
        'id': id,
        'bytes': bytes,

        //here we are converting dateTimes to strings due to the different ways the
        //Hive and Firebase handle saving dateTime.
        //Also jsonDecode does not work with DateTime.
        'created': created.toIso8601String(),
        'updated': updated.toIso8601String(),
      };

  String toString() => jsonEncode(map);
}
