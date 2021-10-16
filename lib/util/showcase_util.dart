// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:super_tooltip/super_tooltip.dart';

import '../util/prefs.dart';

class ShowcaseGlobalKey<T extends State<StatefulWidget>> extends GlobalKey<T> {
  const ShowcaseGlobalKey(this.name, this.version) : super.constructor();

  final String name;
  final int version;
}

class ShowcaseUtil {
  static const prefsPrefix = 'showcase_';

  static Future showForContext({
    required ShowcaseGlobalKey key,
    required String text,
    required TooltipDirection tooltipDirection
  }) async {
    var v = await Prefs.getInt(prefsPrefix + key.name);
    if(v == key.version)
      return;

    var future = Completer<void>();

    await WidgetsBinding.instance?.endOfFrame;

    if(key.currentWidget == null)
      return;
    var context = key.currentContext;
    if(context == null)
      return;
    var targetBox = context.findRenderObject();
    if(targetBox is! RenderBox)
      return;
    var overlayBox = Overlay.of(context)?.context.findRenderObject();
    if(overlayBox is! RenderBox)
      return;

    SuperTooltip? tooltip;
    tooltip = SuperTooltip(
      popupDirection: tooltipDirection,
      borderWidth: 0,
      borderColor: Colors.transparent,
      backgroundColor: Theme.of(context).primaryColor,
      outsideBackgroundColor: Colors.transparent,
      arrowLength: 50,
      hasShadow: false,
      onClose: () {
        markAsComplete(key);
        future.complete();
      },
      content: GestureDetector(
        onTap: () {
          tooltip?.close();
        },
        child: Material(
          color: Theme.of(context).primaryColor,
          child: Text(
            text,
            softWrap: true,
            style: TextStyle(color: Theme.of(context).backgroundColor)
          )
        )
      )
    );

    tooltip.show(context);
    return future.future;
  }

  static Future markAsComplete(ShowcaseGlobalKey key) async {
    await Prefs.setInt(prefsPrefix + key.name, key.version);
  }
}
