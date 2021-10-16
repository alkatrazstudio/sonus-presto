// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';

import '../util/audio_player_handler.dart';

class ProgressBar extends StatelessWidget {
  final valueListener = ValueNotifier(0.0);

  ProgressBar() {
    AudioService.position.listen((curPos) {
      var duration = audioHandler.mediaItem.valueOrNull?.duration?.inMicroseconds ?? 0;
      if(duration == 0) {
        valueListener.value = 0;
        return;
      }
      valueListener.value = (curPos.inMicroseconds / duration).clamp(0, 1);
    });
  }

  @override
  Widget build(context) {
    return AnimatedBuilder(
      animation: valueListener,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: valueListener.value
        );
      }
    );
  }
}
