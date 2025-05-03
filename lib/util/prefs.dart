// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

class Prefs {
  static late SharedPreferencesWithCache _prefs;

  static Future<void> init() async {
    await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: await SharedPreferences.getInstance(),
      sharedPreferencesAsyncOptions: const SharedPreferencesOptions(),
      migrationCompletedKey: 'migrationCompleted'
    );
    _prefs = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  }

  static String getString(String key, [String def = '']) {
    try{
      return _prefs.getString(key) ?? def;
    }catch(e){
      debugPrint(e.toString());
      return def;
    }
  }

  static Future<void> setString(String key, String val) async {
    try {
      String? curVal;
      try {
        curVal = _prefs.getString(key);
      }catch(e){
        debugPrint(e.toString());
      }
      if(curVal == null || curVal != val)
        await _prefs.setString(key, val);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  static bool getBool(String key, [bool def = false]) {
    try{
      return _prefs.getBool(key) ?? def;
    }catch(e){
      debugPrint(e.toString());
      return def;
    }
  }

  static Future<void> setBool(String key, bool val) async {
    try {
      bool? curVal;
      try {
        curVal = _prefs.getBool(key);
      }catch(e){
        debugPrint(e.toString());
      }
      if(curVal == null || curVal != val)
        await _prefs.setBool(key, val);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  static int getInt(String key, [int def = 0]) {
    try{
      return _prefs.getInt(key) ?? def;
    }catch(e){
      debugPrint(e.toString());
      return def;
    }
  }

  static Future<void> setInt(String key, int val) async {
    try {
      int? curVal;
      try {
        curVal = _prefs.getInt(key);
      }catch(e){
        debugPrint(e.toString());
      }
      if(curVal == null || curVal != val)
        await _prefs.setInt(key, val);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  static Future remove(String key) async {
    try{
      await _prefs.remove(key);
    }catch(e){
      debugPrint(e.toString());
    }
  }
}
