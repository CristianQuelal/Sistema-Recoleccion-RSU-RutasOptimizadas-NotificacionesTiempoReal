// Archivo generado por el CLI (Command Line Interface) de FlutterFire

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
    apiKey: 'Ingresar API KEY',
    appId: '1:577573442468:web:3229bd45d8d6d645c12731',
    messagingSenderId: '577573442468',
    projectId: 'residuos-solidos-urbanos2023',
    authDomain: 'residuos-solidos-urbanos2023.firebaseapp.com',
    databaseURL: 'https://residuos-solidos-urbanos2023-default-rtdb.firebaseio.com',
    storageBucket: 'residuos-solidos-urbanos2023.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDQFJutJMDZ867YxiTW3GoBi_pU4OVmo1M',
    appId: '1:577573442468:android:54c3f8fb0792b630c12731',
    messagingSenderId: '577573442468',
    projectId: 'residuos-solidos-urbanos2023',
    databaseURL: 'https://residuos-solidos-urbanos2023-default-rtdb.firebaseio.com',
    storageBucket: 'residuos-solidos-urbanos2023.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDJy8asK3ExKwtJlGzuxXJgJjEsq116g50',
    appId: '1:577573442468:ios:83cd2abf3c4f7ed3c12731',
    messagingSenderId: '577573442468',
    projectId: 'residuos-solidos-urbanos2023',
    databaseURL: 'https://residuos-solidos-urbanos2023-default-rtdb.firebaseio.com',
    storageBucket: 'residuos-solidos-urbanos2023.appspot.com',
    iosBundleId: 'com.example.mapbox',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDJy8asK3ExKwtJlGzuxXJgJjEsq116g50',
    appId: '1:577573442468:ios:83cd2abf3c4f7ed3c12731',
    messagingSenderId: '577573442468',
    projectId: 'residuos-solidos-urbanos2023',
    databaseURL: 'https://residuos-solidos-urbanos2023-default-rtdb.firebaseio.com',
    storageBucket: 'residuos-solidos-urbanos2023.appspot.com',
    iosBundleId: 'com.example.mapbox',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDkWZDzV8rc_uX4BgDkafUtef-9B_SHbvQ',
    appId: '1:577573442468:web:ec1ac07533eeeb12c12731',
    messagingSenderId: '577573442468',
    projectId: 'residuos-solidos-urbanos2023',
    authDomain: 'residuos-solidos-urbanos2023.firebaseapp.com',
    databaseURL: 'https://residuos-solidos-urbanos2023-default-rtdb.firebaseio.com',
    storageBucket: 'residuos-solidos-urbanos2023.appspot.com',
  );

}
