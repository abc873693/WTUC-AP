import 'dart:async';
import 'dart:io' show Platform;

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/models/score_data.dart';
import 'package:ap_common/models/semester_data.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:ap_common_firebase/utils/firebase_crashlytics_utils.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:wtuc_ap/api/wtuc_helper.dart';
import 'package:wtuc_ap/models/teaching_evaluation.dart';

export 'package:ap_common/callback/general_callback.dart';

class Helper {
  static Helper _instance;

  static Helper get instance {
    return _instance ??= Helper();
  }

  static String username;
  static String password;

  static bool isSupportCacheData =
      (!kIsWeb && (Platform.isIOS || Platform.isMacOS || Platform.isAndroid));

  Dio dio;

  Future<GeneralResponse> login({
    @required String username,
    @required String password,
    GeneralCallback<GeneralResponse> callback,
  }) async {
    try {
      await WebApHelper.instance.wzuApLogin(
        username: username,
        password: password,
      );
      Helper.username = username;
      Helper.password = password;
      if (callback != null)
        return callback.onSuccess(GeneralResponse.success());
      else
        return GeneralResponse.success();
    } on GeneralResponse catch (response) {
      callback?.onError(response);
    } on DioError catch (e) {
      callback?.onFailure(e);
    } catch (e, s) {
      callback?.onError(GeneralResponse.unknownError());
      if (FirebaseCrashlyticsUtils.isSupported)
        await FirebaseCrashlytics.instance.recordError(e, s);
    }
    return null;
  }

  Future<String> getChangePasswordInfo({
    @required String username,
    GeneralCallback<String> callback,
  }) async {
    try {
      final String text = await WebApHelper.instance.getChangePasswordInfo(
        username: username,
      );
      if (callback != null)
        return callback.onSuccess(text);
      else
        return text;
    } on GeneralResponse catch (response) {
      callback?.onError(response);
    } on DioError catch (e) {
      callback?.onFailure(e);
    } catch (e, s) {
      callback?.onError(GeneralResponse.unknownError());
      if (FirebaseCrashlyticsUtils.isSupported)
        await FirebaseCrashlytics.instance.recordError(e, s);
    }
    return null;
  }

  Future<GeneralResponse> changePassword({
    @required String username,
    @required String password,
    @required String passwordConfirm,
    GeneralCallback<GeneralResponse> callback,
  }) async {
    try {
      await WebApHelper.instance.changePassword(
        username: username,
        password: password,
      );
      if (callback != null)
        return callback.onSuccess(GeneralResponse.success());
      else
        return GeneralResponse.success();
    } on GeneralResponse catch (response) {
      callback?.onError(response);
    } on DioError catch (e) {
      callback?.onFailure(e);
    } catch (e, s) {
      callback?.onError(GeneralResponse.unknownError());
      if (FirebaseCrashlyticsUtils.isSupported)
        await FirebaseCrashlytics.instance.recordError(e, s);
    }
    return null;
  }

  Future<SemesterData> getSemester({
    GeneralCallback<SemesterData> callback,
  }) async {
    try {
      var data = await WebApHelper.instance.wtucSemesters();
      data.data = data.data.reversed.toList();
      data.currentIndex = data.defaultIndex;
      return (callback == null) ? data : callback.onSuccess(data);
    } on DioError catch (dioError) {
      callback?.onFailure(dioError);
      if (callback == null) throw dioError;
    } catch (e, s) {
      callback?.onError(GeneralResponse.unknownError());
      if (FirebaseCrashlyticsUtils.isSupported)
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
      return (callback == null) ? data : callback.onSuccess(data);
    } on DioError catch (dioError) {
      callback?.onFailure(dioError);
      if (callback == null) throw dioError;
    } catch (e, s) {
      callback?.onError(GeneralResponse.unknownError());
      if (FirebaseCrashlyticsUtils.isSupported)
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
      if (FirebaseCrashlyticsUtils.isSupported)
        await FirebaseCrashlytics.instance.recordError(e, s);
    }
    return null;
  }

  Future<ScoreData> getScores({
    @required Semester semester,
    GeneralCallback<ScoreData> callback,
  }) async {
    try {
      var data = await WebApHelper.instance.wtucScores(
        semester.year,
        semester.value,
      );
      if (data != null && data.scores.length == 0) data = null;
      return (callback == null) ? data : callback.onSuccess(data);
    } on DioError catch (dioError) {
      callback?.onFailure(dioError);
      if (callback == null) throw dioError;
    } on GeneralResponse catch (r) {
      callback?.onError(r);
    } catch (e, s) {
      callback?.onError(GeneralResponse.unknownError());
      if (FirebaseCrashlyticsUtils.isSupported)
        await FirebaseCrashlytics.instance.recordError(e, s);
    }
    return null;
  }

  Future<List<TeachingEvaluation>> getTeachingEvaluation({
    GeneralCallback<List<TeachingEvaluation>> callback,
  }) async {
    try {
      var data = await WebApHelper.instance.wtucTeachingEvaluation();
      if (data != null && data.length == 0) data = null;
      return (callback == null) ? data : callback.onSuccess(data);
    } on DioError catch (dioError) {
      callback?.onFailure(dioError);
      if (callback == null) throw dioError;
    } catch (e, s) {
      callback?.onError(GeneralResponse.unknownError());
      if (FirebaseCrashlyticsUtils.isSupported)
        await FirebaseCrashlytics.instance.recordError(e, s);
    }
    return null;
  }

  Future<GeneralResponse> sendTeachingEvaluation({
    List<TeachingEvaluation> teachingEvaluations,
    GeneralCallback<GeneralResponse> callback,
  }) async {
    try {
      for (var teachingEvaluation in teachingEvaluations) {
        await WebApHelper.instance.sendTeachingEvaluation(teachingEvaluation);
      }
      return (callback == null)
          ? GeneralResponse.success()
          : callback.onSuccess(GeneralResponse.success());
    } on DioError catch (dioError) {
      callback?.onFailure(dioError);
      if (callback == null) throw dioError;
    } catch (e, s) {
      callback?.onError(GeneralResponse.unknownError());
      if (FirebaseCrashlyticsUtils.isSupported)
        await FirebaseCrashlytics.instance.recordError(e, s);
    }
    return null;
  }
}
