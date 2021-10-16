// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../folder_items/folder_item_directory.dart';
import '../folder_items/folder_item_file.dart';
import '../folder_items/folder_item_playlist.dart';
import '../folder_items/folder_item_playlist_track.dart';
import '../util/collections_ex.dart';
import '../util/document_tree.dart';

class FolderItemClassMeta {
  final String className;
  final Future<FolderItem?> Function(String) fromUriFunc;
  final FolderItem? Function(DocumentTreeItem)? fromDocumentTreeItemFunc;
  final bool Function(String)? isSupportedUriFunc;

  const FolderItemClassMeta({
    required this.className,
    required this.fromUriFunc,
    required this.fromDocumentTreeItemFunc,
    required this.isSupportedUriFunc
  });
}

abstract class FolderItem {
  static final Map<String, FolderItem> itemCache = {};
  static final Map<String, AudioSource> audioSourceCache = {};
  static final Map<String, List<FolderItem>> childrenCache = {};
  static final invalid = FolderItemDirectory(DocumentTreeItem.invalid);

  bool isContainer();

  int sortOrder() {
    return 0;
  }

  String displayName();

  String uri();

  String fileUri() {
    return uri();
  }

  bool isChildOf(FolderItem item) {
    if(!item.isContainer())
      return false;
    return (uri() + DocumentTreeItem.pathSep).startsWith(item.uri() + DocumentTreeItem.pathSep);
  }

  Future<bool> exists();

  FolderItem parent();

  MediaItem mediaItem() {
    if(isContainer()) {
      return MediaItem(
        id: uri(),
        title: displayName(),
        playable: false
      );
    }

    var p = parent();

    return MediaItem(
      id: uri(),
      title: displayName(),
      album: p.displayName(),
      artist: p.parent().displayName(),
      playable: true
    );
  }

  Future<List<FolderItem>> children() async {
    if(!useChildrenCache())
      return await fetchChildren();

    var _uri = uri();
    var items = childrenCache[_uri];
    if(items != null)
      return items;

    items = await fetchChildren();
    childrenCache[_uri] = items;
    return items;
  }

  Future<List<FolderItem>> fetchChildren() async {
    return [];
  }

  static Future<List<FolderItem>> fetchChildrenFrom(FolderItem item) async {
    return await item.fetchChildren();
  }

  Stream<FolderItem> recursiveChildren() async* {
    yield* uniqueRecursiveChildren([]);
  }

  Stream<FolderItem> uniqueRecursiveChildren(List<FolderItem> addedItems) async* {
    if(!canFetchRecursiveChildren())
      return;

    var childItems = await children();
    for(var childItem in childItems) {
      if(childItem.isContainer()) {
        yield* childItem.uniqueRecursiveChildren(addedItems);
      } else {
        if(!childItem.isRealFileUri() || addedItems.indexWhere((item) => item.fileUri() == childItem.fileUri()) == -1) {
          yield childItem;
          addedItems.add(childItem);
        }
      }
    }
  }

  IconData icon();

  bool canFetchRecursiveChildren() {
    return false;
  }

  bool isRealFileUri() {
    return true;
  }

  static T audioSourceByUri<T extends AudioSource>(String uri, T Function() f) {
    var src = audioSourceCache[uri];
    if(src != null)
      return src as T;
    var newSrc = f();
    audioSourceCache[uri] = newSrc;
    return newSrc;
  }

  AudioSource audioSource() {
    return audioSourceByUri(uri(), createAudioSource);
  }

  AudioSource createAudioSource() {
    return SilenceAudioSource(duration: const Duration());
  }

  bool useChildrenCache() {
    return false;
  }

  static final List<FolderItemClassMeta> classMetas = [
    FolderItemDirectory.classMeta(),
    FolderItemFile.classMeta(),
    FolderItemPlaylist.classMeta(),
    FolderItemPlaylistTrack.classMeta()
  ]..sort((a, b) {
    var diff = (a.isSupportedUriFunc != null ? 0 : 1) - (b.isSupportedUriFunc != null ? 0 : 1);
    if(diff != 0)
      return diff;
    diff = (a.fromDocumentTreeItemFunc == null ? 0 : 1) - (b.fromDocumentTreeItemFunc == null ? 0 : 1);
    if(diff != 0)
      return diff;
    return a.className.compareTo(b.className);
  });

  static Future<FolderItem?> fromUri(String uri) async {
    if(uri.isEmpty)
      return null;

    var item = itemCache[uri];
    if(item != null)
      return item;

    DocumentTreeItem? documentTreeItem;

    for(var meta in classMetas) {
      if(meta.isSupportedUriFunc != null && !meta.isSupportedUriFunc!(uri))
        continue;
      if(meta.fromDocumentTreeItemFunc != null) {
        documentTreeItem ??= await DocumentTreeItem.fromUri(uri);
        if(documentTreeItem == null)
          return null;
        item = meta.fromDocumentTreeItemFunc!(documentTreeItem);
        if(item != null)
          break;
        continue;
      }
      item = await meta.fromUriFunc(uri);
      if(item != null)
        break;
    }

    if(item != null)
      itemCache[uri] = item;
    return item;
  }

  static Future<T?> fromUriByType<T extends FolderItem>(String uri) async {
    if(uri.isEmpty)
      return null;

    var item = itemCache[uri];
    if(item is T)
      return item;

    var f = classMetas.firstWhereOrNull((m) => m.className == T.toString())?.fromUriFunc;
    if(f == null)
      return null;
    item = await f(uri);
    if(item == null)
      return null;
    itemCache[uri] = item;
    return item as T;
  }

  static FolderItem? fromDocumentTreeItem(DocumentTreeItem docItem) {
    var item = itemCache[docItem.uri];
    if(item != null)
      return item;

    for(var meta in classMetas) {
      if(meta.fromDocumentTreeItemFunc == null)
        continue;

      item = meta.fromDocumentTreeItemFunc!(docItem);
      if(item != null) {
        itemCache[docItem.uri] = item;
        return item;
      }
    }
    return null;
  }
}
