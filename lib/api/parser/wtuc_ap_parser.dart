import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:ap_common/utils/crashlytics_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:wtuc_ap/api/api_status_code.dart';
import 'package:wtuc_ap/api/helper.dart';

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
  var imgUrls = document.getElementById('table1').getElementsByTagName("img");
  List<String> result = [];
  for (int i = 0; i < imgUrls.length; i++) {
    result.add(imgUrls[i].attributes['src']);
  }
  return result;
}

String loginRequireParser(dynamic html) {
  if (html is Uint8List) {
    html = clearTransEncoding(html);
  }
  var document = parse(html);
  var allInput = document.getElementsByTagName('input');
  for (int i = 0; i < allInput.length; i++) {
    if (allInput[i].attributes['name'] == 'SYSTEM_MAGICNUMBER') {
      return allInput[i].attributes['value'];
    }
  }
  return null;
}

String formUrlEncoded(Map<String, dynamic> data) {
  if (data == null) {
    return null;
  }
  String temp = "";
  data.forEach((key, value) {
    if (temp != null) {
      temp += "&";
    }
    temp += "$key=$value";
  });
  return temp;
}

Future<Map<String, dynamic>> wtucCoursetableParser(dynamic html) async {
  if (html is Uint8List) {
    html = clearTransEncoding(html);
  }

  Map<String, dynamic> data = {
    "courses": [],
    "timeCodes": [],
  };
  Map<String, dynamic> courseTable = {
    "timeCodes": [],
    "Monday": [],
    "Tuesday": [],
    "Wednesday": [],
    "Thursday": [],
    "Friday": [],
    "Saturday": [],
    "Sunday": []
  };
  var document = parse(html);

  if (document.getElementsByTagName("table").length < 3) {
    //table not found
    return data;
  }

  //make timetable
  var secondTable =
      document.getElementsByTagName("table")[3].getElementsByTagName("tr");
  try {
    //remark:Best split is regex but... Chinese have some difficulty Q_Q
    for (int i = 1; i < secondTable.length; i++) {
      if (i == 11) {
        // bypass "night" content td.
        continue;
      }
      var _temptext =
          secondTable[i].getElementsByTagName('td')[0].text.replaceAll(" ", "");
      final title = _temptext
          .substring(0, _temptext.length - 9)
          .replaceAll(String.fromCharCode(160), "")
          .replaceAll(" ", "");
      var courseTime = _temptext
          .substring(_temptext.length - 9)
          .replaceAll(String.fromCharCode(160), "");
      data['timeCodes'].add(
        {
          "title": title,
          "startTime":
              "${courseTime.split('-')[0].substring(0, 2)}:${courseTime.split('-')[0].substring(2, 4)}",
          "endTime":
              "${courseTime.split('-')[1].substring(0, 2)}:${courseTime.split('-')[1].substring(2, 4)}",
        },
      );
    }
  } catch (e, s) {
    if (!kIsWeb || (Platform.isAndroid || Platform.isIOS))
      await FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: document.getElementsByTagName("table")[1].text,
      );
  }
  //make each day.
  List weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  try {
    for (int key = 0; key < weekdays.length; key++) {
      for (int eachSession = 1;
          eachSession < data['timeCodes'].length + 1;
          eachSession++) {
        if (eachSession == 11) {
          // bypass "night" content td.
          continue;
        }

        var eachDays = document
            .getElementsByTagName("table")[3]
            .getElementsByTagName("tr")[eachSession]
            .getElementsByTagName("td")[key + 1];

        if (eachDays.outerHtml.length <= 40) {
          continue;
        }
        var splitData = (eachDays.outerHtml
            .substring(35, eachDays.outerHtml.length - 11)
            .split("<br>"));

        for (int i = 0; i < splitData.length; i++) {
          splitData[i] = splitData[i].replaceAll("&nbsp;", "");
          splitData[i] = splitData[i].replaceAll(" ", "");
        }
        var _eachDaysDate = document
            .getElementsByTagName("table")[3]
            .getElementsByTagName("tr")[eachSession]
            .getElementsByTagName("td")[0]
            .outerHtml;

        var courseTime = _eachDaysDate
            .substring(_eachDaysDate.indexOf('nowrap="">') + 10,
                _eachDaysDate.indexOf("</td>"))
            .split("<br>");

        if (splitData.length <= 1) {
          continue;
        }

        String title = splitData[0].replaceAll("\n", "");
        if (title.lastIndexOf(">") > -1) {
          title = title
              .substring(title.lastIndexOf(">") + 1, title.length)
              .replaceAll("&nbsp;", '')
              .replaceAll(";", '');
        }
        courseTable[weekdays[key]].add({
          'title': title,
          'date': {
            "startTime":
                "${courseTime[1].split('-')[0].substring(0, 2)}:${courseTime[1].split('-')[0].substring(2, 4)}",
            "endTime":
                "${courseTime[1].split('-')[1].substring(0, 2)}:${courseTime[1].split('-')[1].substring(2, 4)}",
            'section': eachSession - (eachSession >= 11 ? 2 : 1)
          },
          'location': {"room": splitData[3]},
          'instructors': splitData[2].split(","),
        });
      }
    }
  } catch (e, s) {
    if (!kIsWeb || (Platform.isAndroid || Platform.isIOS))
      await FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: document.getElementsByTagName("table")[3].text,
      );
  }
  Map<String, Map<String, dynamic>> _temp = {};
  //Use Map to avoid duplicate
  // use coursetable to create courses.
  for (int i = 0; i < weekdays.length; i++) {
    var weekdayCourses = courseTable[weekdays[i]];
    for (int timeCodeIndex = 0;
        timeCodeIndex < weekdayCourses.length;
        timeCodeIndex++) {
      final title = weekdayCourses[timeCodeIndex]['title'];
      final location = weekdayCourses[timeCodeIndex]['location'];
      final sectionIndex = weekdayCourses[timeCodeIndex]['date']['section'];
      final key = '${title}_$location';
      if (_temp[key] != null) {
        _temp[key]['sectionTimes'].add({
          "index": sectionIndex,
          "weekday": i + 1,
        });

        continue;
      }
      //
      _temp[key] = {
        'title': title,
        'sectionTimes': [
          {
            "index": sectionIndex,
            "weekday": i + 1,
          }
        ],
        "instructors": weekdayCourses[timeCodeIndex]['instructors'],
        'location': weekdayCourses[timeCodeIndex]['location']
      };
    }
  }
  _temp.values.forEach((element) {
    data['courses'].add(element);
  });

  return data;
}

int wtucApQueryStatusParser(dynamic html) {
  /*
    Retrun type Int
    1: need relogin.
    */
  if (html is Uint8List) {
    html = clearTransEncoding(html);
  }
  if (html.indexOf("parent.location.href='../index.html'") > -1 ||
      html.indexOf(">alert('Please Logon'") > -1) {
    return 1;
  }
  return 0;
}

Map<String, dynamic> wtucSemestersParser(String html) {
  Map<String, dynamic> data = {
    "data": [],
    "default": {"year": "108", "value": "2", "text": "108學年第二學期(Parse失敗)"}
  };
  var document = parse(html);

  var ymsElements =
      document.getElementById("yms").getElementsByTagName("option");
  if (ymsElements.length < 5) {
    //parse fail.
    return data;
  }
  for (int i = 0; i < ymsElements.length; i++) {
    data['data'].add({
      "year": ymsElements[i].attributes["value"].split(",")[0],
      "value": ymsElements[i].attributes["value"].split(",")[1],
      "text": ymsElements[i].text
    });
    if (ymsElements[i].attributes["selected"] != null) {
      //set default
      data['default'] = {
        "year": ymsElements[i].attributes["value"].split(",")[0],
        "value": ymsElements[i].attributes["value"].split(",")[1],
        "text": ymsElements[i].text
      };
    }
  }
  return data;
}

Map<String, dynamic> wtucScoresParser(String html) {
  var document = parse(html);

  Map<String, dynamic> data = {
    "scores": [],
    "detail": {
      "conduct": null,
      "classRank": null,
      "departmentRank": null,
      'average': null
    }
  };

  final table = document.getElementsByTagName("table");
  if (table.length >= 2) {
    try {
      final trs = table[2].getElementsByTagName("tr");
      for (int scoresIndex = 1; scoresIndex < trs.length; scoresIndex++) {
        var td = trs[scoresIndex].getElementsByTagName('td');
        data['scores'].add({
          "title": td[1].text,
          'units': td[3].text,
          'hours': "",
          'required': "",
          'at': td[3].text,
          'middleScore': td[5].text,
          'generalScore': td[4].text,
          'finalScore': td[6].text,
          'semesterScore': td[10].text,
          'remark': "",
        });
      }
    } catch (e, s) {
      CrashlyticsUtils.instance.recordError(
        GeneralResponse.unknownError(),
        s,
        reason: document.text,
      );
    }
  } else {
    final b = document.getElementsByTagName('b');
    if (b.length > 0)
      throw GeneralResponse(
        statusCode: ApiStatusCode.SCORE_ERROR,
        message: b.first.text,
      );
    else {
      CrashlyticsUtils.instance.recordError(
        GeneralResponse.unknownError(),
        StackTrace.current,
        reason: document.text,
      );
      throw GeneralResponse.unknownError();
    }
  }

  return data;
}

Map<String, dynamic> wtucUserInfoParser(dynamic html) {
  if (html is Uint8List) {
    html = clearTransEncoding(html);
  }
  var document = parse(html);
  Map<String, dynamic> data = {
    "educationSystem": null,
    "department": null,
    "className": null,
    "id": null,
    "name": null,
    "pictureUrl": null
  };
  var tableDom = document.getElementsByTagName("table") ?? [];
  if (tableDom.length < 2) {
    return data;
  }
  var trDom =
      document.getElementsByTagName("table")[1].getElementsByTagName("tr") ??
          [];
  if (trDom.length < 5) {
    return data;
  }
  data["name"] = trDom[1].getElementsByTagName("td")[1].text ?? null;
  data["className"] = trDom[2].getElementsByTagName("td")[1].text ?? null;
  data["id"] = trDom[3].getElementsByTagName("td")[1].text ?? null;
  return data;
}
