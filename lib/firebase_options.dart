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
    apiKey: 'AIzaSyDNARFFn7Jt0-Pirw2tmRQcgbt8u_mLUSI',
    authDomain: 'tablessketty.firebaseapp.com',
    projectId: 'tablessketty',
    storageBucket: 'tablessketty.firebasestorage.app',
    messagingSenderId: '674074758742',
    appId: '1:674074758742:web:0286016a627d53b98875f7',
    measurementId: 'G-H5HQ1VG7VM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDNARFFn7Jt0-Pirw2tmRQcgbt8u_mLUSI',
    authDomain: 'tablessketty.firebaseapp.com',
    projectId: 'tablessketty',
    storageBucket: 'tablessketty.firebasestorage.app',
    messagingSenderId: '674074758742',
    appId: '1:674074758742:android:YOUR_ANDROID_APP_ID',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDNARFFn7Jt0-Pirw2tmRQcgbt8u_mLUSI',
    authDomain: 'tablessketty.firebaseapp.com',
    projectId: 'tablessketty',
    storageBucket: 'tablessketty.firebasestorage.app',
    messagingSenderId: '674074758742',
    appId: '1:674074758742:ios:YOUR_IOS_APP_ID',
    iosBundleId: 'com.mycompany.tablessketty',
  );
}
