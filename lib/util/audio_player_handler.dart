// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:collection/collection.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart';

import '../folder_items/folder_item.dart';

late AudioPlayerHandler audioHandler;

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler {
  late AudioPlayer player;
  List<FolderItem> folderItems = [];

  static const actionStop = 'stop';

  AudioPlayerHandler() {
    player = AudioPlayer(handleInterruptions: true);
    player.setSpeed(1);

    player.playerStateStream.listen((playerState) async {
      await updateState(playerState: playerState);
    });

    player.sequenceStateStream.listen((sequenceState) async {
      if(sequenceState == null) {
        await updateState();
        return;
      }

      var i = sequenceState.currentIndex;
      var mItems = queue.valueOrNull!;
      if(i > (mItems.length - 1)) {
        await updateState();
        return;
      }
      var mItem = mItems[i];
      mItem = await mediaItemWithDuration(mItem);
      mediaItem.add(mItem);
      await updateState();
    });

    player.durationStream.listen((duration) async {
      if(duration == null)
        return;
      var mItem = mediaItem.valueOrNull;
      if(mItem == null)
        return;
      var curDuration = mItem.duration;
      if(curDuration != null && curDuration == duration)
        return;
      mItem = mItem.copyWith(duration: duration);
      mediaItem.add(mItem);
      await updateState();
    });
  }

  Future<MediaItem> mediaItemWithDuration(MediaItem mItem) async {
    if(mItem.duration != null)
      return mItem;
    var folderItem = folderItemFromQueue(mItem);
    if(folderItem == null)
      return mItem;
    var audioSource = folderItem.audioSource();
    var duration = durationFromAudioSource(audioSource);
    if(duration != null)
      return mItem.copyWith(duration: duration);
    return mItem;
  }

  Duration? durationFromAudioSource(AudioSource audioSource) {
    if(audioSource is ClippingAudioSource) {
      var start = audioSource.start ?? const Duration();
      var end = audioSource.end ?? start;
      var duration = end - start;
      if(duration.inMicroseconds > 0) {
        return duration;
      }
    }
    if(audioSource is ProgressiveAudioSource) {
      var duration = audioSource.duration;
      if(duration != null && duration.inMicroseconds > 0) {
        return duration;
      }
    }
    return null;
  }

  Future<void> updateState({PlayerState? playerState}) async {
    playerState ??= player.playerState;

    var isStopped =
      (playerState.processingState == ProcessingState.completed)
      || (playerState.processingState == ProcessingState.idle)
      || (playerState.processingState == ProcessingState.loading)
      || (playerState.processingState == ProcessingState.ready && player.position.inMicroseconds == 0);
    var isPlaying = playerState.playing && !isStopped;
    var hasPrev = canPlayPrev(mediaItem.valueOrNull, queue.valueOrNull);
    var hasNext = canPlayNext(mediaItem.valueOrNull, queue.valueOrNull);

    var controls = [
      if(hasPrev) MediaControl.skipToPrevious,
      isPlaying ? MediaControl.pause : MediaControl.play,
      if(hasNext) MediaControl.skipToNext
    ];

    var state = PlaybackState(
      playing: isPlaying,
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: isStopped ? AudioProcessingState.idle : AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[playerState.processingState] ?? AudioProcessingState.idle,
      controls: controls,
      updatePosition: isStopped ? const Duration() : player.position,
      bufferedPosition: player.bufferedPosition,
      updateTime: DateTime.now(),
      speed: player.speed,
      queueIndex: currentQueueIndex() ?? -1
    );

    playbackState.add(state);
  }

  static bool canPlayNext(MediaItem? mediaItem, List<MediaItem>? queue) {
    if(mediaItem == null)
      return false;
    if(queue == null)
      return false;
    var curIndex = queue.indexOf(mediaItem);
    if(curIndex == -1)
      return false;
    if(curIndex >= queue.length - 1)
      return false;
    if(!(queue[curIndex + 1].playable ?? false))
      return false;
    return true;
  }

  static bool canPlayPrev(MediaItem? mediaItem, List<MediaItem>? queue) {
    if(mediaItem == null)
      return false;
    if(queue == null)
      return false;
    var curIndex = queue.indexOf(mediaItem);
    if(curIndex <= 0)
      return false;
    if(queue[curIndex - 1].playable != true)
      return false;
    return true;
  }

  @override
  Future<void> stop() async {
    await player.stop();
    await seek(const Duration());
    await super.stop();
  }

  @override
  Future<void> pause() async {
    await player.pause();
    await super.pause();
  }

  @override
  Future<void> play() async {
    if(player.processingState == ProcessingState.completed || player.processingState == ProcessingState.idle) {
      var mItem = mediaItem.valueOrNull;
      if(mItem != null)
        await prepareMediaItem(mItem);
    }

    player.play();
  }

  static MediaItem mediaItemFromFilePath(String filename) {
    var fileBaseName = basenameWithoutExtension(filename);
    var dirName = basename(File(filename).parent.path);

    return MediaItem(
      id: filename,
      album: dirName,
      title: fileBaseName
    );
  }

  int? currentQueueIndex() {
    var q = queue.valueOrNull;
    if(q == null)
      return null;
    var m = mediaItem.valueOrNull;
    if(m == null)
      return null;
    var i = q.indexOf(m);
    if(i == -1)
      return null;
    return i;
  }

  static MediaItem mediaItemFromQueueOrFilePath(String filename, List<MediaItem>? queue) {
    var mediaItem = queue?.firstWhereOrNull((item) => item.id == filename);
    return mediaItem ?? mediaItemFromFilePath(filename);
  }

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    var mediaItem = mediaItemFromQueueOrFilePath(mediaId, queue.valueOrNull);
    await playMediaItem(mediaItem);
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    await prepareMediaItem(mediaItem);
    await play();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    var q = queue.valueOrNull;
    if(q == null)
      return;
    await playFromMediaId(q[index].id);
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    List<FolderItem> newFolderItems = [];
    for(var item in newQueue) {
      var folderItem = await FolderItem.fromUri(item.id);
      if(folderItem != null && !folderItem.isContainer())
        newFolderItems.add(folderItem);
    }
    updateQueueFromFolderItems(newFolderItems);
  }

  void updateQueueFromFolderItems(List<FolderItem> items) {
    items = items.where((item) => !item.isContainer()).toList();
    var queueItems = items.map((item) => item.mediaItem()).toList();
    folderItems = items;
    queue.add(queueItems);
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    await removeQueueItems([mediaItem]);
  }

  Future<void> removeQueueItems(List<MediaItem> mediaItems) async {
    var curQueue = queue.valueOrNull;
    if(curQueue == null || curQueue.isEmpty)
      return;
    var newQueue = <MediaItem>[];
    newQueue.addAll(curQueue);

    var nextMediaItem = playbackState.value.playing ? mediaItem.valueOrNull : null;
    var isStopped = false;
    var audioSource = player.audioSource;
    var hasChanged = false;

    for(var item in mediaItems) {
      var itemIndex = newQueue.indexOf(item);
      if(itemIndex < 0)
        continue;

      if(nextMediaItem == item) {
        if(itemIndex < (newQueue.length - 1))
          nextMediaItem = newQueue[itemIndex + 1];
        else if(itemIndex > 0) {
          nextMediaItem = newQueue[itemIndex - 1];
        } else {
          nextMediaItem = null;
        }
        if(!isStopped) {
          await stop();
          isStopped = true;
        }
        mediaItem.add(null);
      }

      newQueue.remove(item);
      hasChanged = true;

      if(audioSource is ConcatenatingAudioSource) {
        var folderItemIndex = folderItems.indexWhere((folderItem) => folderItem.uri() == item.id);
        if(folderItemIndex >= 0) {
          audioSource.removeAt(folderItemIndex);
          folderItems.removeAt(folderItemIndex);
        }
      }
    }

    if(!hasChanged)
      return;

    await updateQueue(newQueue);
    if(nextMediaItem != null && nextMediaItem != mediaItem.valueOrNull)
      await playMediaItem(nextMediaItem);
    await updateState();
  }

  FolderItem? folderItemFromQueue(MediaItem mItem) {
    return folderItems.firstWhereOrNull((item) => item.uri() == mItem.id);
  }

  @override
  Future<void> prepare() async {
    var mItem = mediaItem.valueOrNull;
    if(mItem == null)
      return;

    await prepareMediaItem(mItem);
  }

  @override
  Future<void> prepareFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    var q = queue.valueOrNull;
    if(q == null)
      return;
    var mItem = mediaItemFromQueueOrFilePath(mediaId, q);
    await prepareMediaItem(mItem);
  }

  Future<void> prepareMediaItem(MediaItem mItem) async {
    var q = queue.valueOrNull;
    if(q == null)
      return;
    var i = q.indexOf(mItem);
    if(i < 0)
      return;
    var playlistItems = folderItems.map((item) => item.audioSource()).toList();
    var playlist = ConcatenatingAudioSource(children: playlistItems);
    var playlistItem = playlistItems[i];
    var duration = durationFromAudioSource(playlistItem);

    var curAudioSource = player.audioSource;
    if(
      curAudioSource is ConcatenatingAudioSource &&
      const ListEquality<AudioSource>().equals(playlist.children, curAudioSource.children) &&
      player.processingState != ProcessingState.completed &&
      player.processingState != ProcessingState.idle
    ) {
      player.seek(const Duration(), index: i);
    } else {
      await player.stop();
      var resultDuration = await player.setAudioSource(playlist, initialIndex: i);
      if(resultDuration != null)
        duration = resultDuration;
    }

    if(duration != null) {
      if(playlistItem is ProgressiveAudioSource)
        playlistItem.duration = duration;
      mItem = mItem.copyWith(duration: duration);
    }
    mediaItem.add(mItem);
  }

  @override
  Future<void> skipToNext() async {
    if(canPlayNext(mediaItem.valueOrNull, queue.valueOrNull))
      super.skipToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if(canPlayPrev(mediaItem.valueOrNull, queue.valueOrNull))
      super.skipToPrevious();
  }

  @override
  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch(name) {
      case actionStop:
        await stop();
        break;
    }
  }

  static Future startServiceIfNeeded() async {
    final session = await AudioSession.instance;
    if(session.isConfigured)
      return;

    await session.configure(const AudioSessionConfiguration.music());
    if(!await session.setActive(true))
      throw UnsupportedError('Audio playback is not allowed.');
  }
}
