import 'package:cryptography/cryptography.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:passman/extensions/extensions.dart';
import 'package:passman/objects/encrypted_object.dart';
import 'package:passman/objects/secret.dart';
import 'package:passman/utils/storage/super_secret_key.dart';

//Need to construct this class only after successful local login, therefore
//creating this as a singleton.
///This object will consist of all the secret keys in the encrypted form
///for encryption used to encrypt data, ex- passwords and notes, in this app.
///
/// Encryption of these keys will be done using AES-GCM-256 with a super secret
/// key securely stored according to the platform.
class Secrets {
  static const String boxName = 'secretsBox';

  ///Hive key for the record that contains the [_defaultSecretId] value in the
  ///box.
  static const String __defaultSecretIdKey = 'defaultSecretKey';
  static Secrets? _instance;

  ///This is the super secret key being used to encrypt all secrets.
  late final SuperSecret superSecret;
  final Box _box;

  Secrets._()
      : superSecret = getSuperSecret(),
        _box = Hive.box(boxName) {
    _defaultSecretId = _getDefaultSecretIdIfExists();
  }

  static Secrets get instance {
    if (_instance == null) _instance = Secrets._();

    return _instance!;
  }

  ///This is the Hive Key of the default Secret for the app, either been set
  ///by the user or automatically(i.e the first one in this case).
  String? _defaultSecretId;

  ///Will always return a default secret, if not exist then will generate one,
  ///in case there are no secrets in the local storage.
  ///
  /// To check if any secret exists in local storage check [totalSecrets].
  Future<Secret> get defaultSecret async {
    print("getting default secret id");
    if (_defaultSecretId != null) {
      final secret = await getSecret(_defaultSecretId!);
      if (secret != null) return secret;
      //if the secret at [_defaultSecretId] is corrupted than delete it.
      _box.delete(_defaultSecretId);
      //We are later re-assigning the value to [_defaultSecretId] so to
      //get next possible default value we have to delete current default id
      //from local storage too.
      _box.delete(__defaultSecretIdKey);

      //Now re-setting the [_defaultSecretId] value if any more possible.
      if (_getDefaultSecretIdIfExists() != _defaultSecretId) {
        _defaultSecretId = _getDefaultSecretIdIfExists();
        return defaultSecret;
      }
    }
    print("default secret id is null");

    _defaultSecretId = _getDefaultSecretIdIfExists();

    if (_defaultSecretId == null) {
      _defaultSecretId = await _addAndGenerateSecret();
      _box.put(__defaultSecretIdKey, _defaultSecretId);
    }

    return (await getSecret(_defaultSecretId!))!;
  }

  Future<Secret?> getSecret(String id) async {
    try {
      final encodedValueMap = _box.get(id);
      if (encodedValueMap == null) return null;

      return _convert(encodedValueMap);
    } catch (err) {
      print(
          "Looks like the secret is corrupted, will be automatically deleting it.");
      print(err);
      _box.delete(id);
      return null;
    }
  }

  Future<Map<String, Secret>> all() async {
    Map<String, Secret> res = {};
    List<Future> futures = [];
    _box.toMap().forEach((key, value) {
      if (key == __defaultSecretIdKey || value == null) return;
      futures.add((() async => res[key] = await _convert(value))());
    });
    await Future.wait(futures);
    return res;
  }

  Future<Secret> _convert(encodedValueMap) async {
    final encData =
        EncryptedObject.fromMap(Map<String, dynamic>.from(encodedValueMap));

    return Secret.fromMap(await encData.decryptToMap(
      Secret(bytes: await superSecret.value),
      force: true,
    ));
  }

  static String? _getDefaultSecretIdIfExists() {
    final box = Hive.box(boxName);
    //Here instead of typecasting with [String] we are typecasting with
    //[String?] as [box.get()] can also return null in case the key does not
    //exist.
    final defaultKey = box.get(__defaultSecretIdKey) as String?;
    if (defaultKey != null) return defaultKey;

    final key = box.keys.firstWhere(
      (key) => key != __defaultSecretIdKey,
      orElse: () => null,
    ) as String?;

    box.put(__defaultSecretIdKey, key);
    return key;
  }

  ///This function will take O(n) time to find totalSecrets.
  static int get totalSecrets {
    final box = Hive.box(boxName);
    int total = 0;
    box.toMap().forEach((key, value) {
      if (key != __defaultSecretIdKey && value != null) total++;
    });
    return total;
  }

  ///Generates a new secret and save the key in local storage.
  ///
  /// Returns the random-based key/id of the generated secret.
  ///
  /// Secret is generated for AES-GCM 256 bits Encryption Algorithm.
  Future<String> _addAndGenerateSecret() async {
    final algorithm = AesGcm.with256bits();
    final _secret = await (await algorithm.newSecretKey()).extractBytes();
    final secret = Secret(bytes: _secret);
    return add(secret);
  }

  Future<String> add(Secret secret) async {
    final encSecretObj = await EncryptedObject.create(
        secret.toString().codeUnits, Secret(bytes: await superSecret.value));

    await Hive.box(boxName).put(
      secret.id,
      encSecretObj.map,
    );

    return secret.id;
  }

  Future<void> remove(String id) => _box.delete(id);

  List<String> allSecretsIds({bool debug = false}) {
    final List<String> ids = [];
    _box.toMap().forEach((key, value) {
      if (debug) print("key: $key value: $value");
      if (key != __defaultSecretIdKey && value != null) ids.add(key);
    });
    return ids;
  }
}
