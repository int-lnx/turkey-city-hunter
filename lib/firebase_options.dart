// File generated for Firebase configuration.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions have not been configured for iOS.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDNZlK8vAj4LGATa2CmSWtRykF9xEIzatI',
    appId: '1:736231834800:web:ca6f11614736d971cb6775',
    messagingSenderId: '736231834800',
    projectId: 'turkey-city',
    authDomain: 'turkey-city.firebaseapp.com',
    storageBucket: 'turkey-city.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-4f4mCHlX5P2bdm7m-sxmOZO8JckEqVc',
    appId: '1:736231834800:android:8c981799f1a7e38ccb6775',
    messagingSenderId: '736231834800',
    projectId: 'turkey-city',
    storageBucket: 'turkey-city.firebasestorage.app',
  );
}
