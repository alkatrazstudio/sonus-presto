// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';

import 'package:path/path.dart';

import '../folder_items/folder_item.dart';
import '../folder_items/folder_item_directory.dart';
import '../folder_items/folder_item_playlist_track.dart';
import '../playlist/playlist.dart';
import '../playlist/playlist_cue.dart';
import '../playlist/playlist_m3u.dart';
import '../util/document_tree.dart';

enum PlaylistType {
  unknown,
  cue,
  m3u
}

class PlaylistInfo {
  final Future<Playlist> Function(DocumentTreeItemFile playlistFileItem) parseFunc;
  final IconData iconData;
  final List<String> exts;
  final bool canFetchRecursiveChildren;

  const PlaylistInfo(this.parseFunc, this.iconData, this.exts, this.canFetchRecursiveChildren);

  static const info = {
    PlaylistType.cue: PlaylistInfo(parseCue, Icons.album, ['.cue'], true),
    PlaylistType.m3u: PlaylistInfo(parseM3U, Icons.list_alt, ['.m3u', '.m3u8'], true)
  };
}

class FolderItemPlaylist extends FolderItem {
  DocumentTreeItemFile file;
  Playlist? sheet;
  PlaylistType type;
  List<FolderItemPlaylistTrack>? trackItems;

  FolderItemPlaylist(this.file, this.type);

  static PlaylistType uriType(String uri) {
    var ext = extension(uri).toLowerCase();
    for(var info in PlaylistInfo.info.entries) {
      if(info.value.exts.contains(ext))
        return info.key;
    }
    return PlaylistType.unknown;
  }

  static Future<FolderItemPlaylist?> fromUri(String uri) async {
    var type = uriType(uri);
    if(type == PlaylistType.unknown)
      return null;
    var docItem = await DocumentTreeItem.fromUri(uri);
    if(docItem == null)
      return null;
    if(docItem is DocumentTreeItemFile)
      return FolderItemPlaylist(docItem, type);
    return null;
  }

  static FolderItemPlaylist? fromDocumentTreeItem(DocumentTreeItem docItem) {
    if(docItem is! DocumentTreeItemFile)
      return null;
    var type = uriType(docItem.uri);
    if(type == PlaylistType.unknown)
      return null;
    return FolderItemPlaylist(docItem, type);
  }

  @override
  bool isContainer() {
    return true;
  }

  @override
  int sortOrder() {
    return -5;
  }

  @override
  String displayName() {
    return basenameWithoutExtension(file.name);
  }

  @override
  String uri() {
    return file.uri;
  }

  @override
  Future<bool> exists() async {
    var docItem = await DocumentTreeItem.fromUri(file.uri);
    return docItem is DocumentTreeItemFile;
  }

  @override
  FolderItem parent() {
    return FolderItemDirectory(file.parent());
  }

  @override
  Future<List<FolderItemPlaylistTrack>> fetchChildren() async {
    if(trackItems != null)
      return trackItems!;

    trackItems = [];
    await loadCue();
    var tracks = sheet!.tracks;
    List<int> numbers = [];
    var index = 0;
    for(var track in tracks) {
      if(numbers.contains(track.number))
        continue;
      numbers.add(track.number);
      var trackItem = FolderItemPlaylistTrack(
        sheet: this,
        track: track,
        index: index
      );
      trackItems!.add(trackItem);
      index++;
    }

    return trackItems!;
  }

  @override
  IconData icon() {
    return info().iconData;
  }

  @override
  bool canFetchRecursiveChildren() {
    return info().canFetchRecursiveChildren;
  }

  @override
  bool useChildrenCache() {
    return true;
  }

  Future loadCue() async {
    if(sheet != null)
      return;
    sheet = await info().parseFunc(file);
  }

  PlaylistInfo info() {
    var _info = PlaylistInfo.info[type];
    if(_info != null)
      return _info;
    throw Exception('Unknown playlist type');
  }

  static FolderItemClassMeta classMeta() {
    return FolderItemClassMeta(
      className: (FolderItemPlaylist).toString(),
      fromUriFunc: fromUri,
      fromDocumentTreeItemFunc: fromDocumentTreeItem,
      isSupportedUriFunc: (uri) => uriType(uri) != PlaylistType.unknown
    );
  }
}
