// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'dart:math';

import '../playlist/playlist.dart';
import '../util/document_tree.dart';

Future<Playlist> parseM3U(DocumentTreeItemFile playlistFileItem) async {
  var lines = await playlistFileItem.readLines();
  var playlist = Playlist();
  if(lines.isEmpty)
    return playlist;
  if(!lines[0].trim().startsWith('#EXTM3U'))
    return playlist;
  var playlistDir = playlistFileItem.parent();

  var rxTitle = RegExp(r'^#EXTINF:\s*(?:-?\d+[^,]*?(?:,|$))?\s*(?:([^-]*)?\s-\s)?(.*)$');
  var rxRemote = RegExp(r'^\w+://.+');

  var track = PlaylistTrack();
  track.number = 1;

  for(var line in lines.skip(1)) {
    line = line.trim();
    if(line.isEmpty)
      continue;

    if(!line.startsWith('#')) {
      if(rxRemote.hasMatch(line)) {
        track.filename = line;
        if(track.title.isEmpty)
          track.title = track.filename;
      } else {
        track.filename = DocumentTreeItem.resolvePath(playlistDir.uri, line);
      }
      playlist.tracks.add(track);
      var prevNumber = track.number;
      track = PlaylistTrack();
      track.number = prevNumber + 1;
      continue;
    }

    var match = rxTitle.firstMatch(line);
    if(match == null)
      continue;
    var artist = match.group(1);
    if(artist != null)
      track.artist = artist.trim();
    var title = match.group(2);
    if(title != null)
      track.title = title.trim();
  }

  var nDigits = (log(track.number + 1) / ln10).ceil();
  nDigits = max(2, nDigits);
  for(var track in playlist.tracks)
    track.numberStr = track.number.toString().padLeft(nDigits, '0');

  return playlist;
}
