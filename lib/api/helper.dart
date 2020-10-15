import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:ap_common/callback/general_callback.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

export 'package:ap_common/callback/general_callback.dart';

class Helper {
  static Helper _instance;
  static Dio dio;

  static String username;
  static String password;
  static DateTime expireTime;

  static bool isSupportCacheData =
      (!kIsWeb && (Platform.isIOS || Platform.isMacOS || Platform.isAndroid));

  static Helper get instance {
    if (_instance == null) {
      _instance = Helper();
    }
    return _instance;
  }
}
