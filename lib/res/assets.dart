import 'dart:convert';

import 'package:flutter/services.dart';

class ImageAssets {
  static const String basePath = 'assets/images';

  static String section = '$basePath/section.webp';
  static const schoolMap = '$basePath/map.webp';
}

class FileAssets {
  static const String basePath = 'assets/';

  static const String changelog = 'changelog.json';
  static const String carParkArea = '$basePath/car_park_area.json';

  static Future<Map<String, dynamic>> get changelogData async {
    return jsonDecode(await rootBundle.loadString(changelog));
  }
}
