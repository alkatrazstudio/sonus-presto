// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../folder_items/folder_item.dart';
import '../util/document_tree.dart';

class FolderItemDirectory extends FolderItem {
  DocumentTreeItemDirectory dir;

  FolderItemDirectory(this.dir);

  static Future<FolderItemDirectory?> fromUri(String uri) async {
    var docItem = await DocumentTreeItem.fromUri(uri);
    if(docItem == null)
      return null;
    return fromDocumentTreeItem(docItem);
  }

  static FolderItemDirectory? fromDocumentTreeItem(DocumentTreeItem docItem) {
    if(docItem is DocumentTreeItemDirectory)
      return FolderItemDirectory(docItem);
    return null;
  }

  @override
  bool isContainer() {
    return true;
  }

  @override
  int sortOrder() {
    return -10;
  }

  @override
  String displayName() {
    return dir.name;
  }

  @override
  String uri() {
    return dir.uri;
  }

  @override
  Future<bool> exists() async {
    var docItem = await DocumentTreeItem.fromUri(dir.uri);
    return docItem is DocumentTreeItemDirectory;
  }

  @override
  FolderItem parent() {
    return FolderItemDirectory(dir.parent());
  }

  int underscoreCount(String name) {
    var n = 0;
    for(var c in name.characters) {
      if(c != '_')
        break;
      n++;
    }
    return n;
  }

  @override
  Future<List<FolderItem>> fetchChildren() async {
    var entities = await dir.listChildren();

    var items = <FolderItem>[];

    for(var entity in entities) {
      var item = FolderItem.fromDocumentTreeItem(entity);
      if(item != null && !item.displayName().startsWith('.'))
        items.add(item);
    }

    items.sort((a, b) {
      var orderDiff = a.sortOrder() - b.sortOrder();
      if(orderDiff != 0)
        return orderDiff;
      var aName = a.displayName();
      var bName = b.displayName();
      orderDiff = underscoreCount(bName) - underscoreCount(aName);
      if(orderDiff != 0)
        return orderDiff;
      orderDiff = compareNatural(aName.toUpperCase(), bName.toUpperCase());
      if(orderDiff != 0)
        return orderDiff;
      return a.uri().compareTo(b.uri());
    });
    return items;
  }

  @override
  IconData icon() {
    return Icons.folder;
  }

  @override
  bool canFetchRecursiveChildren() {
    return true;
  }

  static FolderItemClassMeta classMeta() {
    return FolderItemClassMeta(
      className: (FolderItemDirectory).toString(),
      fromUriFunc: fromUri,
      fromDocumentTreeItemFunc: fromDocumentTreeItem,
      isSupportedUriFunc: null
    );
  }
}
