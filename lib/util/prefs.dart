// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static Future<String> getString(String key, [String def = '']) async {
    try{
      var prefs = await SharedPreferences.getInstance();
      return prefs.getString(key) ?? def;
    }catch(e){
      debugPrint(e.toString());
      return def;
    }
  }

  static Future<void> setString(String key, String val) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? curVal;
      try {
        curVal = prefs.getString(key);
      }catch(e){
        debugPrint(e.toString());
      }
      if(curVal == null || curVal != val)
        await prefs.setString(key, val);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  static Future<bool> getBool(String key, [bool def = false]) async {
    try{
      var prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? def;
    }catch(e){
      debugPrint(e.toString());
      return def;
    }
  }

  static Future<void> setBool(String key, bool val) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool? curVal;
      try {
        curVal = prefs.getBool(key);
      }catch(e){
        debugPrint(e.toString());
      }
      if(curVal == null || curVal != val)
        await prefs.setBool(key, val);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  static Future<int> getInt(String key, [int def = 0]) async {
    try{
      var prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key) ?? def;
    }catch(e){
      debugPrint(e.toString());
      return def;
    }
  }

  static Future<void> setInt(String key, int val) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? curVal;
      try {
        curVal = prefs.getInt(key);
      }catch(e){
        debugPrint(e.toString());
      }
      if(curVal == null || curVal != val)
        await prefs.setInt(key, val);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  static Future remove(String key) async {
    try{
      var prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }catch(e){
      debugPrint(e.toString());
    }
  }

  static Future<Set<String>> keys() async {
    try{
      var prefs = await SharedPreferences.getInstance();
      return prefs.getKeys();
    }catch(e){
      debugPrint(e.toString());
      return {};
    }
  }
}
