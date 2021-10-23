// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/foundation.dart';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:collection/collection.dart';

import '../util/prefs.dart';

enum SchemeVariant {
  system,
  systemBlack,
  light,
  dark,
  black
}

class SchemeModel extends ChangeNotifier {
  static const defaultScheme = FlexScheme.amber;
  static const defaultSchemeVariant = SchemeVariant.system;
  static const prefScheme = 'theme';
  static const prefSchemeVariant = 'themeVariant';

  FlexScheme scheme = defaultScheme;
  SchemeVariant schemeVariant = defaultSchemeVariant;

  Future init() async {
    var schemeName = await Prefs.getString(prefScheme);
    scheme = schemeFromName(schemeName);
    var schemeVariantName = await Prefs.getString(prefSchemeVariant);
    schemeVariant = schemeVariantFromName(schemeVariantName);
    notifyListeners();
  }

  Future setScheme(FlexScheme newScheme) async {
    scheme = newScheme;
    notifyListeners();
    await Prefs.setString(prefScheme, scheme.toString());
  }

  Future setSchemeVariant(SchemeVariant newSchemeVariant) async {
    schemeVariant = newSchemeVariant;
    notifyListeners();
    await Prefs.setString(prefSchemeVariant, schemeVariant.toString());
  }

  static FlexScheme schemeFromName(String schemeName) {
    var scheme = FlexScheme.values.firstWhereOrNull((scheme) => scheme.toString() == schemeName);
    scheme ??= SchemeModel.defaultScheme;
    return scheme;
  }

  static SchemeVariant schemeVariantFromName(String variantName) {
    var schemeVariant = SchemeVariant.values.firstWhereOrNull((v) => v.toString() == variantName);
    schemeVariant ??= SchemeModel.defaultSchemeVariant;
    return schemeVariant;
  }
}
