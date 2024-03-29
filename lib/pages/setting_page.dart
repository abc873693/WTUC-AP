import 'dart:io';

import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/analytics_utils.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common/widgets/setting_page_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../widgets/share_data_widget.dart';

class SettingPage extends StatefulWidget {
  static const String routerName = "/setting";

  @override
  SettingPageState createState() => SettingPageState();
}

class SettingPageState extends State<SettingPage> {
  ApLocalizations ap;

  String appVersion;

  bool displayPicture = true;

  @override
  void initState() {
    _getPreference();
    if (DateTime.now().millisecondsSinceEpoch % 5 == 0)
      ApUtils.showAppReviewDialog(context, Constants.PLAY_STORE_URL);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(ap.settings),
        backgroundColor: ApTheme.of(context).blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SettingTitle(text: ap.notificationItem),
            CheckCourseNotifyItem(),
            ClearAllNotifyItem(),
            Divider(
              color: Colors.grey,
              height: 0.5,
            ),
            SettingTitle(text: ap.otherSettings),
            SettingSwitch(
              text: ap.headPhotoSetting,
              subText: ap.headPhotoSettingSubTitle,
              value: displayPicture,
              onChanged: (b) {
                setState(() {
                  displayPicture = !displayPicture;
                });
                Preferences.setBool(
                    Constants.PREF_DISPLAY_PICTURE, displayPicture);
              },
            ),
            ChangeLanguageItem(
              onChange: (locale) {
                ShareDataWidget.of(context).data.loadLocale(locale);
              },
            ),
            ChangeThemeModeItem(
              onChange: (themeMode) {
                ShareDataWidget.of(context).data.loadTheme(themeMode);
              },
            ),
            ChangeIconStyleItem(
              onChange: (String code) {
                ShareDataWidget.of(context).data.update();
              },
            ),
            Divider(
              color: Colors.grey,
              height: 0.5,
            ),
            SettingTitle(text: ap.otherInfo),
            SettingItem(
              text: ap.feedback,
              subText: ap.feedbackViaFacebook,
              onTap: () {
                ApUtils.launchFbFansPage(context, Constants.FANS_PAGE_ID);
                AnalyticsUtils.instance?.logEvent('feedback_click');
              },
            ),
            SettingItem(
              text: ap.appVersion,
              subText: "v$appVersion",
              onTap: () {
                AnalyticsUtils.instance?.logEvent('app_version_click');
              },
            ),
          ],
        ),
      ),
    );
  }

  _getPreference() async {
    PackageInfo packageInfo;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo?.version ?? '0.1.3';
    }
    setState(() {
      displayPicture =
          Preferences.getBool(Constants.PREF_DISPLAY_PICTURE, true);
    });
  }
}
