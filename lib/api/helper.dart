import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/course_data.dart';

/// TODO: Select senesterData use by local model or ap_common.
import 'package:ap_common/models/semester_data.dart';
import 'package:ap_common/models/user_info.dart';

import 'package:ap_common_firebase/utils/firebase_utils.dart';
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

  Future<SemesterData> getSemester({
    GeneralCallback<SemesterData> callback,
  }) async {
    try {
      var data = await WebApHelper.instance.wtucSemesters();

      return (callback == null) ? data : callback.onSuccess(data);
    } on DioError catch (dioError) {
      callback?.onFailure(dioError);
      if (callback == null) throw dioError;
    } catch (e, s) {
      callback?.onError(GeneralResponse.unknownError());
      if (FirebaseUtils.isSupportCrashlytics)
        await FirebaseCrashlytics.instance.recordError(e, s);
    }
    return null;
  }

  Future<CourseData> getCourseTables({
    @required Semester semester,
    GeneralCallback<CourseData> callback,
  }) async {
    // if (isExpire()) await login(username: username, password: password);
    var data = await WebApHelper.instance.wtucCoursetable(
      semester.year,
      semester.value,
    );

    try {
      if (data != null && data.courses != null && data.courses.length != 0) {
        data.updateIndex();
      }
      return (callback == null) ? data : callback.onSuccess(data);
    } on DioError catch (dioError) {
      callback?.onFailure(dioError);
      if (callback == null) throw dioError;
    } catch (e, s) {
      callback?.onError(GeneralResponse.unknownError());
      if (FirebaseUtils.isSupportCrashlytics)
        await FirebaseCrashlytics.instance.recordError(e, s);
    }
    return null;
  }

  Future<UserInfo> getUsersInfo({
    GeneralCallback<UserInfo> callback,
  }) async {
    try {
      var data = await WebApHelper.instance.wtucUserInfo();

      if (data.id == null) data.id = username;
      return (callback == null) ? data : callback.onSuccess(data);
    } on DioError catch (dioError) {
      callback?.onFailure(dioError);
      if (callback == null) throw dioError;
    } catch (e, s) {
      callback?.onError(GeneralResponse.unknownError());
      if (FirebaseUtils.isSupportCrashlytics)
        await FirebaseCrashlytics.instance.recordError(e, s);
    }
    return null;
  }
}
