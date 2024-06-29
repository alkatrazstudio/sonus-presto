// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:super_tooltip/super_tooltip.dart';

import '../util/prefs.dart';

class ShowcaseController {
  ShowcaseController(this.name, this.version);

  static const prefsPrefix = 'showcase_';

  final String name;
  final int version;

  final controller = SuperTooltipController();

  Completer<void>? future;

  Future<void> show() async {
    var v = await Prefs.getInt(prefsPrefix + name);
    if(v == version)
      return;

    await WidgetsBinding.instance.endOfFrame;

    var curFuture = Completer<void>();
    future = curFuture;
    controller.showTooltip();
    return curFuture.future;
  }

  Future<void> hide() async {
    await controller.hideTooltip();
  }

  void onHide() {
    Prefs.setInt(prefsPrefix + name, version);
    future?.complete();
  }
}

class Showcase extends StatelessWidget {
  const Showcase({
    required this.text,
    required this.tooltipDirection,
    required this.controller,
    required this.child
  });

  final String text;
  final TooltipDirection tooltipDirection;
  final ShowcaseController controller;
  final Widget child;

  @override
  Widget build(context) {
    return SuperTooltip(
      controller: controller.controller,
      popupDirection: tooltipDirection,
      borderWidth: 0,
      borderColor: Colors.transparent,
      backgroundColor: Theme.of(context).primaryColor,
      arrowLength: 50,
      hasShadow: false,
      onHide: controller.onHide,
      content: GestureDetector(
        onTap: () {
          controller.hide();
        },
        child: Material(
          color: Theme.of(context).primaryColor,
          child: Text(
            text,
            softWrap: true,
            style: TextStyle(color: Theme.of(context).colorScheme.surface)
          )
        )
      ),
      child: child,
    );
  }
}


/*
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
    var controller = SuperTooltipController();

    await WidgetsBinding.instance.endOfFrame;

    if(key.currentWidget == null)
      return;
    var context = key.currentContext;
    if(context == null)
      return;
    var targetBox = context.findRenderObject();
    if(targetBox is! RenderBox)
      return;
    var overlayBox = Overlay.of(context).context.findRenderObject();
    if(overlayBox is! RenderBox)
      return;

    tooltip =

    await controller.showTooltip();
    return future.future;
  }

  static Future markAsComplete(ShowcaseGlobalKey key) async {

  }
}
*/
