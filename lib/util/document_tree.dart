// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/services.dart';

import 'package:path/path.dart';

abstract class DocumentTree {
  static const platform = MethodChannel('sonuspresto.alkatrazstudio.net/documentTree');

  static Future<DocumentTreeItemDirectory> requestAccess() async {
    var docResult = await platform.invokeMethod<Map<Object?, Object?>>('requestAccess');
    if(docResult == null)
      throw Exception('requestAccess returned null');

    var docItem = DocumentTreeItem.fromDocumentTreeResult(docResult);
    if(docItem is DocumentTreeItemDirectory)
      return docItem;
    throw Exception('requestAccess not returned DocumentTreeItemDirectory');
  }

  static Future<bool> hasAccess(String uri) async {
    return await platform.invokeMethod<bool>('hasAccess', uri) ?? false;
  }

  static Future releaseAccess() async {
    return await platform.invokeMethod<void>('releaseAccess');
  }

  static Future<List<DocumentTreeItem>> listChildren(String uri) async {
    var result = await platform.invokeMethod<List<Object?>>('listChildren', uri);
    if(result == null)
      return [];
    var docs = result.cast<Map<Object?, Object?>>().map(DocumentTreeItem.fromDocumentTreeResult).toList();
    return docs;
  }

  static Future<Map<Object?, Object?>> getDoc(String uri) async {
    var doc = await platform.invokeMethod<Map<Object?, Object?>>('getDoc', uri);
    if(doc == null)
      throw Exception('getDoc returned null');
    return doc;
  }

  static Future<List<String>> readLines(String uri) async {
    var lines = (await platform.invokeMethod<List<Object?>?>('readLines', uri))?.cast<String>();
    return lines ?? [];
  }

  static Future<bool> deleteDoc(String uri) async {
    return await platform.invokeMethod<bool>('deleteDoc', uri) ?? false;
  }
}

abstract class DocumentTreeItem {
  static const pathSep = '%2F';
  static const deviceSep = ':';
  static final invalid = DocumentTreeItemDirectory('');

  final String uri;
  late final String name;

  DocumentTreeItem(this.uri) {
    name = extractName(uri);
  }

  static String extractName(String uri) {
    var decodedUri = Uri.decodeFull(uri);
    var name = basename(decodedUri).split(deviceSep).last;
    return name;
  }

  static bool isRootUri(String uri) {
    var uriObj = Uri.parse(uri);
    if(uriObj.pathSegments.length < 4)
      return true;
    var rootPart = uriObj.pathSegments[1];
    var pathPart = uriObj.pathSegments[3];
    return rootPart == pathPart;
  }

  static DocumentTreeItem fromDocumentTreeResult(Map<Object?, Object?> result) {
    var uri = result['uri'] as String;
    var isDirectory = result['isDirectory'] as bool;
    var item = isDirectory ? DocumentTreeItemDirectory(uri) : DocumentTreeItemFile(uri);
    return item;
  }

  static Future<DocumentTreeItem?> fromUri(String uri) async {
    try {
      if(uri.isEmpty)
        return null;
      var result = await DocumentTree.getDoc(uri);
      var doc = fromDocumentTreeResult(result);
      return doc;
    } catch(e) {
      return null;
    }
  }

  static String resolvePath(String fromUri, String path) {
    var pathParts = path.split('/');
    var uri = fromUri;
    for(var pathPart in pathParts) {
      if(pathPart == '.')
        continue;

      if(pathPart == '..') {
        if(isRootUri(uri))
          continue;
        var i = uri.lastIndexOf(pathSep);
        if(i >= 0)
          uri = uri.substring(0, i);
        continue;
      }

      uri = uri + pathSep + Uri.encodeFull(pathPart);
    }

    return uri;
  }

  DocumentTreeItemDirectory parent() {
    var parentUri = resolvePath(uri, '..');
    var dir = DocumentTreeItemDirectory(parentUri);
    return dir;
  }
}

class DocumentTreeItemDirectory extends DocumentTreeItem {
  DocumentTreeItemDirectory(super.uri);

  Future<List<DocumentTreeItem>> listChildren() async {
    try{
      var items = await DocumentTree.listChildren(uri);
      return items;
    }catch(e){
      return [];
    }
  }
}

class DocumentTreeItemFile extends DocumentTreeItem {
  DocumentTreeItemFile(super.uri);

  Future<List<String>> readLines() async {
    try{
      var lines = DocumentTree.readLines(uri);
      return lines;
    } catch(e) {
      return [];
    }
  }
}
