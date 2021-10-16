// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import '../playlist/playlist.dart';
import '../util/document_tree.dart';

String? _extractFirstVal(String line, RegExp rx) {
  var match = rx.firstMatch(line);
  if(match == null)
    return null;
  var val = match.group(1);
  if(val == null)
    return null;
  if(val.length < 2)
    return val;
  if((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'")))
    return val.substring(1, val.length - 1);
  return val;
}

Duration? _extractDuration(String line, RegExp rx) {
  var match = rx.firstMatch(line);
  if(match == null)
    return null;

  var m = int.parse(match.namedGroup('m') ?? '');
  var s = int.parse(match.namedGroup('s') ?? '');
  var f = int.parse(match.namedGroup('f') ?? '');

  return Duration(
      minutes: m,
      seconds: s,
      microseconds: (Duration.microsecondsPerSecond * f / PlaylistTrack.cueFramesPerSecond).truncate()
  );
}

Future<Playlist> parseCue(DocumentTreeItemFile playlistFileItem) async {
  var lines = await playlistFileItem.readLines();
  var sheet = Playlist();

  var rxTitle = RegExp(r'^TITLE\s+(.+)$');
  var rxPerformer = RegExp(r'^PERFORMER\s+(.+)$');
  var rxFile = RegExp(r'^FILE\s+(.+)\s+(?:WAVE|MP3|AIFF)$');
  var rxTrack = RegExp(r'^TRACK\s+(\d+)\s+AUDIO$');
  var rxIndex0 = RegExp(r'^INDEX\s+00\s+(?<m>\d+):(?<s>\d+):(?<f>\d+)$');
  var rxIndex1 = RegExp(r'^INDEX\s+01\s+(?<m>\d+):(?<s>\d+):(?<f>\d+)$');

  var cueDir = playlistFileItem.parent();
  var lastFilename = '';
  PlaylistTrack? track;
  String? artist;
  String? album;
  for(var line in lines) {
    line = line.trim();

    var filename = _extractFirstVal(line, rxFile);
    if(filename != null && filename.isNotEmpty) {
      lastFilename = DocumentTreeItem.resolvePath(cueDir.uri, filename);
      continue;
    }

    var title = _extractFirstVal(line, rxTitle);
    if(title != null) {
      if(track != null)
        track.title = title;
      else
        album = title;
      continue;
    }

    var performer = _extractFirstVal(line, rxPerformer);
    if(performer != null) {
      if(track != null)
        track.artist = performer;
      else
        artist = performer;
      continue;
    }

    if(lastFilename.isEmpty)
      continue;

    var number = _extractFirstVal(line, rxTrack);
    if(number != null) {
      if(track != null)
        sheet.tracks.add(track);
      track = PlaylistTrack();
      track.numberStr = number;
      track.number = int.parse(number);
      track.filename = lastFilename;
      track.album = album ?? '';
      track.artist = artist ?? '';
      continue;
    }

    if(track == null)
      continue;

    var duration0 = _extractDuration(line, rxIndex0);
    if(duration0 != null) {
      track.index0 = duration0;
      continue;
    }

    var duration1 = _extractDuration(line, rxIndex1);
    if(duration1 != null) {
      track.index1 = duration1;
      continue;
    }
  }

  if(track != null)
    sheet.tracks.add(track);

  return sheet;
}
