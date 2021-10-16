// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:audio_service/audio_service.dart';

import '../folder_items/folder_item.dart';
import '../util/audio_player_handler.dart';

class PlaybackStateModel extends ChangeNotifier {
  late final StreamSubscription<PlaybackState> _stateSub;
  late final StreamSubscription<MediaItem?> _mediaItemSub;

  var processingState = AudioProcessingState.idle;
  var isPlaying = false;
  var mediaId = '';
  FolderItem? folderItem;
  MediaItem? mediaItem;
  var duration = const Duration();
  var canPlayNext = false;
  var canPlayPrev = false;

  PlaybackStateModel() {
    _stateSub = audioHandler.playbackState.listen((playbackState) {
      setState(playbackState);
      notifyListeners();
    });
    _mediaItemSub = audioHandler.mediaItem.listen((newMediaItem) {
      mediaItem = newMediaItem;
      duration = newMediaItem?.duration ?? const Duration();
      mediaId = newMediaItem?.id ?? '';
      notifyListeners();
    });
    setState(audioHandler.playbackState.valueOrNull ?? PlaybackState());
  }

  void setState(PlaybackState playbackState) {
    var curMediaItem = audioHandler.mediaItem.valueOrNull;
    mediaItem = curMediaItem;

    processingState = playbackState.processingState;
    isPlaying = playbackState.playing;
    mediaId = curMediaItem?.id ?? '';
    duration = curMediaItem?.duration ?? const Duration();
    canPlayNext = playbackState.controls.contains(MediaControl.skipToNext);
    canPlayPrev = playbackState.controls.contains(MediaControl.skipToPrevious);
    if(curMediaItem == null)
      folderItem = null;
    else
      folderItem = audioHandler.folderItemFromQueue(curMediaItem);
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _mediaItemSub.cancel();
    super.dispose();
  }
}
