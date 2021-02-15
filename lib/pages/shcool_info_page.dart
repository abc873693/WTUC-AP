import 'dart:typed_data';

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/notification_data.dart';
import 'package:ap_common/models/phone_model.dart';
import 'package:ap_common/scaffold/notification_scaffold.dart';
import 'package:ap_common/scaffold/phone_scaffold.dart';
import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/scaffold/pdf_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common_firebase/utils/firebase_remote_config_utils.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
import 'package:flutter/material.dart';
import 'package:wtuc_ap/config/constants.dart';

class SchoolInfoPage extends StatefulWidget {
  static const String routerName = "/ShcoolInfo";

  @override
  SchoolInfoPageState createState() => SchoolInfoPageState();
}

class SchoolInfoPageState extends State<SchoolInfoPage>
    with SingleTickerProviderStateMixin {
  final phoneModelList = [
    PhoneModel("校長室", '07-342-6031#1102'),
    PhoneModel("副校長室一", '07-342-6031#1105'),
    PhoneModel("副校長室二", '07-342-6031#1107'),
    PhoneModel("教務處", '07-342-6031#2102'),
    PhoneModel("學生事務處", '07-342-6031#2202'),
    PhoneModel("研究發展處 ", '07-342-6031#3202'),
    PhoneModel("總務處 ", '07-342-6031#2552'),
    PhoneModel("國際暨兩岸合作處 ", '07-342-6031#2602'),
    PhoneModel("會計室 ", '07-342-6031#1305'),
    PhoneModel("華語中心", '07-342-6031#3302'),
    PhoneModel("進修部 ", '07-342-6031#3112'),
    PhoneModel("秘書室 ", '07-342-6031#1305'),
    PhoneModel("人事室 ", '07-342-6031#1212'),
    PhoneModel("圖書館 ", '07-342-6031#2751'),
    PhoneModel("資訊與教學科技中心 ", '07-342-6031#2819'),
    PhoneModel("教師發展中心 ", '07-342-6031#2918'),
    PhoneModel("公關室 ", '07-342-6031#1602'),
    PhoneModel("推廣部 ", '07-3458212'),
  ];

  NotificationState notificationState = NotificationState.loading;

  List<Notifications> notificationList = [];
  int page = 1;

  PhoneState phoneState = PhoneState.finish;

  PdfState pdfState = PdfState.loading;

  ApLocalizations ap;

  TabController controller;

  int _currentIndex = 0;

  static const DEFAULT_SCHEDULE =
      'https://a001.wzu.edu.tw/datas/upload/files/%E8%A1%8C%E4%BA%8B%E6%9B%86/109/109%E9%80%B2%E4%BF%AE%E9%83%A8%E9%83%A8%E8%A1%8C%E4%BA%8B%E6%9B%86_1090930%E4%BF%AE%E6%AD%A3%E7%89%88_.pdf';

  Uint8List pdfData;

  @override
  void initState() {
//    FirebaseAnalyticsUtils.instance.setCurrentScreen("SchoolInfoPage", "school_info_page.dart");
    controller = TabController(length: 2, vsync: this);
    _getSchedules();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(ap.schoolInfo),
        backgroundColor: ApTheme.of(context).blue,
      ),
      body: TabBarView(
        children: [
          PhoneScaffold(
            state: phoneState,
            phoneModelList: phoneModelList,
          ),
          PdfScaffold(
            state: pdfState,
            data: pdfData,
            fileName: 'schedule',
            onRefresh: () => _getSchedules(),
          ),
        ],
        controller: controller,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            controller.animateTo(_currentIndex);
          });
        },
        fixedColor: ApTheme.of(context).yellow,
        items: [
          BottomNavigationBarItem(
            icon: Icon(ApIcon.phone),
            title: Text(ap.phones),
          ),
          BottomNavigationBarItem(
            icon: Icon(ApIcon.dateRange),
            title: Text(ap.events),
          ),
        ],
      ),
    );
  }

  _getSchedules() async {
    String pdfUrl;
    if (FirebaseUtils.isSupportRemoteConfig) {
      try {
        final RemoteConfig remoteConfig = await RemoteConfig.instance;
        await remoteConfig.fetch(expiration: const Duration(hours: 1));
        await remoteConfig.activateFetched();
        pdfUrl = remoteConfig.getString(Constants.SCHEDULE_PDF_URL);
        if (pdfUrl != null && pdfUrl.isNotEmpty) {
          Preferences.setString(Constants.SCHEDULE_PDF_URL, pdfUrl);
        } else
          pdfUrl = Preferences.getString(
              Constants.SCHEDULE_PDF_URL, DEFAULT_SCHEDULE);
      } catch (exception) {
        pdfUrl =
            Preferences.getString(Constants.SCHEDULE_PDF_URL, DEFAULT_SCHEDULE);
      }
    } else {
      pdfUrl =
          Preferences.getString(Constants.SCHEDULE_PDF_URL, DEFAULT_SCHEDULE);
    }
    downloadFdf(pdfUrl);
  }

  void downloadFdf(String url) async {
    try {
      var response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (mounted)
        setState(() {
          pdfState = PdfState.finish;
          pdfData = response.data;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          pdfState = PdfState.error;
        });
      throw e;
    }
  }
}
