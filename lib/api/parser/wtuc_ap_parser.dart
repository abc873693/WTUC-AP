import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;

String clearTransEncoding(List<int> htmlBytes) {
  // htmlBytes is fixed-length list, need copy.
  var tempData = new List<int>.from(htmlBytes);

  //Add /r/n on first word.
  tempData.insert(0, 10);
  tempData.insert(0, 13);

  int startIndex = 0;
  for (int i = 0; i < tempData.length - 1; i++) {
    //check i and i+1 is /r/n
    if (tempData[i] == 13 && tempData[i + 1] == 10) {
      if (i - startIndex - 2 <= 4 && i - startIndex - 2 > 0) {
        //check in this range word is number or A~F (Hex)
        int removeCount = 0;
        for (int _strIndex = startIndex + 2; _strIndex < i; _strIndex++) {
          if ((tempData[_strIndex] > 47 && tempData[_strIndex] < 58) ||
              (tempData[_strIndex] > 64 && tempData[_strIndex] < 71) ||
              (tempData[_strIndex] > 96 && tempData[_strIndex] < 103)) {
            removeCount++;
          }
        }
        if (removeCount == i - startIndex - 2) {
          tempData.removeRange(startIndex, i + 2);
        }
        //Subtract offset
        i -= i - startIndex - 2;
        startIndex -= i - startIndex - 2;
      }
      startIndex = i;
    }
  }

  return utf8.decode(tempData, allowMalformed: true);
}

List<String> captchaUrlParser(dynamic html) {
  if (html is Uint8List) {
    html = clearTransEncoding(html);
  }
  var document = parse(html);
  var img_urls = document.getElementById('table1').getElementsByTagName("img");
  List<String> result = [];
  for (int i = 0; i < img_urls.length; i++) {
    result.add(img_urls[i].attributes['src']);
  }
  return result;
}

String loginRequireParser(dynamic html) {
  if (html is Uint8List) {
    html = clearTransEncoding(html);
  }
  var document = parse(html);
  var all_input = document.getElementsByTagName('input');
  for (int i = 0; i < all_input.length; i++) {
    if (all_input[i].attributes['name'] == 'SYSTEM_MAGICNUMBER') {
      return all_input[i].attributes['value'];
    }
  }
}
