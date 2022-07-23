// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2022, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../folder_items/folder_item.dart';
import '../models/dir_model.dart';
import '../util/audio_player_handler.dart';
import '../util/document_tree.dart';
import '../util/locale_helper.dart';
import '../widgets/folder_scroller.dart';

class ContextMenuOption {
  ContextMenuOption(this.title, this.icon, this.onTap);

  final String title;
  final IconData icon;
  final Future<void> Function(BuildContext, FolderItem) onTap;
}

Future<void> showContextMenu(BuildContext context, FolderItem item) async {
  if(!item.isRealFileUri())
    return;

  var options = <ContextMenuOption>[];

  if(item.isContainer()) {
    return;
  } else {
    options.add(ContextMenuOption(L(context).contextBtnDeleteFile, Icons.delete_forever, deleteFileWithConfirmation));
  }

  var result = await showDialog<ContextMenuOption>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text(item.displayName()),
        children: options.map((opt) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, opt),
          child: ListTile(
            title: Text(opt.title),
            leading: Icon(opt.icon),
            contentPadding: const EdgeInsets.symmetric(horizontal: 0)
          )
        )).toList()
      );
    }
  );

  await result?.onTap(context, item);
}

Future<bool> showConfirmDeleteDialog(
  BuildContext context,
  String title,
  String text
) async {
  return (await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            child: Text(L(context).btnCancel),
            onPressed: () => Navigator.of(context).pop()
          ),
          TextButton(
            child: Text(L(context).btnDelete),
            onPressed: () => Navigator.of(context).pop(true)
          )
        ]
      );
    }
  )) ?? false;
}

Future<void> deleteFileWithConfirmation(BuildContext context, FolderItem item) async {
  if(!await showConfirmDeleteDialog(context, item.displayName(), L(context).deleteFileConfirmText))
    return;

  await audioHandler.removeQueueItem(item.mediaItem());

  var dirModel = Provider.of<DirModel>(context, listen: false);
  var inCurDir = item.parent().uri() == dirModel.curDirItem.uri();

  await DocumentTree.deleteDoc(item.fileUri());

  if(inCurDir)
    FolderScroller.reload();
}
