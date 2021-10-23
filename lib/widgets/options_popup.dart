// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';

import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:super_tooltip/super_tooltip.dart';

import '../folder_items/folder_item.dart';
import '../models/playback_state_model.dart';
import '../util/audio_player_handler.dart';
import '../util/document_tree.dart';
import '../util/locale_helper.dart';
import '../util/showcase_util.dart';
import '../widgets/homepage.dart';
import '../widgets/help_page.dart';
import '../widgets/locale_selector.dart';
import '../widgets/restartable_app.dart';
import '../widgets/scheme_selector.dart';

class OptionsPopup extends StatelessWidget {
  static const fileInfoShowcaseKey = ShowcaseGlobalKey('fileInfo', 1);

  const OptionsPopup({
    required this.onLocateFile
  });

  final void Function() onLocateFile;

  String durationToStr(Duration duration) {
    var secs = duration.inSeconds;
    var mins = (secs / 60).truncate();
    secs = secs - mins * 60;
    var secsStr = secs.toString();
    if(secs < 10)
      secsStr = '0' + secsStr;
    var s = mins.toString() + ':' + secsStr;
    return s;
  }

  String filenameToTitle(String filename) {
    return basenameWithoutExtension(filename);
  }

  String filenameToDirTitle(String filename) {
    return basename(dirname(filename));
  }

  static void resetRoot() async {
    await audioHandler.stop();
    audioHandler.updateQueueFromFolderItems([]);
    audioHandler.mediaItem.add(null);
    await DocumentTree.releaseAccess();
    await HomePage.resetFilePrefs();
    RestartableApp.restart();
  }

  void confirmResetRoot(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(L(context).alertChangeRootTitle),
          actions: <Widget>[
            TextButton(
              child: Text(L(context).btnCancel),
              onPressed: () {
                Navigator.of(context).pop();
              }
            ),
            TextButton(
              child: Text(L(context).alertChangeRootBtnChange),
              onPressed: resetRoot
            )
          ]
        );
      }
    );
  }

  Widget fileInfo(BuildContext context, FolderItem folderItem) {
    return InkWell(
      key: fileInfoShowcaseKey,
      onTap: () {
        onLocateFile.call();
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 10
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              folderItem.displayName(),
              style: Theme.of(context).textTheme.headline6,
              textAlign: TextAlign.center
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: Theme.of(context).textTheme.subtitle2?.fontSize ?? 15
                ),
                Text(
                  ' ' + durationToStr(context.watch<PlaybackStateModel>().duration),
                  style: Theme.of(context).textTheme.subtitle2
                )
              ]
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 10
              ),
              child: Text(
                folderItem.parent().displayName(),
                style: Theme.of(context).textTheme.caption,
                textAlign: TextAlign.center
              )
            )
          ]
        )
      )
    );
  }

  @override
  Widget build(context) {
    var folderItem = context.watch<PlaybackStateModel>().folderItem;

    Future<void>.delayed(const Duration(milliseconds: 500)).then((value) {
      ShowcaseUtil.showForContext(
        key: fileInfoShowcaseKey,
        text: L(context).showcaseFileInfo,
        tooltipDirection: TooltipDirection.down
      );
    });

    return Column(
      children: [
        if(folderItem != null) fileInfo(context, folderItem),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              child: ElevatedButton(
                onPressed: () {
                  confirmResetRoot(context);
                },
                child: Text(
                  L(context).optionsPopupBtnChangeRoot,
                  textAlign: TextAlign.center
                )
              )
            ),
            Flexible(
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  HelpPage.open(context);
                },
                child: Text(
                  L(context).optionPopupBtnHelp,
                  textAlign: TextAlign.center
                )
              )
            )
          ]
        ),
        const Spacer(),
        const LocaleSelector(),
        const SchemeSelector()
      ]
    );
  }
}
