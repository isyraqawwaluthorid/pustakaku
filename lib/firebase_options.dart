// ============================================================================
// FILE INI ADALAH PLACEHOLDER (MODE DEMO LOKAL).
//
// Selama projectId masih diawali "demo-", aplikasi otomatis terhubung ke
// Firebase Local Emulator Suite (Auth + Firestore) yang dijalankan dengan:
//   firebase emulators:start --only auth,firestore --project demo-pustakaku
//
// Untuk memakai proyek Firebase sungguhan, jalankan di root proyek:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<id-proyek-firebase> --platforms=android,ios,web
// Perintah tersebut menimpa file ini dan menaruh google-services.json /
// GoogleService-Info.plist. Mode demo lalu nonaktif dengan sendirinya.
// ============================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk platform ini.'),
    };
  }

  /// true selama masih memakai konfigurasi placeholder (emulator lokal).
  static bool get isDemo => currentPlatform.projectId.startsWith('demo-');

  static const _demoProject = 'demo-pustakaku';

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: _demoProject,
    authDomain: '$_demoProject.firebaseapp.com',
    storageBucket: '$_demoProject.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: _demoProject,
    storageBucket: '$_demoProject.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: _demoProject,
    storageBucket: '$_demoProject.appspot.com',
    iosBundleId: 'com.isyraqawwal.pustakaku',
  );
}
