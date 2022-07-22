// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';

import '../folder_items/folder_item.dart';
import '../models/playback_state_model.dart';

enum FolderViewItemMode {
  unknown,
  folder,
  file
}

class FolderViewItem extends StatelessWidget {
  const FolderViewItem({
    required this.folderItem,
    this.onTap,
    this.onLongPress
  });

  final FolderItem folderItem;
  final GestureTapCallback? onTap;
  final GestureTapCallback? onLongPress;

  IconData icon(PlaybackStateModel playback) {
    if(folderItem.isContainer() || !isInPathOfCurrentItem(playback))
      return folderItem.icon();

    if(playback.isPlaying)
      return Icons.play_arrow;
    if(playback.processingState == AudioProcessingState.ready)
      return Icons.pause;
    return Icons.stop;
  }

  bool isInPathOfCurrentItem(PlaybackStateModel playback) {
    var curFolderItem = playback.folderItem;
    if(curFolderItem == null)
      return false;

    if(folderItem.isContainer())
      return curFolderItem.isChildOf(folderItem);
    return curFolderItem.uri() == folderItem.uri();
  }

  @override
  Widget build(context) {
    var playback = context.watch<PlaybackStateModel>();
    return ListTile(
      key: Key('$FolderViewItem:${folderItem.uri()}'),
      leading: Icon(icon(playback)),
      visualDensity: VisualDensity(
        horizontal: VisualDensity.minimumDensity,
        vertical: VisualDensity.adaptivePlatformDensity.vertical
      ),
      title: Text(
        folderItem.displayName(),
        style: TextStyle(
          fontWeight: isInPathOfCurrentItem(playback) ? FontWeight.bold : FontWeight.normal
        )
      ),
      onTap: onTap,
      onLongPress: onLongPress,
      selected: isInPathOfCurrentItem(playback),
      tileColor: Colors.transparent,
      selectedTileColor: Theme.of(context).highlightColor
    );
  }
}
