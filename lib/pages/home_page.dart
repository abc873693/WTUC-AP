import 'package:ap_common/api/announcement_helper.dart';
import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:ap_common/pages/about_us_page.dart';
import 'package:ap_common/pages/announcement/home_page.dart';
import 'package:ap_common/pages/announcement_content_page.dart';
import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/scaffold/home_page_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/dialog_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common/widgets/ap_drawer.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:ap_common_firebase/utils/firebase_message_utils.dart';
import 'package:ap_common_firebase/utils/firebase_remote_config_utils.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wtuc_ap/api/api_status_code.dart';
import 'package:wtuc_ap/api/helper.dart';
import 'package:wtuc_ap/pages/school_map_page.dart';
import 'package:wtuc_ap/pages/study/teaching_evaluation_page.dart';

import '../config/constants.dart';
import '../res/assets.dart';
import '../utils/app_localizations.dart';
import 'login/change_passwrod_page.dart';
import 'login_page.dart';
import 'setting_page.dart';
import 'shcool_info_page.dart';
import 'study/course_page.dart';
import 'study/score_page.dart';
import 'user_info_page.dart';

class HomePage extends StatefulWidget {
  static const String routerName = "/home";

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final GlobalKey<HomePageScaffoldState> _homeKey =
      GlobalKey<HomePageScaffoldState>();

  bool get isTablet => MediaQuery.of(context).size.shortestSide > 680;

  var state = HomeState.loading;

  AppLocalizations app;
  ApLocalizations ap;

  Widget content;

  List<Announcement> announcements;

  var isLogin = false;
  bool displayPicture = true;
  bool isStudyExpanded = false;
  bool isBusExpanded = false;
  bool isLeaveExpanded = false;

  bool canUseQuickFillIn = false;

  UserInfo userInfo;

  TextStyle get _defaultStyle => TextStyle(
        color: ApTheme.of(context).grey,
        fontSize: 16.0,
      );

  static aboutPage(BuildContext context, {String assetImage}) {
    return AboutUsPage(
      assetImage: assetImage ?? ImageAssets.section,
      githubName: 'NKUST-ITC',
      email: 'abc873693@gmail.com',
      appLicense: AppLocalizations.of(context).aboutOpenSourceContent,
      fbFanPageId: '735951703168873',
      fbFanPageUrl: 'https://www.facebook.com/NKUST.ITC/',
      githubUrl: 'https://github.com/NKUST-ITC',
      actions: <Widget>[],
    );
  }

  @override
  void initState() {
    _getAnnouncements();
    if (Preferences.getBool(Constants.PREF_AUTO_LOGIN, false)) {
      _login();
    } else {
      checkLogin();
    }
    if (FirebaseRemoteConfigUtils.isSupported) {
      _checkUpdate();
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    ap = ApLocalizations.of(context);
    return HomePageScaffold(
      title: app.appName,
      key: _homeKey,
      state: state,
      announcements: announcements,
      isLogin: isLogin,
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.fiber_new_rounded),
          tooltip: ap.announcementReviewSystem,
          onPressed: () async {
            ApUtils.pushCupertinoStyle(
              context,
              AnnouncementHomePage(
                organizationDomain: Constants.MAIL_DOMAIN,
              ),
            );
            if (FirebaseMessagingUtils.isSupported) {
              try {
                final messaging = FirebaseMessaging.instance;
                NotificationSettings settings =
                    await messaging.getNotificationSettings();
                if (settings.authorizationStatus ==
                        AuthorizationStatus.authorized ||
                    settings.authorizationStatus ==
                        AuthorizationStatus.provisional) {
                  String token = await messaging.getToken();
                  AnnouncementHelper.instance.fcmToken = token;
                }
              } catch (_) {}
            }
          },
        ),
      ],
      content: content,
      drawer: ApDrawer(
        userInfo: userInfo,
        displayPicture:
            Preferences.getBool(Constants.PREF_DISPLAY_PICTURE, true),
        onTapHeader: () {
          if (isLogin) {
            if (userInfo != null)
              ApUtils.pushCupertinoStyle(
                context,
                UserInfoPage(userInfo: userInfo),
              );
          } else {
            if (!isTablet) Navigator.of(context).pop();
            openLoginPage();
          }
        },
        widgets: <Widget>[
          if (isTablet)
            DrawerItem(
              icon: ApIcon.home,
              title: ap.home,
              onTap: () => setState(() => content = null),
            ),
          ExpansionTile(
            initiallyExpanded: isStudyExpanded,
            onExpansionChanged: (bool) {
              setState(() {
                isStudyExpanded = bool;
              });
            },
            leading: Icon(
              ApIcon.school,
              color: isStudyExpanded
                  ? ApTheme.of(context).blueAccent
                  : ApTheme.of(context).grey,
            ),
            title: Text(ap.courseInfo, style: _defaultStyle),
            children: <Widget>[
              DrawerSubItem(
                icon: ApIcon.classIcon,
                title: ap.course,
                onTap: () => _openPage(
                  CoursePage(),
                  needLogin: true,
                ),
              ),
              DrawerSubItem(
                icon: ApIcon.assignment,
                title: ap.score,
                onTap: () => _openPage(
                  ScorePage(),
                  needLogin: true,
                ),
              ),
//              DrawerSubItem(
//                icon: ApIcon.room,
//                title: ap.classroomCourseTableSearch,
//                page: RoomListPage(),
//              ),
            ],
          ),
          DrawerItem(
            icon: ApIcon.map,
            title: ap.schoolMap,
            onTap: () => _openPage(
              SchoolMapPage(),
            ),
          ),
          if (canUseQuickFillIn && isLogin)
            DrawerItem(
              icon: ApIcon.person,
              title: app.teachingEvaluation,
              onTap: () => _openPage(
                TeachingEvaluationPage(),
                needLogin: true,
              ),
            ),
          DrawerItem(
            icon: ApIcon.info,
            title: ap.schoolInfo,
            onTap: () => _openPage(
              SchoolInfoPage(),
            ),
          ),
          DrawerItem(
            icon: ApIcon.face,
            title: ap.about,
            onTap: () => _openPage(
              aboutPage(context, assetImage: ImageAssets.section),
            ),
          ),
          DrawerItem(
            icon: ApIcon.settings,
            title: ap.settings,
            onTap: () => _openPage(
              SettingPage(),
            ),
          ),
          if (isLogin)
            DrawerItem(
              icon: ApIcon.powerSettingsNew,
              title: ap.logout,
              onTap: () async {
                await Preferences.setBool(Constants.PREF_AUTO_LOGIN, false);
                isLogin = false;
                userInfo = null;
                content = null;
                canUseQuickFillIn = false;
                if (!isTablet) Navigator.of(context).pop();
                checkLogin();
              },
            ),
        ],
      ),
      onImageTapped: (Announcement announcement) {
        ApUtils.pushCupertinoStyle(
          context,
          AnnouncementContentPage(announcement: announcement),
        );
      },
      onTabTapped: onTabTapped,
      bottomNavigationBarItems: [
        BottomNavigationBarItem(
          icon: Icon(ApIcon.face),
          label: ap.about,
        ),
        BottomNavigationBarItem(
          icon: Icon(ApIcon.classIcon),
          label: ap.course,
        ),
        BottomNavigationBarItem(
          icon: Icon(ApIcon.assignment),
          label: ap.score,
        ),
      ],
    );
  }

  void onTabTapped(int index) async {
    if (isLogin) {
      switch (index) {
        case 0:
          ApUtils.pushCupertinoStyle(
            context,
            aboutPage(
              context,
              assetImage: ImageAssets.section,
            ),
          );
          break;
        case 1:
          ApUtils.pushCupertinoStyle(context, CoursePage());
          break;
        case 2:
          ApUtils.pushCupertinoStyle(context, ScorePage());
          break;
      }
    } else
      ApUtils.showToast(context, ap.notLogin);
  }

  _getAnnouncements() async {
    AnnouncementHelper.instance.getAnnouncements(
      tags: ['wtuc'],
      callback: GeneralCallback(
        onFailure: (_) => setState(() => state = HomeState.error),
        onError: (_) => setState(() => state = HomeState.error),
        onSuccess: (List<Announcement> data) {
          announcements = data;
          if (mounted)
            setState(() {
              if (announcements == null || announcements.length == 0)
                state = HomeState.empty;
              else
                state = HomeState.finish;
            });
        },
      ),
    );
  }

  _getUserInfo() async {
    Helper.instance.getUsersInfo(
      callback: GeneralCallback(
        onSuccess: (UserInfo data) async {
          if (mounted) {
            setState(() {
              this.userInfo = data;
            });
            await FirebaseAnalyticsUtils.instance.logUserInfo(userInfo);
            _checkCanUseQuickFillIn();
            userInfo.save(Helper.username);
            if (Preferences.getBool(Constants.PREF_DISPLAY_PICTURE, true))
              _getUserPicture();
          }
        },
        onFailure: (DioError e) {},
        onError: (GeneralResponse e) => null,
      ),
    );
    if (Preferences.getBool(Constants.PREF_DISPLAY_PICTURE, true))
      _getUserPicture();
  }

  _getUserPicture() async {
    try {
      if ((userInfo?.pictureUrl) == null) return;
      var response = await http.get(Uri.parse(userInfo.pictureUrl));
      if (!response.body.contains('html')) {
        if (mounted) {
          setState(() {
            userInfo.pictureBytes = response.bodyBytes;
          });
        }
//        CacheUtils.savePictureData(response.bodyBytes);
      }
    } catch (e) {
      throw e;
    }
  }

  Future _login() async {
    await Future.delayed(Duration(microseconds: 30));
    var username = Preferences.getString(Constants.PREF_USERNAME, '');
    var password = Preferences.getStringSecurity(Constants.PREF_PASSWORD, '');
    Helper.instance.login(
      username: username,
      password: password,
      callback: GeneralCallback<GeneralResponse>(
        onSuccess: (GeneralResponse response) async {
          isLogin = true;
          Preferences.setBool(Constants.PREF_IS_OFFLINE_LOGIN, false);
          _getUserInfo();
          _checkCanUseQuickFillIn();
          if (state != HomeState.finish) {
            _getAnnouncements();
          }
          _homeKey.currentState.showBasicHint(text: ap.loginSuccess);
        },
        onFailure: (DioError e) {
          final text = e.i18nMessage;
          _homeKey.currentState.showSnackBar(
            text: text,
            actionText: ap.retry,
            onSnackBarTapped: _login,
          );
        },
        onError: (GeneralResponse response) {
          switch (response.statusCode) {
            case ApiStatusCode.LOGIN_FAIL:
              ApUtils.showToast(context, ap.loginFail);
              checkLogin();
              break;
            case ApiStatusCode.NEED_CHANGE_PASSWORD:
              ApUtils.showToast(
                  context, AppLocalizations.of(context).needChangePasswordHint);
              _openChangePasswordPage(username);
              break;
            default:
              _homeKey.currentState.showSnackBar(
                text: ap.unknownError,
                actionText: ap.retry,
                onSnackBarTapped: _login,
              );
              break;
          }
        },
      ),
    );
  }

  Future openLoginPage() async {
    var result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginPage(),
      ),
    );
    checkLogin();
    if (result ?? false) {
      _getUserInfo();
      _checkCanUseQuickFillIn();
      if (state != HomeState.finish) {
        _getAnnouncements();
      }
      setState(() {
        isLogin = true;
      });
    }
  }

  void checkLogin() async {
    await Future.delayed(Duration(microseconds: 30));
    if (isLogin) {
      _homeKey.currentState.hideSnackBar();
    } else {
      _homeKey.currentState
          .showSnackBar(
            text: ApLocalizations.of(context).notLogin,
            actionText: ApLocalizations.of(context).login,
            onSnackBarTapped: openLoginPage,
          )
          .closed
          .then(
        (SnackBarClosedReason reason) {
          checkLogin();
        },
      );
    }
  }

  _openPage(Widget page, {needLogin = false}) {
    if (!isTablet) Navigator.of(context).pop();
    if (needLogin && !isLogin)
      ApUtils.showToast(
        context,
        ApLocalizations.of(context).notLoginHint,
      );
    else {
      if (isTablet) {
        setState(() => content = page);
      } else
        ApUtils.pushCupertinoStyle(context, page);
    }
  }

  _checkUpdate() async {
    if (kIsWeb) return;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    await Future.delayed(Duration(milliseconds: 50));
    var currentVersion =
        Preferences.getString(Constants.PREF_CURRENT_VERSION, '');
    if (currentVersion != packageInfo.buildNumber) {
      final rawData = await FileAssets.changelogData;
      final updateNoteContent =
          rawData["${packageInfo.buildNumber}"][ApLocalizations.current.locale];
      DialogUtils.showUpdateContent(
        context,
        "v${packageInfo.version}\n"
        "$updateNoteContent",
      );
      Preferences.setString(
        Constants.PREF_CURRENT_VERSION,
        packageInfo.buildNumber,
      );
    }
    if (!kDebugMode) {
      RemoteConfig remoteConfig = RemoteConfig.instance;
      await remoteConfig.fetch();
      await remoteConfig.activate();
      VersionInfo versionInfo = remoteConfig.versionInfo;
      if (versionInfo != null)
        DialogUtils.showNewVersionContent(
          context: context,
          iOSAppId: '1536450161',
          defaultUrl: 'https://www.facebook.com/NKUST.ITC/',
          githubRepositoryName: 'abc873693/WTUC-AP',
          windowsPath:
              'https://github.com/NKUST-ITC/abc873693/WTUC-AP/releases/download/%s/wtuc_ap_windows.zip',
          appName: app.appName,
          versionInfo: versionInfo,
        );
    }
  }

  _checkCanUseQuickFillIn() async {
    if (FirebaseRemoteConfigUtils.isSupported) {
      final config = RemoteConfig.instance;
      setState(() {
        canUseQuickFillIn =
            config.getBool(Constants.QUICK_FILL_IN_TEACHING_EVALUATION);
        print(canUseQuickFillIn);
      });
    }
  }

  Future<void> _openChangePasswordPage(String username) async {
    final String password = await Navigator.of(context).push(
      MaterialPageRoute<String>(
        builder: (_) => ChangePasswordPage(username: username),
      ),
    );
    if (password != null) {
      Preferences.setStringSecurity(Constants.PREF_PASSWORD, password);
      await Future.delayed(Duration(seconds: 1));
      _login();
    }
  }
}
