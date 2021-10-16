// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

class PlaylistTrack {
  static const cueFramesPerSecond = 75;

  String numberStr = '';
  int number = 0;
  String filename = '';
  String title = '';
  String artist = '';
  String album = '';
  Duration? index0;
  Duration? index1;
}

class Playlist {
  List<PlaylistTrack> tracks = [];
}
