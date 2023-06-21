// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:provider/provider.dart';

import '../models/scheme_model.dart';
import '../util/locale_helper.dart';
import '../widgets/scheme_tile.dart';

class SchemeSelector extends StatefulWidget {
  const SchemeSelector();

  @override
  SchemeSelectorState createState() => SchemeSelectorState();
}

class SchemeSelectorState extends State<SchemeSelector> {
  bool doScroll = true;

  double scrollOffset(BuildContext context, FlexScheme scheme) {
    var i = FlexColor.schemes.keys.toList().indexOf(scheme);
    var centerOffset = (context.size?.width ?? 0) / 2 - SchemeTile.fullWidth / 2;
    var pos = i * SchemeTile.fullWidth - centerOffset;
    if(pos < 0)
      pos = 0;
    return pos;
  }

  @override
  Widget build(context) {
    var schemeModel = context.watch<SchemeModel>();

    final scrollController = ScrollController();
    if(doScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(scrollController.hasClients) {
          scrollController.animateTo(
              scrollOffset(context, schemeModel.scheme), duration: const Duration(microseconds: 1),
              curve: Curves.linear);
        }
      });
      doScroll = false;
    }

    var variantTitles = {
      SchemeVariant.system: L(context).schemeSystem,
      SchemeVariant.systemBlack: L(context).schemeSystemBlack,
      SchemeVariant.light: L(context).schemeLight,
      SchemeVariant.dark: L(context).schemeDark,
      SchemeVariant.black: L(context).schemeBlack
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
          child: Row(
            children: [
              Text(
                L(context).schemeLabel,
                style: Theme.of(context).textTheme.titleLarge
              ),
              const Spacer(),
              DropdownButton<SchemeVariant>(
                value: schemeModel.schemeVariant,
                items: variantTitles.entries.map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value)
                )).toList(),
                onChanged: (v) {
                  v ??= SchemeVariant.system;
                  schemeModel.setSchemeVariant(v);
                }
              )
            ]
          )
        ),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            controller: scrollController,
            children: FlexColor.schemes.entries.map((schemeEntry) => SchemeTile(
              scheme: schemeEntry.key,
              isCurrent: schemeEntry.key == schemeModel.scheme,
              onSelected: () {
                schemeModel.setScheme(schemeEntry.key);
              }
            )).toList()
          )
        )
      ]
    );
  }
}
