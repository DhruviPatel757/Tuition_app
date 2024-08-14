import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAq9xLg82_T8fsbGFMid6bMSVen4EBoF1o',
    appId: '1:40862319635:web:415fe5c5a8fc57fae4abe6',
    messagingSenderId: '40862319635',
    projectId: 'test-7a3f6',
    authDomain: 'test-7a3f6.firebaseapp.com',
    storageBucket: 'test-7a3f6.appspot.com',
    measurementId: 'G-8H3Y60JGL2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB9ntPOBrWasJUk3S_3S0yAlhCr_jnvBrQ',
    appId: '1:40862319635:android:b52287eac412d6ede4abe6',
    messagingSenderId: '40862319635',
    projectId: 'test-7a3f6',
    storageBucket: 'test-7a3f6.appspot.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAq9xLg82_T8fsbGFMid6bMSVen4EBoF1o',
    appId: '1:40862319635:web:e3d79d9b8b55fee3e4abe6',
    messagingSenderId: '40862319635',
    projectId: 'test-7a3f6',
    authDomain: 'test-7a3f6.firebaseapp.com',
    storageBucket: 'test-7a3f6.appspot.com',
    measurementId: 'G-VJ0CV2QY7E',
  );
}