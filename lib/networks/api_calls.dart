import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

abstract class Api {
  static Future<bool> isStrong(String password) async {
    final url = 'https://passwordstrengthiss.herokuapp.com/psiss/score';
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{'password': password}),
    );

    final body = jsonDecode(res.body);

    if (res.statusCode == 200) return body['score'] > 2;

    print(body);

    throw PlatformException(code: 'ERROR');
  }

  static Future<List<String>> logo(String url) async {
    final httpCallUrl =
        'https://mycorsproxy-iss.herokuapp.com/https://logo-extractor-232.herokuapp.com/allicons.json?url=$url';

    final res =
        await http.get(Uri.parse(httpCallUrl), headers: {'origin': 'true'});

    final body = jsonDecode(res.body);

    if (res.statusCode == 200) {
      List<String> res = [];
      for (final elem in body['icons']) res.add(elem['url']);
      return res;
    }

    throw PlatformException(code: 'ERROR');
  }
}
