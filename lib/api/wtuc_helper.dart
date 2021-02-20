//dio
import 'dart:typed_data';

import 'package:ap_common/models/semester_data.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/cupertino.dart';
import 'package:crypto/crypto.dart';
import 'package:html/parser.dart';
import 'package:wtuc_ap/api/private_cookie_manager.dart';
import 'package:wtuc_ap/api/parser/wtuc_ap_parser.dart';
import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/models/score_data.dart';

// callback
import 'package:ap_common/callback/general_callback.dart';
import 'package:wtuc_ap/models/teaching_evaluation.dart';

import 'api_status_code.dart';
import 'helper.dart';

class WebApHelper {
  static Dio dio;
  static DioCacheManager _manager;
  static WebApHelper _instance;
  static CookieJar cookieJar;

  static int reLoginReTryCountsLimit = 3;
  static int reLoginReTryCounts = 0;

  bool ssoIsLogin = false;
  bool infoIsLogin = false;
  static String ssoHost = "https://sso.wzu.edu.tw";

  //cache key name
  static String get semesterCacheKey => "semesterCacheKey";

  static String get coursetableCacheKey =>
      "${Helper.username}_coursetableCacheKey";

  static String get scoresCacheKey => "${Helper.username}_scoresCacheKey";

  static String get userInfoCacheKey => "${Helper.username}_userInfoCacheKey";

  static WebApHelper get instance {
    if (_instance == null) {
      _instance = WebApHelper();
      dioInit();
    }
    return _instance;
  }

  static dioInit() {
    // Use PrivateCookieManager to overwrite origin CookieManager, because
    // Cookie name of the NKUST ap system not follow the RFC6265. :(
    dio = Dio();
    cookieJar = CookieJar();
    if (Helper.isSupportCacheData) {
      _manager =
          DioCacheManager(CacheConfig(baseUrl: "https://info.wzu.edu.tw"));
      dio.interceptors.add(_manager.interceptor);
    }
    dio.interceptors.add(PrivateCookieManager(cookieJar));
    dio.options.headers['user-agent'] =
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.89 Safari/537.36';
    dio.options.headers['Connection'] = 'close';
    dio.options.connectTimeout = 15000;
    dio.options.receiveTimeout = 15000;
  }

  Future<bool> wzuSSOLogin({
    @required String username,
    @required String password,
  }) async {
    Map<String, String> captchaMd5Data = {
      "9bcd5ab8fc729c83bdbbc784e3002d2f": "3",
      "543cd21e5aaa43d056d8068654c54b9a": "4",
      "5b24f8c135fee3ae3b14a1b9d0594704": "5",
      "2e81195ea486bd3704e94d8738cce591": "6",
      "88a220af9e880ed9089f64067a09e9b3": "7",
      "961ad1052e35d01d1a0cafc0917183a9": "8",
      "ed6b4795dd09ba4aab1d728657ac825a": "a",
      "ada5aca56c49ebdd600af0e74f1b91fd": "d",
      "f2a05ef72e154278ab4e6665d5200458": "e",
      "9f729a736e3590d919d52ae4c6bc2346": "f",
      "51203198720eb3c05e5acf73f209c285": "h",
      "969f09793ed0900a9d86768f013446c5": "i",
      "4d12aa55f5402f24a86cf848ccbdaad7": "m",
      "a41049298340e857d905972dca4d4732": "n",
      "de5ad6fec2d3e65cabdc79077aff44fd": "r",
      "9197aa82ba8921840737c118d1a12f79": "t"
    };

    Response loginPageRequest = await dio.get("$ssoHost/Portal/login.htm");
    List<Future<Response>> asyncPool = [];
    var captchaUrls = captchaUrlParser(loginPageRequest.data);
    for (int i = 0; i < captchaUrls.length; i++) {
      asyncPool.add(dio.get("$ssoHost${captchaUrls[i]}",
          options: Options(responseType: ResponseType.bytes)));
    }

    String captchaCode = "";
    for (int i = 0; i < asyncPool.length; i++) {
      var charCaptchaImage = await asyncPool[i];

      var t = md5.convert(charCaptchaImage.data).toString();
      captchaCode += captchaMd5Data[t];
    }
    //followRedirects: false

    // login request

    Response loginRequest = await dio.post('$ssoHost/Portal/loginprocess',
        data: {
          'USERID': username,
          'PASSWD': password,
          'SYSTEM_MAGICNUMBERTEXT': captchaCode,
          'SYSTEM_MAGICNUMBER': loginRequireParser(loginPageRequest.data)
        },
        options: Options(
            followRedirects: false,
            contentType: Headers.formUrlEncodedContentType,
            validateStatus: (status) {
              return status < 500;
            }));
    if (loginRequest.statusCode == 302) {
      ssoIsLogin = true;
      return true;
    }
    return false;
  }

  Future<bool> wzuApLogin({
    @required String username,
    @required String password,
  }) async {
    Response _ = await dio.post(
      "https://info.wzu.edu.tw/wtuc/portalidx.jsp",
      data: {"uid": username, "pwd": password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    // login status check
    Response loginCheckRequest = await dio.get(
        "https://info.wzu.edu.tw/wtuc/portalleft.jsp?sys_name=web&sys_kind=01");
    if (loginCheckRequest.data.substring(0, 1000).indexOf("alert(") > -1) {
      throw GeneralResponse(
        statusCode: ApiStatusCode.LOGIN_FAIL,
        message: "Login fail.",
      );
    }
    infoIsLogin = true;
    return true;
  }

  Future<Response> wtucApQuery(
    String queryQid,
    Map<String, String> queryData, {
    String cacheKey,
    Duration cacheExpiredTime,
    bool bytesResponse,
    String otherUrl,
  }) async {
    String url;
    if (otherUrl == null) {
      url =
          "https://info.wzu.edu.tw/wtuc/${queryQid.substring(0, 2)}_pro/$queryQid.jsp";
    } else {
      url = otherUrl;
    }
    print(url);
    Options _options;
    dynamic requestData;
    if (cacheKey == null) {
      _options = Options(contentType: Headers.formUrlEncodedContentType);
      if (bytesResponse != null) {
        _options.responseType = ResponseType.bytes;
      }
      requestData = queryData;
    } else {
      dio.options.headers["Content-Type"] = "application/x-www-form-urlencoded";
      Options otherOptions;
      if (bytesResponse != null) {
        otherOptions = Options(responseType: ResponseType.bytes);
      }
      _options = buildConfigurableCacheOptions(
        options: otherOptions,
        maxAge: cacheExpiredTime ?? Duration(seconds: 60),
        primaryKey: cacheKey,
      );
      requestData = formUrlEncoded(queryData);
    }
    Response<dynamic> request;

    if (bytesResponse != null) {
      request = await dio.post<List<int>>(
        url,
        data: requestData,
        options: _options,
      );
    } else {
      request = await dio.post(
        url,
        data: requestData,
        options: _options,
      );
    }

    if (wtucApQueryStatusParser(request.data) == 1) {
      if (Helper.isSupportCacheData) _manager.delete(cacheKey);
      reLoginReTryCounts += 1;
      await wzuApLogin(username: Helper.username, password: Helper.password);
      return wtucApQuery(queryQid, queryData, bytesResponse: bytesResponse);
    }

    reLoginReTryCounts = 0;

    return request;
  }

  Future<CourseData> wtucCoursetable(String years, String semesterValue) async {
    if (!Helper.isSupportCacheData) {
      var query = await wtucApQuery(
        "ag001",
        {"arg01": years, "arg02": semesterValue},
        bytesResponse: true,
      );
      return CourseData.fromJson(await wtucCoursetableParser(query.data));
    }
    var query = await wtucApQuery(
      "ag001",
      {"arg01": years, "arg02": semesterValue},
      cacheKey: "${coursetableCacheKey}_${years}_$semesterValue",
      cacheExpiredTime: Duration(hours: 6),
      bytesResponse: true,
    );
    var parsedData = await wtucCoursetableParser(query.data);
    if (parsedData["courses"].length == 0) {
      _manager.delete("${coursetableCacheKey}_${years}_$semesterValue");
    }
    return CourseData.fromJson(
      parsedData,
    );
  }

  Future<SemesterData> wtucSemesters() async {
    if (!Helper.isSupportCacheData) {
      var query = await wtucApQuery(
        null,
        {"fncid": "AG001"},
        otherUrl: 'https://info.wzu.edu.tw/wtuc/system/sys001_00.jsp',
      );
      return SemesterData.fromJson(wtucSemestersParser(query.data));
    }
    var query = await wtucApQuery(
      null,
      {"fncid": "AG001"},
      otherUrl: 'https://info.wzu.edu.tw/wtuc/system/sys001_00.jsp',
      cacheKey: semesterCacheKey,
      cacheExpiredTime: Duration(hours: 3),
    );
    var parsedData = wtucSemestersParser(query.data);
    if (parsedData["data"].length < 1) {
      //data error delete cache
      _manager.delete(semesterCacheKey);
    }

    return SemesterData.fromJson(parsedData);
  }

  Future<ScoreData> wtucScores(String years, String semesterValue) async {
    if (!Helper.isSupportCacheData) {
      var query = await wtucApQuery(
        "ag008",
        {"arg01": years, "arg02": semesterValue},
      );
      return ScoreData.fromJson(wtucScoresParser(query.data));
    }
    var query = await wtucApQuery(
      "ag008",
      {"arg01": years, "arg02": semesterValue},
      cacheKey: "${scoresCacheKey}_${years}_$semesterValue",
      cacheExpiredTime: Duration(hours: 6),
    );

    var parsedData = wtucScoresParser(query.data);
    if (parsedData["scores"].length == 0) {
      _manager.delete("${scoresCacheKey}_${years}_$semesterValue");
    }

    return ScoreData.fromJson(
      parsedData,
    );
  }

  Future<UserInfo> wtucUserInfo() async {
    if (!Helper.isSupportCacheData) {
      var query = await wtucApQuery("bg004", null);
      print(query.data);
      return UserInfo.fromJson(
        wtucUserInfoParser(query.data),
      );
    }
    var query = await wtucApQuery(
      "bg004",
      null,
      cacheKey: userInfoCacheKey,
      cacheExpiredTime: Duration(hours: 6),
    );

    var parsedData = wtucUserInfoParser(query.data);
    if (parsedData["id"] == null) {
      _manager.delete(userInfoCacheKey);
    }
    return UserInfo.fromJson(
      parsedData,
    );
  }

  Future<List<TeachingEvaluation>> wtucTeachingEvaluation() async {
    List<TeachingEvaluation> data = [];
    var query =
        await dio.post('https://info.wzu.edu.tw/wtuc/bg_pro/bg052_00.jsp');
    var html = query.data;
    if (html is Uint8List) {
      html = clearTransEncoding(html);
    }
    var document = parse(html);
    var trs = document.getElementsByTagName('tr');
    for (var tr in trs) {
      if (tr.id != null && tr.id.contains('tr')) {
        var tds = tr.getElementsByTagName('td');
        print('${tr.id} ${tr.text} ${tr.attributes['onclick'].split('\'')[1]}');
        data.add(
          TeachingEvaluation(
            title: tds[0].text,
            instructor: tds[5].text,
            state: tds[6].text,
            isFinish:
                tds[6].getElementsByTagName('font').first.attributes['color'] ==
                    "blue",
            id: tr.attributes['onclick'].split('\'')[1],
          ),
        );
      }
    }
    return data;
  }

  Future<void> sendTeachingEvaluation(
      TeachingEvaluation teachingEvaluation) async {
    print('id = ${teachingEvaluation.id}');
    dio.options.headers["Content-Type"] = "application/x-www-form-urlencoded";
    await dio.post(
      'https://info.wzu.edu.tw/wtuc/bg_pro/bg052_01.jsp',
      data: {
        'arg': teachingEvaluation.id,
      },
      options: Options(
        followRedirects: false,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    dio.options.headers["Content-Type"] = "application/x-www-form-urlencoded";
    var query = await dio.post(
      'https://info.wzu.edu.tw/wtuc/bg_pro/bg052_ins.jsp',
      options: Options(
        followRedirects: false,
        contentType: Headers.formUrlEncodedContentType,
      ),
      data: {
        "yradio1": "on",
        "hyvalue1": "23#0#N#Y#N#N#N#N#5#",
        "yradio2": "on",
        "hyvalue2": "24#0#N#Y#N#N#N#N#5#",
        "yradio3": "on",
        "hyvalue3": "26#0#N#Y#N#N#N#N#5#",
        "yradio4": "on",
        "hyvalue4": "27#0#N#Y#N#N#N#N#5#",
        "yradio5": "on",
        "hyvalue5": "29#0#N#Y#N#N#N#N#5#",
        "yradio6": "on",
        "hyvalue6": "31#0#N#Y#N#N#N#N#5#",
        "yradio7": "on",
        "hyvalue7": "32#0#N#Y#N#N#N#N#5#",
        "yradio8": "on",
        "hyvalue8": "33#0#N#Y#N#N#N#N#5#",
        "yradio9": "on",
        "hyvalue9": "34#0#N#Y#N#N#N#N#5#",
        "yradio10": "on",
        "hyvalue10": "35#0#N#Y#N#N#N#N#5#",
        "yradio11": "on",
        "hyvalue11": "36#0#N#Y#N#N#N#N#5#",
        "yradio12": "on",
        "hyvalue12": "38#0#N#Y#N#N#N#N#5#",
        "yradio13": "on",
        "hyvalue13": "39#0#N#Y#N#N#N#N#5#",
        "yradio14": "on",
        "hyvalue14": "40#0#N#Y#N#N#N#N#5#",
        "yradio15": "on",
        "hyvalue15": "41#0#N#Y#N#N#N#N#5#",
        "yradio16": "on",
        "hyvalue16": "43#0#N#Y#N#N#N#N#5#",
        "yradio17": "on",
        "hyvalue17": "44#0#N#Y#N#N#N#N#5#",
        "yradio18": "on",
        "hyvalue18": "45#0#N#Y#N#N#N#N#5#",
        'yradio19': "on",
        "hyvalue19": "46#0#N#Y#N#N#N#N#5#",
        "yradio20": "on",
        "hyvalue20": "52#0#N#N#N#N#N#Y#1#",
        "yradio21": "on",
        "hyvalue21": "47#0#N#Y#N#N#N#N#5#",
        "yradio22": "on",
        "hyvalue22": "48#0#N#Y#N#N#N#N#5#",
        "yradio23": "on",
        "hyvalue23": "49#0#N#Y#N#N#N#N#5#",
        "hquesn1": "51#1#Y#N#N#N#N#N##",
        "svalue": teachingEvaluation.id,
        "code_no_y": "23",
        "code_no_n": "0",
        "ques_no_y": "0",
        "ques_no_n": "1",
        "cho_lang": "C",
        "content":
            "23#0#N#Y#N#N#N#N#5#\$24#0#N#Y#N#N#N#N#5#\$26#0#N#Y#N#N#N#N#5#\$27#0#N#Y#N#N#N#N#5#\$29#0#N#Y#N#N#N#N#5#\$31#0#N#Y#N#N#N#N#5#\$32#0#N#Y#N#N#N#N#5#\$33#0#N#Y#N#N#N#N#5#\$34#0#N#Y#N#N#N#N#5#\$35#0#N#Y#N#N#N#N#5#\$36#0#N#Y#N#N#N#N#5#\$38#0#N#Y#N#N#N#N#5#\$39#0#N#Y#N#N#N#N#5#\$40#0#N#Y#N#N#N#N#5#\$41#0#N#Y#N#N#N#N#5#\$43#0#N#Y#N#N#N#N#5#\$44#0#N#Y#N#N#N#N#5#\$45#0#N#Y#N#N#N#N#5#\$46#0#N#Y#N#N#N#N#5#\$52#0#N#N#N#N#N#Y#1#\$47#0#N#Y#N#N#N#N#5#\$48#0#N#Y#N#N#N#N#5#\$49#0#N#Y#N#N#N#N#5#\$51#1#Y#N#N#N#N#N##"
      },
    );
    var html = query.data;
    if (html is Uint8List) {
      html = clearTransEncoding(html);
    }
    return null;
  }
}
