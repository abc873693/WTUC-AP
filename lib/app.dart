import 'dart:typed_data';

import 'package:ap_common/config/analytics_constants.dart';
import 'package:ap_common/pages/about_us_page.dart';
import 'package:ap_common/pages/open_source_page.dart';
import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/constants.dart';
import 'pages/home_page.dart';
import 'utils/app_localizations.dart';
import 'widgets/share_data_widget.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  FirebaseAnalytics analytics;

  ThemeData themeData;
  Uint8List pictureBytes;
  bool offlineLogin = false;
  bool hasBusViolationRecords = false;

  ThemeMode themeMode = ThemeMode.system;

  Locale locale;

  logout() {
    setState(() {
      this.offlineLogin = false;
      this.pictureBytes = null;
    });
  }

  @override
  void initState() {
    analytics = FirebaseUtils.init();
    themeMode = ThemeMode
        .values[Preferences.getInt(Constants.PREF_THEME_MODE_INDEX, 0)];
    FirebaseAnalyticsUtils.instance.logThemeEvent(themeMode);
    FirebaseAnalyticsUtils.instance
        .setUserProperty(AnalyticsConstants.ICON_STYLE, ApIcon.code);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
    FirebaseAnalyticsUtils.instance.logThemeEvent(themeMode);
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return ShareDataWidget(
      data: this,
      child: ApTheme(
        themeMode,
        child: MaterialApp(
          localeResolutionCallback:
              (Locale locale, Iterable<Locale> supportedLocales) {
            String languageCode = Preferences.getString(
              Constants.PREF_LANGUAGE_CODE,
              ApSupportLanguageConstants.SYSTEM,
            );
            if (languageCode == ApSupportLanguageConstants.SYSTEM)
              return this.locale = ApLocalizations.delegate.isSupported(locale)
                  ? locale
                  : Locale('en');
            else
              return Locale(
                languageCode,
                languageCode == ApSupportLanguageConstants.ZH ? 'TW' : null,
              );
          },
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          routes: <String, WidgetBuilder>{
            Navigator.defaultRouteName: (context) => HomePage(),
            AboutUsPage.routerName: (BuildContext context) =>
                HomePageState.aboutPage(context),
            OpenSourcePage.routerName: (BuildContext context) =>
                OpenSourcePage(),
          },
          theme: ApTheme.light,
          darkTheme: ApTheme.dark,
          themeMode: themeMode,
          locale: locale,
          navigatorObservers: [
            if (FirebaseUtils.isSupportAnalytics)
              FirebaseAnalyticsObserver(analytics: analytics),
          ],
          localizationsDelegates: [
            const AppLocalizationsDelegate(),
            ApLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('en', 'US'), // English
            const Locale('zh', 'TW'), // Chinese
          ],
        ),
      ),
    );
  }

  void update(ThemeMode mode) {
    setState(() {
      themeMode = mode;
    });
    FirebaseAnalyticsUtils.instance.logThemeEvent(themeMode);
  }

  void loadLocale(Locale locale) {
    this.locale = locale;
    setState(() {
      AppLocalizationsDelegate().load(locale);
      ApLocalizations.load(locale);
    });
  }
}
