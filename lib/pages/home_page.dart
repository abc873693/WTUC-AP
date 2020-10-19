import 'package:ap_common/api/github_helper.dart';
import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:ap_common/pages/announcement_content_page.dart';
import 'package:ap_common/pages/about_us_page.dart';
import 'package:ap_common/pages/open_source_page.dart';
import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/scaffold/home_page_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/dialog_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common/widgets/ap_drawer.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:ap_common_firebase/utils/firebase_remote_config_utils.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wtuc_ap/api/api_status_code.dart';
import 'package:wtuc_ap/api/helper.dart';
import 'package:wtuc_ap/pages/school_map_page.dart';
import 'package:package_info/package_info.dart';

import '../config/constants.dart';
import '../res/assets.dart';
import '../utils/app_localizations.dart';
import 'setting_page.dart';
import 'shcool_info_page.dart';
import 'user_info_page.dart';
import 'login_page.dart';
import 'study/course_page.dart';
import 'study/score_page.dart';

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

  Map<String, List<Announcement>> newsMap;

  Widget content;

  List<Announcement> get announcements =>
      (newsMap == null) ? null : newsMap[AppLocalizations.locale.languageCode];

  var isLogin = false;
  bool displayPicture = true;
  bool isStudyExpanded = false;
  bool isBusExpanded = false;
  bool isLeaveExpanded = false;

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
      logEvent: (name, value) {},
      setCurrentScreen: () {},
      actions: <Widget>[
        IconButton(
          icon: Icon(ApIcon.codeIcon),
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => OpenSourcePage(
                  setCurrentScreen: () {},
                ),
              ),
            );
          },
        )
      ],
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
    if (FirebaseUtils.isSupportRemoteConfig) {
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
          icon: Icon(ApIcon.info),
          onPressed: _showInformationDialog,
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
    GitHubHelper.instance.getAnnouncement(
      gitHubUsername: 'abc873693',
      hashCode: 'e1ea5bda328ef8ffa01334c0da6d62b9',
      tag: 'wtuc',
      callback: GeneralCallback(
        onFailure: (_) => setState(() => state = HomeState.error),
        onError: (_) => setState(() => state = HomeState.error),
        onSuccess: (Map<String, List<Announcement>> data) {
          newsMap = data;
          setState(() {
            if (announcements == null || announcements.length == 0)
              state = HomeState.empty;
            else {
              newsMap.forEach((_, data) {
                data.sort((a, b) {
                  return b.weight.compareTo(a.weight);
                });
              });
              state = HomeState.finish;
            }
          });
        },
      ),
    );
  }

  _getUserInfo() async {
    Helper.instance.getUsersInfo(
      callback: GeneralCallback(
        onSuccess: (UserInfo data) {
          if (mounted) {
            setState(() {
              this.userInfo = data;
            });
            FirebaseAnalyticsUtils.instance.logUserInfo(userInfo);
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
      var response = await http.get(userInfo.pictureUrl);
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

  void _showInformationDialog() {
    DialogUtils.showAnnouncementRule(
      context: context,
      onRightButtonClick: () {
        ApUtils.launchFbFansPage(context, Constants.FANS_PAGE_ID);
      },
    );
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
          if (state != HomeState.finish) {
            _getAnnouncements();
          }
          _homeKey.currentState.showBasicHint(text: ap.loginSuccess);
        },
        onFailure: (DioError e) {
          final text = ApLocalizations.dioError(context, e);
          _homeKey.currentState.showSnackBar(
            text: text,
            actionText: ap.retry,
            onSnackBarTapped: _login,
          );
        },
        onError: (GeneralResponse response) {
          String message = '';
          switch (response.statusCode) {
            case ApiStatusCode.LOGIN_FAIL:
              message = ap.loginFail;
              break;
            default:
              message = ap.somethingError;
              break;
          }
          _homeKey.currentState.showSnackBar(
            text: message,
            actionText: ap.retry,
            onSnackBarTapped: _login,
          );
        },
      ),
    );
    isLogin = true;
    Preferences.setBool(Constants.PREF_IS_OFFLINE_LOGIN, false);
    _getUserInfo();
    if (state != HomeState.finish) {
      _getAnnouncements();
    }
    _homeKey.currentState.showBasicHint(text: ap.loginSuccess);
  }

  Future openLoginPage() async {
    var result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => LoginPage(),
      ),
    );
    checkLogin();
    if (result ?? false) {
      _getUserInfo();
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
      DialogUtils.showUpdateContent(
        context,
        "v${packageInfo.version}\n"
            "${app.updateNoteContent}",
      );
      Preferences.setString(
        Constants.PREF_CURRENT_VERSION,
        packageInfo.buildNumber,
      );
    }
    if (!kDebugMode) {
      VersionInfo versionInfo =
      await FirebaseRemoteConfigUtils.getVersionInfo();
      if (versionInfo != null)
        DialogUtils.showNewVersionContent(
          context: context,
          iOSAppId: '1536450161',
          defaultUrl: 'https://www.facebook.com/NKUST.ITC/',
          appName: app.appName,
          versionInfo: versionInfo,
        );
    }
  }
}
