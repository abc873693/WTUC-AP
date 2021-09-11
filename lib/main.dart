import 'dart:async';
import 'dart:io';

import 'package:ap_common/api/announcement_helper.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common_firebase/utils/firebase_crashlytics_utils.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in_dartio/google_sign_in_dartio.dart';

import 'app.dart';
import 'config/constants.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // HttpClient.enableTimelineLogging = kDebugMode;
  await Preferences.init(key: Constants.key, iv: Constants.iv);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  if (FirebaseUtils.isSupportCore) await Firebase.initializeApp();
  AnnouncementHelper.instance.organization = 'wtuc';
  AnnouncementHelper.instance.appleBundleId = 'com.wtuc.ap';
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux))
    GoogleSignInDart.register(
      clientId:
          '424476440071-1u6ogh95cl7a6tosoco42hum7q06nff2.apps.googleusercontent.com',
    );
  if (!kDebugMode && FirebaseCrashlyticsUtils.isSupported) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    runZonedGuarded(() {
      runApp(MyApp());
    }, (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    });
  } else
    runApp(MyApp());
}
