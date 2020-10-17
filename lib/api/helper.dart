import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:ap_common/callback/general_callback.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:wtuc_ap/api/wtuc_helper.dart';
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

  Future<bool> login({
    @required String username,
    @required String password,
    GeneralCallback<bool> callback,
  }) async {
    try {
      var loginResponse = await WebApHelper.instance.wzuApLogin(
        username: username,
        password: password,
      );
      if (!loginResponse) {
        throw GeneralResponse(statusCode: 401, message: "Login fail.");
      }
      Helper.username = username;
      Helper.password = password;
      if (callback != null)
        return callback.onSuccess(loginResponse);
      else
        return loginResponse;
    } on GeneralResponse catch (response) {
      callback?.onError(response);
    } on DioError catch (e) {
      callback?.onFailure(e);
    } catch (e) {
      callback?.onError(
        GeneralResponse.unknownError(),
      );
      throw e;
    }
    return null;
  }
}
