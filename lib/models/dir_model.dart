// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/foundation.dart';

import '../folder_items/folder_item.dart';

class DirModel extends ChangeNotifier {
  static final instance = DirModel();

  FolderItem curDirItem = FolderItem.invalid;
  FolderItem? selectedItem;

  void setDir(FolderItem newDirItem, [FolderItem? newSelectedFolderItem]) {
    if(newDirItem.uri() == curDirItem.uri() && newSelectedFolderItem == null)
      return;

    curDirItem = newDirItem;
    if(newSelectedFolderItem != null)
      selectedItem = newSelectedFolderItem;
    notifyListeners();
  }

  void resetSelectedItem() {
    selectedItem = null;
  }
}
