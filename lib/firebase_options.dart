// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
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
    apiKey: 'AIzaSyCYy-KNcfg8JMW6laXxA5wPkmy-7SzpWYg',
    appId: '1:20561310459:web:e068ffd9d6e668a1eff65e',
    messagingSenderId: '20561310459',
    projectId: 'andco-9cdaa',
    authDomain: 'andco-9cdaa.firebaseapp.com',
    storageBucket: 'andco-9cdaa.firebasestorage.app',
    measurementId: 'G-B926P9E11F',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAXXHaTD-AXT8JbPMpdNWEiAbyiqoIgZrA',
    appId: '1:20561310459:android:c28cb8dd77aba653eff65e',
    messagingSenderId: '20561310459',
    projectId: 'andco-9cdaa',
    storageBucket: 'andco-9cdaa.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAMYhaako-FGVaWNm3cLMDYQpYcCzgh14Q',
    appId: '1:20561310459:ios:c1983c7c7ccf1787eff65e',
    messagingSenderId: '20561310459',
    projectId: 'andco-9cdaa',
    storageBucket: 'andco-9cdaa.firebasestorage.app',
    iosBundleId: 'com.example.andco',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAMYhaako-FGVaWNm3cLMDYQpYcCzgh14Q',
    appId: '1:20561310459:ios:c1983c7c7ccf1787eff65e',
    messagingSenderId: '20561310459',
    projectId: 'andco-9cdaa',
    storageBucket: 'andco-9cdaa.firebasestorage.app',
    iosBundleId: 'com.example.andco',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCYy-KNcfg8JMW6laXxA5wPkmy-7SzpWYg',
    appId: '1:20561310459:web:441beffbb89e3f57eff65e',
    messagingSenderId: '20561310459',
    projectId: 'andco-9cdaa',
    authDomain: 'andco-9cdaa.firebaseapp.com',
    storageBucket: 'andco-9cdaa.firebasestorage.app',
    measurementId: 'G-3ZJFR89QVY',
  );

}