import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(Locale locale) {
    init(locale);
  }

  Map get _vocabularies {
    return _localizedValues[locale.languageCode] ?? _localizedValues['en'];
  }

  String get appName => _vocabularies['app_name'];

  String get updateNoteContent => _vocabularies['update_note_content'];

  String get aboutOpenSourceContent =>
      _vocabularies['about_open_source_content'];

  String get scoreClickHint => _vocabularies['scoreClickHint'];

  String get teachingEvaluation => _vocabularies['teachingEvaluation'];

  String get quicklyFillIn => _vocabularies['quicklyFillIn'];

  String get filling => _vocabularies['filling'];

  String get needChangePasswordHint => _vocabularies['needChangePasswordHint'];

  String get changePasswordDescription =>
      _vocabularies['changePasswordDescription'];

  String get changePasswordExceptionDescription =>
      _vocabularies['changePasswordExceptionDescription'];

  String get goToSSOHint => _vocabularies['goToSSOHint'];

  static init(Locale locale) {
    AppLocalizations.locale = locale;
  }

  static Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'WTUC AP',
      'update_note_content': '* Fix course table error.',
      'about_open_source_content':
          'https://github.com/abc873693/WTUC-AP\n\nThis project is licensed under the terms of the MIT license:\nThe MIT License (MIT)\n\nCopyright © 2020 Rainvisitor\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
      'scoreClickHint': 'Click course name to show detail data.',
      'teachingEvaluation': 'Teaching Evaluation',
      'quicklyFillIn': 'Quickly Fill In',
      'filling': 'Filling',
      'needChangePasswordHint':
          'According to Wenzao\'s ISO27001 Information Security Policy, \npasswords must be changed every 90 days. Please change your password immediately.',
      'changePasswordDescription':
          '【Password Changing Policy】\n1.At least 8 characters, 20 characters at most.\n2.Following special character must not be included ：『 | 』、『 \ 』、『 ~ 』、『 @ 』、『 < 』、 『 > 』、『 ` 』、『 " 』、『 \' 』、『 。』、『 : 』、『 』、space\n3.Passwords can\'t be all numbers, and can\'t be the same as the previous password.\n(according to the meeting decision of 107 academic year Information Development Committee)\n4.After the password change is completed，please pay attention to the following matters：\n(1)The [e-Platform] password in the classroom and the EMAIL password will take effect after 30 minutes.\n(2)Wenzao Google GAP passwords take effect at 7 am, 1 pm and 11 pm daily.\n\n<< In order to sync your password to Library System, please make sure do not include the following password patterns>>：\n1. A character that is consecutively repeated three or more times.(for example: 333, aaa, 333ab, ab3333)\n2. A set of up to four characters is that is consecutively repeated two or more times. (for example: abab, 1212, 123123, abcabc, ab1212)\n3. PIN must be alphanumeric characters only, no punctuations or other symbols.',
      'changePasswordExceptionDescription':
          'If you can’t change your password, please try to change it on the web version of the school administration system',
      'goToSSOHint': 'Goto web version to change',
    },
    'zh': {
      'app_name': '文藻校務通',
      'update_note_content': '* 修正課表錯誤',
      'about_open_source_content':
          'https://github.com/abc873693/WTUC-AP\n\n本專案採MIT 開放原始碼授權：\nThe MIT License (MIT)\n\nCopyright © 2020 Rainvisitor\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
      'scoreClickHint': '點擊課程名稱顯示詳細資料',
      'teachingEvaluation': '教學評鑑輸入作業',
      'quicklyFillIn': '一鍵填寫',
      'filling': '正在填寫中',
      'needChangePasswordHint':
          '基於本校ISO27001資訊安全管理規範，系統檢測您已超過90天未進行變更，\n建請您立即進行密碼變更',
      'changePasswordDescription':
          '【校務系統變更密碼原則 注意事項】\n1.密碼長度最少8碼，最多20碼\n2.密碼請勿設定下列之特殊字元：『 | 』、『 \ 』、『 ~ 』、『 @ 』、 『 < 』、『 > 』、『 ` 』、『 " 』、『 \' 』、『 。』、『 : 』、『 』、(空白鍵)\n3.密碼變更不得為全數字及不得與現行密碼一樣(依107學年度第2次資訊發展委員會決議)\n4.密碼變更完成後，請注意以下事項：\n(1)教室中的[資訊講台]密碼及EMAIL密碼於30分鐘後始生效。\n(2)Google GAP密碼於每日上午七點、下午一點及十一點執行同步生效。\n\n<<如欲同步更新圖書館密碼，請務必排除以下密碼型態，否則將無法同步更新至圖書館系統>>\n1.密碼中同一文(數)字連續出現3次或以上，例 如333、aaa、333ab、ab3333等。\n2.密碼中同一種組合模式出現2次或以上，例 如abab、1212、123123、abcabc、123ab123、ab1212等。\n3.密碼中包含特殊符號：例如頓號、句號等。',
      'changePasswordExceptionDescription': '如果無法變更密碼，請嘗試至校務系統網頁版修改',
      'goToSSOHint': '至網頁版本修改',
    },
  };
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
