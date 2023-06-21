// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';

import '../models/playback_state_model.dart';
import '../widgets/control_slider.dart';
import '../widgets/options_popup.dart';
import '../util/showcase_util.dart';

class ControlPane extends StatelessWidget {
  static const optionsPopupBtnShowcaseKey = ShowcaseGlobalKey('optionsPopupBtn', 1);
  static const controlSliderShowcaseKey = ShowcaseGlobalKey('controlSlider', 1);

  const ControlPane({
    required this.onPrevTap,
    required this.onPauseTap,
    required this.onStopTap,
    required this.onPlayTap,
    required this.onNextTap,
    required this.onLocateFile
  });

  final void Function() onPrevTap;
  final void Function() onPauseTap;
  final void Function() onStopTap;
  final void Function() onPlayTap;
  final void Function() onNextTap;
  final void Function() onLocateFile;

  @override
  Widget build(context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      color: Theme.of(context).bottomAppBarTheme.color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50
          ),
          const Spacer(),
          SizedBox(
            width: 200,
            key: controlSliderShowcaseKey,
            child: ControlSlider(
              onNext: () {
                if(context.read<PlaybackStateModel>().canPlayNext)
                  onNextTap();
              },
              onPrev: () {
                if(context.read<PlaybackStateModel>().canPlayPrev)
                  onPrevTap();
              },
              onPlayToggle: () {
                if(context.read<PlaybackStateModel>().mediaId == '')
                  return;
                if(context.read<PlaybackStateModel>().isPlaying)
                  onPauseTap();
                else
                  onPlayTap();
              },
              onStop: () {
                if(context.read<PlaybackStateModel>().mediaId == '')
                  return;
                if(context.read<PlaybackStateModel>().processingState != AudioProcessingState.idle)
                  onStopTap();
              }
            )
          ),
          const Spacer(),
          SizedBox(
            width: 50,
            child: IconButton(
              icon: const Icon(Icons.more_vert),
              key: optionsPopupBtnShowcaseKey,
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (context) {
                    return OptionsPopup(
                      onLocateFile: onLocateFile
                    );
                  }
                );
              }
            )
          )
        ]
      )
    );
  }
}
