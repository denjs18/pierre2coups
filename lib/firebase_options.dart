// PLACEHOLDER - Remplir avec les valeurs depuis Firebase Console
// Project settings → General → Your apps → Web app → SDK setup and configuration

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
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDAqS8VXDVRJLj8RLaK4-MdAqVMB1dYfNU',
    authDomain: 'pierre2coups.firebaseapp.com',
    projectId: 'pierre2coups',
    storageBucket: 'pierre2coups.firebasestorage.app',
    messagingSenderId: '409958538162',
    appId: '1:409958538162:web:f355953a13bbfe6e9da2ab',
    measurementId: 'G-QZDK82Y0WL',
  );

  // TODO: Remplacer si vous supportez Android (google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REMPLACER_ICI',
    appId: 'REMPLACER_ICI',
    messagingSenderId: 'REMPLACER_ICI',
    projectId: 'REMPLACER_ICI',
    storageBucket: 'REMPLACER_ICI',
  );

  // TODO: Remplacer si vous supportez iOS (GoogleService-Info.plist)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REMPLACER_ICI',
    appId: 'REMPLACER_ICI',
    messagingSenderId: 'REMPLACER_ICI',
    projectId: 'REMPLACER_ICI',
    storageBucket: 'REMPLACER_ICI',
    iosBundleId: 'REMPLACER_ICI',
  );
}
