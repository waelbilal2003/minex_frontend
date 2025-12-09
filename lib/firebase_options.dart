import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    } else {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not supported for this platform.',
      );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCzWwuVRe9LujNzXcHxSZf0NcJAx5b2MLo',
    appId: '1:987403350920:android:7e441e7bc62a435bae403d',
    messagingSenderId: '987403350920',
    projectId: 'minex-notifications',
    storageBucket: 'minex-notifications.appspot.com',
  );
}
