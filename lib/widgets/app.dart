// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/dir_model.dart';
import '../models/locale_model.dart';
import '../models/playback_state_model.dart';
import '../models/scheme_model.dart';
import '../util/audio_player_handler.dart';
import '../util/locale_helper.dart';
import '../util/prefs.dart';
import '../widgets/blocking_spinner.dart';
import '../widgets/homepage.dart';
import '../widgets/restartable_app.dart';

void appMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  var prefsFuture = Prefs.init();

  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'net.alkatrazstudio.sonuspresto.channel.audio',
      androidNotificationChannelName: 'Playback controls',
      androidNotificationIcon: 'drawable/ic_notification',
      androidNotificationOngoing: true
    )
  );

  await prefsFuture;

  var schemeModel = SchemeModel();
  schemeModel.init();
  var localeModel = LocaleModel();
  localeModel.init();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => PlaybackStateModel()),
      ChangeNotifierProvider.value(value: schemeModel),
      ChangeNotifierProvider.value(value: DirModel.instance),
      ChangeNotifierProvider.value(value: localeModel)
    ],
    child: const RestartableApp(
      child: MyApp()
    )
  ));
}

class MyApp extends StatefulWidget {
  const MyApp();

  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  static ThemeMode schemeVariantToThemeMode(SchemeVariant schemeVariant) {
    if(schemeVariant == SchemeVariant.system || schemeVariant == SchemeVariant.systemBlack)
      return ThemeMode.system;
    if(schemeVariant == SchemeVariant.light)
      return ThemeMode.light;
    return ThemeMode.dark;
  }

  @override
  Widget build(context) {
    var scheme = context.watch<SchemeModel>().scheme;
    var schemeVariant = context.watch<SchemeModel>().schemeVariant;
    var localeCode = context.watch<LocaleModel>().localeCode;

    return MaterialApp(
      title: appTitle,
      theme: FlexColorScheme.light(
        scheme: scheme,
        appBarStyle: FlexAppBarStyle.primary
      ).toTheme,
      darkTheme: FlexColorScheme.dark(
        scheme: scheme,
        appBarStyle: FlexAppBarStyle.primary,
        darkIsTrueBlack: schemeVariant == SchemeVariant.systemBlack || schemeVariant == SchemeVariant.black).toTheme,
      themeMode: schemeVariantToThemeMode(schemeVariant),
      home: const Stack(
        children: [
          HomePage(),
          BlockingSpinner()
        ]
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeCode.isEmpty ? null : Locale(localeCode)
    );
  }
}
