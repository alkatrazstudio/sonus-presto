// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';

import 'package:flex_color_scheme/flex_color_scheme.dart';

class SchemeTile extends StatelessWidget {
  static const double boxWidth = 35;
  static const double padding = 5;
  static const double fullWidth = boxWidth * 2 + padding * 2;

  const SchemeTile({
    required this.scheme,
    required this.isCurrent,
    required this.onSelected
  });

  final FlexScheme scheme;
  final bool isCurrent;
  final void Function() onSelected;

  FlexSchemeColor colors(BuildContext context) {
    if(Theme.of(context).brightness == Brightness.dark)
      return FlexColor.schemes[scheme]!.dark;
    return FlexColor.schemes[scheme]!.light;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      child: Container(
        color: isCurrent ? Theme.of(context).highlightColor : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(SchemeTile.padding),
          child: Column(
            children: [
              Row (
                children: [
                  SizedBox(
                    width: SchemeTile.boxWidth,
                    height: SchemeTile.boxWidth,
                    child: Container(
                      color: colors(context).primary
                    )
                  ),
                  SizedBox(
                    width: SchemeTile.boxWidth,
                    height: SchemeTile.boxWidth,
                    child: Container(
                      color: colors(context).primaryVariant
                    )
                  )
                ]
              ),
              Row (
                children: [
                  SizedBox(
                    width: SchemeTile.boxWidth,
                    height: SchemeTile.boxWidth,
                    child: Container(
                      color: colors(context).secondary
                    ),
                  ),
                  SizedBox(
                    width: SchemeTile.boxWidth,
                    height: SchemeTile.boxWidth,
                    child: Container(
                      color: colors(context).secondaryVariant
                    )
                  )
                ]
              )
            ]
          )
        )
      )
    );
  }
}
