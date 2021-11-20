import 'package:cryptography/cryptography.dart';

void main() async {
  final algo = X25519();
  final firstKeyPair = await algo.newKeyPair();
  final secondKeyPair = await algo.newKeyPair();

  final sharedKey = await algo.sharedSecretKey(
    keyPair: firstKeyPair,
    remotePublicKey: SimplePublicKey(
        (await secondKeyPair.extractPublicKey()).bytes,
        type: KeyPairType.x25519),
  );

  print('shared key: ${(await sharedKey.extract()).bytes}');
}
