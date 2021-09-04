import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

void initDynamicLinks() async {
  FirebaseDynamicLinks.instance.onLink(onSuccess: (dynamicLink) async {
    final deepLink = dynamicLink?.link;
    manageDeepLink(deepLink);
  }, onError: (OnLinkErrorException e) async {
    print('onLinkError');
    print(e.message);
  });

  final data = await FirebaseDynamicLinks.instance.getInitialLink();
  final deepLink = data?.link;
  manageDeepLink(deepLink);
}

void manageDeepLink(Uri? deepLink) async {
  final auth = FirebaseAuth.instance;
  if (deepLink == null) return;
  var actionCode = deepLink.queryParameters['oobCode'];
  if (actionCode == null) return;

  try {
    await auth.checkActionCode(actionCode);
    await auth.applyActionCode(actionCode);

    // If successful, reload the user:
    auth.currentUser?.reload();
  } on FirebaseAuthException catch (e) {
    if (e.code == 'invalid-action-code') {
      print('The code is invalid.');
    }
  }
}
