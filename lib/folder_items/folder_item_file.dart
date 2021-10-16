// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';
import 'package:path/path.dart';

import 'package:just_audio/just_audio.dart';

import '../folder_items/folder_item.dart';
import '../folder_items/folder_item_directory.dart';
import '../util/document_tree.dart';

class FolderItemFile extends FolderItem {
  static const List<String> exts = [
    '.3gp',
    '.aac',
    '.ac3',
    '.adts',
    '.aiff',
    '.ape',
    '.avi',
    '.flac',
    '.m2ts',
    '.m4a',
    '.mkv',
    '.mp3',
    '.mp4',
    '.mts',
    '.ogg',
    '.ogx',
    '.ts',
    '.tta',
    '.wav',
    '.wma',
    '.wmv',
    '.wv',
    '.webm'
  ];

  DocumentTreeItemFile file;

  FolderItemFile(this.file);

  static bool isSupportedUri(String uri) {
    var ext = extension(uri).toLowerCase();
    return exts.contains(ext);
  }

  static Future<FolderItemFile?> fromUri(String uri) async {
    if(!isSupportedUri(uri))
      return null;
    var docItem = await DocumentTreeItem.fromUri(uri);
    if(docItem is DocumentTreeItemFile)
      return FolderItemFile(docItem);
    return null;
  }

  static FolderItemFile? fromDocumentTreeItem(DocumentTreeItem docItem) {
    if(docItem is! DocumentTreeItemFile)
      return null;
    if(!isSupportedUri(docItem.name))
      return null;
    return FolderItemFile(docItem);
  }

  @override
  bool isContainer() {
    return false;
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
  IconData icon() {
    return Icons.music_note;
  }

  @override
  AudioSource createAudioSource() {
    var uri = Uri.parse(file.uri);
    return AudioSource.uri(uri);
  }

  static FolderItemClassMeta classMeta() {
    return FolderItemClassMeta(
      className: (FolderItemFile).toString(),
      fromUriFunc: fromUri,
      fromDocumentTreeItemFunc: fromDocumentTreeItem,
      isSupportedUriFunc: isSupportedUri
    );
  }
}
