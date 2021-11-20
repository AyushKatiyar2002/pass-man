import 'package:passman/networks/share_secret.dart';

extension MapSharedKeyClone on Map<String, SharedKey> {
  Future<Map<String, SharedKey>> get clone async {
    Map<String, SharedKey> res = {};
    List<Future> _futures = [];
    this.forEach((key, value) =>
        _futures.add((() async => res[key] = await value.clone)()));
    await Future.wait(_futures);
    return res;
  }
}
