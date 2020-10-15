//dio
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:wtuc_ap/api/private_cookie_manager.dart';
import 'package:wtuc_ap/api/parser/wtuc_ap_parser.dart';

// callback
import 'package:ap_common/callback/general_callback.dart';

import 'helper.dart';

class WebApHelper {
  static Dio dio;
  static DioCacheManager _manager;
  static WebApHelper _instance;
  static CookieJar cookieJar;

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
    Map<String, String> captcha_md5_data = {
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

    Response login_page_request = await dio.get("$ssoHost/Portal/login.htm");
    List<Future<Response>> async_pool = [];
    var captcha_urls = captchaUrlParser(login_page_request.data);
    for (int i = 0; i < captcha_urls.length; i++) {
      async_pool.add(dio.get("$ssoHost${captcha_urls[i]}",
          options: Options(responseType: ResponseType.bytes)));
    }

    String captcha_code = "";
    for (int i = 0; i < async_pool.length; i++) {
      var char_captcha_image = await async_pool[i];

      var t = md5.convert(char_captcha_image.data).toString();
      captcha_code += captcha_md5_data[t];
    }
    //followRedirects: false

    // login request

    Response login_request = await dio.post('$ssoHost/Portal/loginprocess',
        data: {
          'USERID': username,
          'PASSWD': password,
          'SYSTEM_MAGICNUMBERTEXT': captcha_code,
          'SYSTEM_MAGICNUMBER': loginRequireParser(login_page_request.data)
        },
        options: Options(
            followRedirects: false,
            contentType: Headers.formUrlEncodedContentType,
            validateStatus: (status) {
              return status < 500;
            }));
    if (login_request.statusCode == 302) {
      ssoIsLogin = true;
      return true;
    }
    return false;
  }
}
