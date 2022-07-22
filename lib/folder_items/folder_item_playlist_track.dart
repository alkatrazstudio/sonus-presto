// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'dart:math';
import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';
import 'package:collection/collection.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart';

import '../folder_items/folder_item.dart';
import '../folder_items/folder_item_playlist.dart';
import '../playlist/playlist.dart';
import '../util/document_tree.dart';

class FolderItemPlaylistTrack extends FolderItem {
  static const trackSep = '/./';

  FolderItemPlaylist sheet;
  PlaylistTrack track;
  int index;
  late Duration minStart;

  FolderItemPlaylistTrack({
    required this.sheet,
    required this.track,
    required this.index
  }) {
    var index0 = track.index0;
    var index1 = track.index1;
    index0 ??= index1 ?? const Duration();
    index1 ??= index0;
    var microSecs0 = index0.inMicroseconds;
    var microSecs1 = index1.inMicroseconds;
    var microSecs = min(microSecs0, microSecs1);
    minStart = Duration(microseconds: microSecs);
  }

  static RegExp uriRx() {
    return RegExp(r'^(?<cueFilename>.+)' + RegExp.escape(trackSep) + r'(?<trackNumber>\d+)');
  }

  static Future<FolderItemPlaylistTrack?> fromUri(String uri) async {
    var rx = uriRx();
    var match = rx.firstMatch(uri);
    if(match == null)
      return null;

    var cueFilename = match.namedGroup('cueFilename') ?? '';
    var sheet = await FolderItem.fromUriByType<FolderItemPlaylist>(cueFilename);
    if(sheet == null)
      return null;

    var trackItems = await sheet.children();
    var trackItem = trackItems.firstWhereOrNull((item) => item.uri() == uri);
    if(trackItem is! FolderItemPlaylistTrack)
      return null;

    return trackItem;
  }

  @override
  bool isContainer() {
    return false;
  }

  @override
  String displayName() {
    var title = track.title;
    if(title.isEmpty)
      title = basenameWithoutExtension(DocumentTreeItem.extractName(track.filename));
    return '${track.numberStr}. $title';
  }

  @override
  String uri() {
    return sheet.uri() + trackSep + track.number.toString();
  }

  @override
  String fileUri() {
    return track.filename;
  }

  @override
  Future<bool> exists() async {
    if(!await sheet.exists())
      return false;
    var trackItems = await sheet.children();
    var trackPath = uri();
    return trackItems.any((item) => item.uri() == trackPath);
  }

  @override
  FolderItem parent() {
    return sheet;
  }

  @override
  IconData icon() {
    return Icons.music_note;
  }

  @override
  bool isRealFileUri() {
    return false;
  }

  @override
  AudioSource createAudioSource() {
    var child = FolderItem.audioSourceByUri(
      track.filename,
      () => ProgressiveAudioSource(Uri.parse(track.filename))
    );

    Duration? end;
    var tracks = sheet.trackItems ?? []; // can't be called before children(), which initializes the sheet
    if(index < tracks.length - 1) {
      var nextTrackItem = tracks[index + 1];
      if(nextTrackItem.track.filename == track.filename)
        end = nextTrackItem.minStart;
    }

    return ClippingAudioSource(
      child: child,
      start: minStart,
      end: end
    );
  }

  @override
  bool isChildOf(FolderItem item) {
    if(sheet == item)
      return true;
    return super.isChildOf(item);
  }

  @override
  MediaItem mediaItem() {
    var mItem = super.mediaItem();

    var album = track.album;
    if(album.isEmpty)
      album = DocumentTreeItem.extractName(DocumentTreeItem.resolvePath(track.filename, '..'));
    var artist = track.artist;
    if(artist.isEmpty)
      artist = DocumentTreeItem.extractName(DocumentTreeItem.resolvePath(track.filename, '../..'));

    mItem = mItem.copyWith(
      album: album,
      artist: artist
    );

    return mItem;
  }

  static FolderItemClassMeta classMeta() {
    return FolderItemClassMeta(
      className: (FolderItemPlaylistTrack).toString(),
      fromUriFunc: fromUri,
      fromDocumentTreeItemFunc: null,
      isSupportedUriFunc: (uri) => uriRx().hasMatch(uri)
    );
  }
}
