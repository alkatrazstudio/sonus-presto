// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';

import '../models/playback_state_model.dart';
import '../util/audio_player_handler.dart';

class ControlSlider extends StatefulWidget {
  const ControlSlider({
    required this.onPrev,
    required this.onPlayToggle,
    required this.onNext,
    required this.onStop,
  });

  final void Function() onPrev;
  final void Function() onPlayToggle;
  final void Function() onNext;
  final void Function() onStop;

  @override
  ControlSliderState createState() => ControlSliderState();
}

class ControlSliderState extends State<ControlSlider> {
  static const timerIntervalMsecs = 100;
  static const timeTickToFast = 15;
  static const timerTicksPerFastStep = 10;
  static const fastSteps = 10;
  static const prevThreshold = -0.75;
  static const nextThreshold = 0.75;

  Timer? timer;
  final isFastNotifier = ValueNotifier(false);
  final valueListener = ValueNotifier(0.0);

  bool get isBack => valueListener.value < prevThreshold;
  bool get isForward => valueListener.value > nextThreshold;

  @override
  void initState() {
    super.initState();
  }

  void enableTimer() {
    if(timer?.isActive ?? false)
      return;

    timer = Timer.periodic(const Duration(milliseconds: timerIntervalMsecs), (timer) async {
      if(isFastNotifier.value) {
        var state = audioHandler.playbackState.valueOrNull;
        var mItem = audioHandler.mediaItem.valueOrNull;
        var totalDuration = mItem?.duration;
        if(
          totalDuration == null ||
          totalDuration.inSeconds < 1 ||
          state == null ||
          state.processingState != AudioProcessingState.ready
        ) {
          return;
        }

        Duration posStep;
        if(state.playing) {
          if((timer.tick - timeTickToFast - 1).remainder(timerTicksPerFastStep) != 0)
            return;
          posStep = Duration(microseconds: (totalDuration.inMicroseconds / fastSteps).truncate());
        } else {
          posStep = Duration(microseconds: (totalDuration.inMicroseconds / fastSteps / timerTicksPerFastStep).truncate());
        }

        var pos = state.position;
        if(isBack) {
          pos -= posStep;
          if(pos < const Duration())
            pos = const Duration();
        } else if(isForward) {
          if(pos + posStep < totalDuration)
            pos += posStep;
        }

        audioHandler.seek(pos);
      } else if(timer.tick >= timeTickToFast) {
        isFastNotifier.value = true;
      }
    });
  }

  void disableTimer() {
    isFastNotifier.value = false;
    timer?.cancel();
  }

  @override
  void dispose() {
    timer?.cancel();
    isFastNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    var dragStartX = 0.0;
    valueListener.value = 0;

    var animatedIcon = AnimatedBuilder(
      animation: Listenable.merge([
        valueListener,
        isFastNotifier
      ]),
      builder: (context, child) {
        IconData iconData;
        if(isBack) {
          enableTimer();
          iconData = isFastNotifier.value ? Icons.fast_rewind : Icons.skip_previous;
        } else if(isForward) {
          enableTimer();
          iconData = isFastNotifier.value ? Icons.fast_forward : Icons.skip_next;
        } else {
          disableTimer();
          if(context.watch<PlaybackStateModel>().isPlaying)
            iconData = Icons.pause_circle_outline;
          else
            iconData = Icons.play_circle_outline;
        }
        return Icon(
          iconData,
          size: 45
        );
      }
    );

    final handle = GestureDetector(
      onHorizontalDragStart: (details) {
        dragStartX = details.localPosition.dx;
      },
      onHorizontalDragUpdate: (details) {
        var deltaX = details.localPosition.dx - dragStartX;
        var w = context.size!.width;
        valueListener.value = (deltaX / w * 2 * 2).clamp(-1.0, 1.0);
      },
      onHorizontalDragEnd: (details) {
        if(!isFastNotifier.value) {
          if(isBack)
            widget.onPrev();
          else if(isForward)
            widget.onNext();
        }

        valueListener.value = 0;
      },

      child: InkWell(
        onTap: widget.onPlayToggle,
        onLongPress: widget.onStop,
        child: SizedBox(
          width: 150,
          child: animatedIcon
        )
      )
    );

    var mainWidget = AnimatedBuilder(
      animation: valueListener,
      builder: (context, child) {
        return Align(
          alignment: Alignment(valueListener.value, .5),
          child: child
        );
      },
      child: handle
    );

    return mainWidget;
  }
}
