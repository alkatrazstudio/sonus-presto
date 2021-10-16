// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'dart:io';
import 'package:flutter/material.dart';

import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:super_tooltip/super_tooltip.dart';

import '../folder_items/folder_item.dart';
import '../folder_items/folder_item_directory.dart';
import '../models/dir_model.dart';
import '../util/audio_player_handler.dart';
import '../util/collections_ex.dart';
import '../util/document_tree.dart';
import '../util/locale_helper.dart';
import '../util/prefs.dart';
import '../util/showcase_util.dart';
import '../widgets/blocking_spinner.dart';
import '../widgets/control_pane.dart';
import '../widgets/folder_scroller.dart';
import '../widgets/future_with_spinner.dart';
import '../widgets/progress_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage();

  static const prefRootDir = 'rootDir';
  static const prefCurDir = 'curDir';
  static const prefCurFile = 'curFile';
  static const prefRootDirAlertShown = 'rootDirAlertShown';

  static const titleShowcaseKey = ShowcaseGlobalKey('title', 1);
  static const folderScrollerShowcaseKey = ShowcaseGlobalKey('folderScroller', 1);

  @override
  HomePageState createState() => HomePageState();

  static Future resetFilePrefs() async {
    await Prefs.remove(prefRootDir);
    await Prefs.remove(prefCurDir);
    await Prefs.remove(prefCurFile);
  }
}

class HomePageState extends State<HomePage> {
  late FolderItem rootDirItem = FolderItem.invalid;
  Future<bool>? initFuture;

  static Future rootDirAlert(BuildContext context) async {
    if(await Prefs.getBool(HomePage.prefRootDirAlertShown))
      return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Text(L(context).alertSelectRootText(appTitle)),
          actions: [
            TextButton(
              child: Text(L(context).btnOk),
              onPressed: () {
                Navigator.of(context).pop();
              }
            )
          ]
        );
      }
    );

    Prefs.setBool(HomePage.prefRootDirAlertShown, true);
  }

  static Future<FolderItem> getRootDirItem(BuildContext context) async {
    var rootPath = await Prefs.getString(HomePage.prefRootDir);
    var dir = await DocumentTreeItem.fromUri(rootPath);

    try {
      if(dir is! DocumentTreeItemDirectory)
        throw Error();
      if(!await DocumentTree.hasAccess(dir.uri))
        throw Error();
    } catch(e) {
      await rootDirAlert(context);
      dir = await DocumentTree.requestAccess();
      rootPath = dir.uri;
      await Prefs.remove(HomePage.prefCurDir);
      await Prefs.remove(HomePage.prefCurFile);
    }
    await Prefs.setString(HomePage.prefRootDir, rootPath);
    return FolderItemDirectory(dir as DocumentTreeItemDirectory);
  }

  Future<bool> init(BuildContext context) async {
    rootDirItem = await getRootDirItem(context);

    var curDirPath = await Prefs.getString(HomePage.prefCurDir, rootDirItem.uri());
    var curDirItem = await FolderItem.fromUri(curDirPath);

    while(true) {
      if(curDirItem == null) {
        curDirItem = rootDirItem;
        break;
      }

      if(!curDirItem.isChildOf(rootDirItem)) {
        curDirItem = rootDirItem;
        break;
      }

      try {
        if(await curDirItem.exists())
          break;
      } catch(e) {
        curDirItem = rootDirItem;
        break;
      }

      curDirItem = curDirItem.parent();
    }

    var curFilePath = await Prefs.getString(HomePage.prefCurFile, '');
    var curFileItem = await FolderItem.fromUri(curFilePath);
    if(curFileItem != null && curFileItem.isChildOf(rootDirItem) && !curFileItem.isContainer() && await curFileItem.exists()) {
      var startPromise = AudioPlayerHandler.startServiceIfNeeded();
      var children = await curFileItem.parent().children();
      await startPromise;
      audioHandler.updateQueueFromFolderItems(children);
      var mediaItem = curFileItem.mediaItem();
      try {
        await audioHandler.prepareMediaItem(mediaItem);
      }catch(e) {
        debugPrint(e.toString());
      }
    }

    audioHandler.mediaItem.listen((mediaItem) async {
      if(mediaItem != null)
        await Prefs.setString(HomePage.prefCurFile, mediaItem.id);
    });

    var curItemId = audioHandler.mediaItem.valueOrNull?.id ?? '';
    if(curItemId.isNotEmpty && curFileItem != null && curFileItem.parent().uri() == curDirItem.uri())
      DirModel.instance.setDir(curDirItem, curFileItem);
    else
      DirModel.instance.setDir(curDirItem);

    DirModel.instance.addListener(() async {
      var id = DirModel.instance.curDirItem.uri();
      if(id == '')
        return;
      await Prefs.setString(HomePage.prefCurDir, id);
    });

    return true;
  }

  String title(FolderItem dirItem) {
    var folders = <String>[];
    var curDirPart = dirItem;
    if(dirItem.uri() == '' || rootDirItem.uri() == '')
      return appTitle;
    while(true) {
      folders.insert(0, curDirPart.displayName());
      var parentPart = curDirPart.parent();
      if(parentPart.uri() == curDirPart.uri())
        break;
      if(!curDirPart.isChildOf(rootDirItem))
        break;
      curDirPart = parentPart;
    }
    if(folders.length == 1)
      return folders.first;
    var fullTitle = folders.skip(1).join('/');
    return fullTitle;
  }

  FolderScroller folderScroller() {
    return FolderScroller(
      rootDirItem: rootDirItem,
      onFileTap: (item, siblings) async {
        await AudioPlayerHandler.startServiceIfNeeded();
        if(item.uri() != audioHandler.mediaItem.valueOrNull?.id) {
          var mediaItem = audioHandler.queue.valueOrNull?.firstWhereOrNull((mItem) => mItem.id == item.uri());
          if(mediaItem == null)
            audioHandler.updateQueueFromFolderItems(siblings);
          await audioHandler.playFromMediaId(item.uri());
        } else {
          if(audioHandler.playbackState.valueOrNull?.playing ?? false)
            await audioHandler.pause();
          else
            await audioHandler.play();
        }
      },
      onDirLongPress: (item) async {
        var items = await BlockingSpinner.showWhile<List<FolderItem>>(() async {
          List<FolderItem> items = [];
          await for (var item in item.recursiveChildren()) {
            if(BlockingSpinner.isInterrupted)
              return [];
            items.add(item);
          }
          return items;
        });
        if(items.isEmpty)
          return;

        await AudioPlayerHandler.startServiceIfNeeded();
        audioHandler.updateQueueFromFolderItems(items);
        await audioHandler.playFromMediaId(items.first.uri());
      }
    );
  }

  Future<void> locateCurrentFile() async {
    var mediaItem = audioHandler.mediaItem.valueOrNull;
    if(mediaItem == null)
      return;
    var index = audioHandler.queue.valueOrNull?.indexOf(mediaItem);
    if(index == null)
      return;
    var mediaFolderItem = await FolderItem.fromUri(mediaItem.id);
    if(mediaFolderItem == null)
      return;
    var newDirItem = mediaFolderItem.parent();
    DirModel.instance.setDir(newDirItem, mediaFolderItem);
  }

  String get curMediaItemDir {
    var mediaItem = audioHandler.mediaItem.valueOrNull;
    if(mediaItem == null)
      return '';
    var parentPath = File(mediaItem.id).parent.path;
    return basename(parentPath);
  }

  void startShowcase(BuildContext context) async {
    await ShowcaseUtil.showForContext(
      key: HomePage.folderScrollerShowcaseKey,
      text: L(context).showcaseFolderScroller,
      tooltipDirection: TooltipDirection.down
    );

    await ShowcaseUtil.showForContext(
        key: HomePage.titleShowcaseKey,
        text: L(context).showcaseTitle,
        tooltipDirection: TooltipDirection.down
    );

    await ShowcaseUtil.showForContext(
      key: ControlPane.controlSliderShowcaseKey,
      text: L(context).showcaseControlSlider,
      tooltipDirection: TooltipDirection.up
    );

    await ShowcaseUtil.showForContext(
      key: ControlPane.optionsPopupBtnShowcaseKey,
      text: L(context).showcaseOptionsPopup,
      tooltipDirection: TooltipDirection.up
    );
  }

  @override
  Widget build(context) {
    initFuture ??= init(context);

    return WillPopScope(
      onWillPop: () async {
        var dirModel = context.read<DirModel>();
        var newDirItem = dirModel.curDirItem.parent();
        if(!newDirItem.isChildOf(rootDirItem))
          return false;
        dirModel.setDir(newDirItem);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: FutureBuilder<bool>(
            future: initFuture,
            builder: (context, snapshot) {
              if(!snapshot.hasData)
                return const SizedBox.shrink();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                key: HomePage.titleShowcaseKey,
                child: Text(title(context.watch<DirModel>().curDirItem))
              );
            }
          )
        ),
        body: FutureWithSpinner<bool>(
          future: initFuture!,
          childFunc: (_) {
            startShowcase(context);

            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  key: HomePage.folderScrollerShowcaseKey,
                  child: folderScroller()
                ),
                ProgressBar(),
                ControlPane(
                  onPrevTap: audioHandler.skipToPrevious,
                  onNextTap: audioHandler.skipToNext,
                  onPlayTap: audioHandler.play,
                  onPauseTap: audioHandler.pause,
                  onStopTap: () => audioHandler.customAction(AudioPlayerHandler.actionStop),
                  onLocateFile: locateCurrentFile
                )
              ]
            );
          }
        )
      )
    );
  }
}
