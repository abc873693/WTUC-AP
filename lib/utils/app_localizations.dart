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
      'update_note_content':
          '* Fix course table error.',
      'about_open_source_content':
          'https://github.com/abc873693/WTUC-AP\n\nThis project is licensed under the terms of the MIT license:\nThe MIT License (MIT)\n\nCopyright © 2020 Rainvisitor\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
      'scoreClickHint': 'Click course name to show detail data.',
      'teachingEvaluation': 'Teaching Evaluation',
      'quicklyFillIn': 'Quickly Fill In',
      'filling': 'Filling',
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
