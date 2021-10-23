// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:collection/collection.dart';

import '../folder_items/folder_item.dart';
import '../models/dir_model.dart';
import '../util/audio_player_handler.dart';
import '../util/listenable_sub.dart';
import '../util/swift_scroll_physics.dart';
import '../widgets/folder_view.dart';

class FolderScroller extends StatefulWidget {
  const FolderScroller({
    required this.rootDirItem,
    required this.onFileTap,
    required this.onDirLongPress
  });

  final FolderItem rootDirItem;
  final void Function(FolderItem item, List<FolderItem> siblings) onFileTap;
  final void Function(FolderItem dirItem) onDirLongPress;

  @override
  State<StatefulWidget> createState() => FolderScrollerState();
}

class FolderScrollerState extends State<FolderScroller> {
  FolderItem curDir = FolderItem.invalid;
  late ListenableSub dirModelListener;

  @override
  void initState() {
    super.initState();
    dirModelListener = ListenableSub(DirModel.instance, () {
      changeDir(DirModel.instance.curDirItem);
    });
    dirItems = [widget.rootDirItem];
    SchedulerBinding.instance?.endOfFrame.then<void>((value) => changeDir(DirModel.instance.curDirItem));
  }

  @override
  void dispose() {
    dirModelListener.dispose();
    super.dispose();
  }

  final pageController = PageController(initialPage: 0);

  late List<FolderItem> dirItems = [];

  Future animateToPage(int index) async {
    await SchedulerBinding.instance?.endOfFrame;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic
    );
  }

  Future changeDir(FolderItem newDirItem) async {
    if(curDir.uri() == newDirItem.uri())
      return;

    // moving to existing dir
    var index = dirItems.lastIndexWhere((dir) => dir.uri() == newDirItem.uri());
    if(index >= 0) {
      var page = pageController.page;
      if(page != null && (page == (index - 1)) || (page == (index + 1)))
        await animateToPage(index);
      else
        pageController.jumpToPage(index);
      return;
    }

    // moving to the next dir down the tree
    if(newDirItem.parent().uri() == dirItems[dirItems.length - 1].uri()) {
      setState(() {
        dirItems.add(newDirItem);
      });
      await animateToPage(dirItems.length - 1);
      return;
    }

    // moving to an arbitrary dir outside the current tree
    var newDirs = <FolderItem>[];
    while(true) {
      var dir = dirItems.firstWhereOrNull((dir) => dir.uri() == newDirItem.uri());
      dir ??= newDirItem;
      newDirs.insert(0, dir);
      if(widget.rootDirItem.uri() == newDirItem.uri())
        break;
      newDirItem = newDirItem.parent();
    }

    setState(() {
      dirItems = newDirs;
    });

    await animateToPage(dirItems.length - 1);
  }

  FolderView folderView(FolderItem dirItem) {
    return FolderView(
      dirItem: dirItem,
      curFilePath: audioHandler.mediaItem.valueOrNull?.id,
      onDirChange: changeDir,
      onFileTap: widget.onFileTap,
      onDirLongPress: widget.onDirLongPress
    );
  }

  @override
  Widget build(context) {
    return PageView.builder(
      controller: pageController,
      itemCount: dirItems.length,
      physics: const SwiftPageScrollPhysics(),
      itemBuilder: (context, index) {
        var dirItem = dirItems[index];
        var view = folderView(dirItem);
        return view;
      },
      onPageChanged: (index) {
        curDir = dirItems[index];
        DirModel.instance.setDir(curDir);
      }
    );
  }
}
