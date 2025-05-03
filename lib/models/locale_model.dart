// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/foundation.dart';

import '../util/prefs.dart';

class LocaleModel extends ChangeNotifier {
  static const systemLocaleCode = '';
  static const prefName = 'locale';

  String localeCode = systemLocaleCode;

  void init() {
    localeCode = Prefs.getString(prefName, '');
  }

  Future setLocaleCode(String code) async {
    if(code == localeCode)
      return;
    localeCode = code;
    notifyListeners();
    Prefs.setString(prefName, localeCode);
  }
}
