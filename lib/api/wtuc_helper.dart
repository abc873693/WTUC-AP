//dio
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:wtuc_ap/api/private_cookie_manager.dart';

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
}
