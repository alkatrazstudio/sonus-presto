// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../folder_items/folder_item.dart';
import '../models/dir_model.dart';
import '../util/listenable_sub.dart';
import '../widgets/folder_view_item.dart';
import '../widgets/future_with_spinner.dart';

class FolderViewItemRec {
  final FileSystemEntity entity;
  final String displayName;

  FolderViewItemRec(this.entity) :
    displayName = entity is Directory
      ? basename(entity.path)
      : basenameWithoutExtension(entity.path);
}

class FolderView extends StatefulWidget {
  FolderView({
    required this.dirItem,
    this.curFilePath,
    required this.onFileTap,
    required this.onDirChange,
    required this.onDirLongPress
  }):super(
    key: PageStorageKey((FolderView).toString() + ':' + dirItem.uri())
  ) {
    entries = dirItem.children();
  }

  final FolderItem dirItem;
  final String? curFilePath;
  final void Function(FolderItem newDirItem) onDirChange;
  final void Function(FolderItem dirItem) onDirLongPress;
  final void Function(FolderItem item, List<FolderItem> siblings) onFileTap;
  late final Future<List<FolderItem>> entries;

  @override
  FolderViewState createState() => FolderViewState();
}

class FolderViewState extends State<FolderView> {
  ListenableSub? locateFileSub;
  var controller = ScrollController();
  final itemScrollController = ItemScrollController();
  final itemPositionsListener = ItemPositionsListener.create();
  ListenableSub? itemPositionsListenerSub;
  var nVisibleItems = 0;

  Future<bool> scrollToItem(FolderItem? item) async {
    if(item == null)
      return false;
    if(widget.dirItem.uri() != item.parent().uri())
      return false;
    var entries = await widget.entries;
    var i = entries.indexWhere((entry) => entry.uri() == item.uri());
    if(i < 0)
      return true;

    await WidgetsBinding.instance?.endOfFrame;

    if(itemScrollController.isAttached) {
      var scrollToIndex = (i - nVisibleItems / 2 + 1).clamp(0, i).truncate();
      itemScrollController.scrollTo(
        index: scrollToIndex,
        duration: const Duration(seconds: 1)
      );
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    itemPositionsListenerSub = ListenableSub(itemPositionsListener.itemPositions, (){
      var positions = itemPositionsListener.itemPositions.value;
      if(positions.isEmpty)
        return;

      var min = positions
        .where((pos) => pos.itemTrailingEdge > 0)
        .reduce((minPos, pos) => pos.itemTrailingEdge < minPos.itemTrailingEdge ? pos : minPos)
        .index;
      var max = positions
        .where((pos) => pos.itemLeadingEdge < 1)
        .reduce((maxPos, pos) => pos.itemLeadingEdge > maxPos.itemLeadingEdge ? pos : maxPos)
        .index;

      nVisibleItems = max - min;
    });
  }

  @override
  void dispose() {
    locateFileSub?.dispose();
    itemPositionsListenerSub?.dispose();
    super.dispose();
  }

  FolderViewItem itemForRec(FolderItem folderItem, List<FolderItem> items) {
    if(folderItem.isContainer()) {
      return FolderViewItem(
        folderItem: folderItem,
        onTap: () => widget.onDirChange(folderItem),
        onLongPress: () => widget.onDirLongPress(folderItem)
      );
    }

    return FolderViewItem(
      folderItem: folderItem,
      onTap: () => widget.onFileTap(folderItem, items)
    );
  }

  @override
  Widget build(context) {
    var dirModel = context.read<DirModel>();

    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      if(await scrollToItem(dirModel.selectedItem))
        dirModel.resetSelectedItem();
      locateFileSub?.dispose();
      locateFileSub = ListenableSub(dirModel, () async {
        if(await scrollToItem(dirModel.selectedItem))
          dirModel.resetSelectedItem();
      });
    });

    return Column(
      children: [
        Flexible(
          child: FutureWithSpinner<List<FolderItem>>(
            future: widget.entries,
            childFunc: (entries) {
              return ScrollablePositionedList.builder(
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
                itemBuilder: (context, index) => itemForRec(entries[index], entries),
                itemCount: entries.length
              );
            }
          )
        )
      ]
    );
  }
}
