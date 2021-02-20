import 'package:ap_common/config/ap_constants.dart';
import 'package:ap_common/models/course_notify_data.dart';
import 'package:ap_common/models/semester_data.dart';
import 'package:ap_common/scaffold/course_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:flutter/material.dart';
import 'package:wtuc_ap/api/helper.dart';

import '../../config/constants.dart';

class CoursePage extends StatefulWidget {
  static const String routerName = '/course';

  @override
  CoursePageState createState() => CoursePageState();
}

class CoursePageState extends State<CoursePage> {
  ApLocalizations ap;

  CourseState state = CourseState.loading;

  SemesterData semesterData;

  CourseData courseData;

  CourseNotifyData notifyData;

  bool isOffline = false;

  String customStateHint = '';

  String get courseNotifyCacheKey => Preferences.getString(
        ApConstants.CURRENT_SEMESTER_CODE,
        ApConstants.SEMESTER_LATEST,
      );

  @override
  void initState() {
    _getSemester();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return CourseScaffold(
      state: state,
      courseData: courseData,
      notifyData: notifyData,
      customHint: isOffline ? ap.offlineCourse : '',
      customStateHint: customStateHint,
      enableNotifyControl: true,
      enableCaptureCourseTable: true,
      courseNotifySaveKey: courseNotifyCacheKey,
      androidResourceIcon: Constants.ANDROID_DEFAULT_NOTIFICATION_NAME,
      semesterData: semesterData,
      onSelect: (index) {
        setState(() {
          state = CourseState.loading;
          semesterData.currentIndex = index;
        });
        _getCourseTables();
      },
      onRefresh: () async {
        await _getCourseTables();
        return null;
      },
    );
  }

  void _getSemester() async {
    Helper.instance.getSemester(
      callback: GeneralCallback<SemesterData>(
        onFailure: null,
        onError: null,
        onSuccess: (data) {
          setState(() {
            semesterData = data;
          });
          _getCourseTables();
        },
      ),
    );
  }

  _getCourseTables() async {
    Helper.instance.getCourseTables(
      semester: semesterData.currentSemester,
      callback: GeneralCallback(
        onSuccess: (CourseData data) {
          if (mounted)
            setState(() {
              courseData = data;
              isOffline = false;
              // courseData.save(semesterData.currentSemester.cacheSaveTag);
              state = CourseState.finish;
              notifyData = CourseNotifyData.load(courseNotifyCacheKey);
            });
        },
        onFailure: (DioError e) async {
          setState(() {
            state = CourseState.custom;
            customStateHint = e.i18nMessage;
          });
        },
        onError: (GeneralResponse generalResponse) async {
          setState(() {
            state = CourseState.custom;
            customStateHint = ap.unknownError;
          });
        },
      ),
    );
  }
}
