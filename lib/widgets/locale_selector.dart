// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../models/locale_model.dart';
import '../util/locale_helper.dart';

class LocaleSelector extends StatefulWidget
{
  const LocaleSelector();

  @override
  LocaleSelectorState createState() => LocaleSelectorState();
}

class LocaleSelectorState extends State<LocaleSelector> {
  @override
  Widget build(context) {
    var localeModel = context.watch<LocaleModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
      child: Row(
        children: [
          Text(
            L(context).localeSelectorLabel,
            style: Theme.of(context).textTheme.headline6
          ),
          const Spacer(),
          DropdownButton<String>(
            value: localeModel.localeCode,
            items: [
              DropdownMenuItem(
                child: Text(L(context).localeSelectorDefault),
                value: ''
              ),
              const DropdownMenuItem(
                child: Text('English'),
                value: 'en'
              ),
              const DropdownMenuItem(
                child: Text('Русский (Russian)'),
                value: 'ru'
              )
            ],
            onChanged: (localeCode) {
              localeModel.setLocaleCode(localeCode ?? '');
            }
          )
        ]
      )
    );
  }
}
