//export all screens
export 'authstate.dart';
export 'login.dart';
export 'verify_email.dart';
export 'home.dart';
export 'sign_up_screen.dart';
export 'lock_screen.dart'
    if (dart.library.io) 'lock_screen_mobile.dart'
    if (dart.library.html) 'lock_screen_web.dart';
export 'mpass.dart';
export 'add_update_account.dart';
export 'add_update_note.dart';
