// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'dart:io';
import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:super_tooltip/super_tooltip.dart';

import '../folder_items/folder_item.dart';
import '../folder_items/folder_item_directory.dart';
import '../models/dir_model.dart';
import '../util/audio_player_handler.dart';
import '../util/document_tree.dart';
import '../util/locale_helper.dart';
import '../util/prefs.dart';
import '../util/showcase_util.dart';
import '../widgets/context_menu.dart';
import '../widgets/control_pane.dart';
import '../widgets/folder_scroller.dart';
import '../widgets/future_with_spinner.dart';
import '../widgets/options_popup.dart';
import '../widgets/progress_bar.dart';

class NoRootDirAccess implements Exception {
  late final String message;

  NoRootDirAccess(Object? parent) {
    message = parent?.toString() ?? 'N/A';
  }
}

class HomePage extends StatefulWidget {
  const HomePage();

  static const prefRootDir = 'rootDir';
  static const prefCurDir = 'curDir';
  static const prefCurFile = 'curFile';
  static const prefRootDirAlertShown = 'rootDirAlertShown';
  static const prefQueueDir = 'queueDir';
  static const prefQueueDirRecursive = 'queueDirRecursive';

  static final googlePlayShowcase = ShowcaseController('googlePlay', 1);
  static final titleShowcase = ShowcaseController('title', 1);
  static final folderScrollerShowcase = ShowcaseController('folderScroller', 2);

  @override
  HomePageState createState() => HomePageState();

  static Future resetFilePrefs() async {
    await Prefs.remove(prefRootDir);
    await Prefs.remove(prefCurDir);
    await Prefs.remove(prefCurFile);
    await Prefs.remove(prefQueueDir);
    await Prefs.remove(prefQueueDirRecursive);
  }

  static Future<void> savePlayingDir(FolderItem item, bool isRecursive) async {
    await Prefs.setString(HomePage.prefQueueDir, item.uri());
    await Prefs.setBool(HomePage.prefQueueDirRecursive, isRecursive);
  }
}

class HomePageState extends State<HomePage> {
  late FolderItem rootDirItem = FolderItem.invalid;
  Future<bool>? initFuture;
  var isError = false;

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
      try {
        dir = await DocumentTree.requestAccess();
      } catch(e) {
        throw NoRootDirAccess(e);
      }
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
      var folderItems = await loadQueue(curFileItem);
      audioHandler.updateQueueFromFolderItems(folderItems);
      await startPromise;

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

  Future<List<FolderItem>> loadQueue(FolderItem curFileItem) async {
    var queueDirUri = await Prefs.getString(HomePage.prefQueueDir);
    var queueDir = await FolderItem.fromUri(queueDirUri);
    if(
      queueDir != null &&
      queueDir.isChildOf(rootDirItem) &&
      queueDir.isContainer() &&
      await queueDir.exists()
    ) {
      var queueDirRecursive = await Prefs.getBool(HomePage.prefQueueDirRecursive);
      if(queueDirRecursive) {
        if(curFileItem.isChildOf(queueDir)) {
          var children = await queueDir.recursiveChildren().toList();
          return children;
        }
      } else {
        if(curFileItem.parent().uri() == queueDir.uri()) {
          var children = await queueDir.children();
          return children;
        }
      }
    }

    queueDir = curFileItem.parent();
    var children = await curFileItem.parent().children();
    await HomePage.savePlayingDir(queueDir, false);
    return children;
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

  FolderScroller folderScroller(BuildContext context) {
    return FolderScroller(
      rootDirItem: rootDirItem,
      onFileTap: (item, siblings) async {
        await AudioPlayerHandler.startServiceIfNeeded();
        if(item.uri() != audioHandler.mediaItem.valueOrNull?.id) {
          var mediaItem = audioHandler.queue.valueOrNull?.firstWhereOrNull((mItem) => mItem.id == item.uri());
          if(mediaItem == null) {
            audioHandler.updateQueueFromFolderItems(siblings);
            await HomePage.savePlayingDir(item.parent(), false);
          }
          await audioHandler.playFromMediaId(item.uri());
        } else {
          if(audioHandler.playbackState.valueOrNull?.playing ?? false)
            await audioHandler.pause();
          else
            await audioHandler.play();
        }
      },
      onFileLongPress: (item) async {
        await showContextMenu(context, item);
      },
      onDirLongPress: (item) async {
        await showContextMenu(context, item);
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
    await HomePage.googlePlayShowcase.show();
    await HomePage.folderScrollerShowcase.show();
    await HomePage.titleShowcase.show();
    await ControlPane.controlSliderShowcase.show();
    await ControlPane.optionsPopupBtnShowcase.show();
  }

  @override
  Widget build(context) {
    initFuture ??= init(context);
    initFuture!.catchError((Object _) => isError = true);

    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if(isError)
          Navigator.pop(context);
        var dirModel = context.read<DirModel>();
        var newDirItem = dirModel.curDirItem.parent();
        if(!newDirItem.isChildOf(rootDirItem))
          return;
        dirModel.setDir(newDirItem);
      },
      child: Scaffold(
        appBar: AppBar(
          title: FutureBuilder<bool>(
            future: initFuture,
            builder: (context, snapshot) {
              return Showcase(
                text: L(context).showcaseTitle,
                tooltipDirection: TooltipDirection.down,
                controller: HomePage.titleShowcase,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(snapshot.hasData ? title(context.watch<DirModel>().curDirItem) : appTitle)
                )
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
                  child: Showcase(
                    controller: HomePage.googlePlayShowcase,
                    text: L(context).showcaseGooglePlay,
                    tooltipDirection: TooltipDirection.down,
                    child: Showcase(
                      controller: HomePage.folderScrollerShowcase,
                      text: L(context).showcaseFolderScroller,
                      tooltipDirection: TooltipDirection.down,
                      child: folderScroller(context)
                    )
                  )
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
          },
          errorWidgetFunc: (err) {
            return Padding(
              padding: const EdgeInsets.all(10),
              child: err is NoRootDirAccess
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(L(context).rootDirNoAccessErr),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(L(context).rootDirNoAccessDetails(err.message)),
                    Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              OptionsPopup.resetRoot();
                            },
                            child: Text(
                              L(context).rootDirNoAccessBtn,
                              textAlign: TextAlign.center
                            )
                          )
                        ]
                      )
                    )
                  ]
                )
                : Text(err?.toString() ?? 'N/A')
            );
          },
        )
      )
    );
  }
}
