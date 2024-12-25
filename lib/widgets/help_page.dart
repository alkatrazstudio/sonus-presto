// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2024, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:help_page/help_page.dart';

import '../util/locale_helper.dart';

String _h(String s) {
  return const HtmlEscape().convert(s);
}

void showHelpPage(BuildContext context) {
  Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (context) => HelpPage(
      appTitle: appTitle,
      githubAuthor: 'alkatrazstudio',
      githubProject: 'sonus-presto',
      manualHtml: '''
<h2>${_h(L(context).helpManualStart)}</h2>
<p>${_h(L(context).helpManualStartDetails(appTitle))}</p>
<p>${_h(L(context).helpManualStartSelectRoot(appTitle))}</p>
<p>${_h(L(context).helpManualStartChangeRoot)}</p>

<h2>${_h(L(context).helpManualMain)}</h2>
<p>${_h(L(context).helpManualMainDetails)}</p>
<p>${_h(L(context).helpManualMainSwipeRight)}</p>
<p>${_h(L(context).helpManualMainSwipeLeft)}</p>
<p>${_h(L(context).helpManualMainPlaylistFolders)}</p>
<p>${_h(L(context).helpManualMainLongPress)}</p>

<h2>${_h(L(context).helpManualTitle)}</h2>
<p>${_h(L(context).helpManualTitleDetails)}</p>
<p>${_h(L(context).helpManualTitleSwipe)}</p>

<h2>${_h(L(context).helpManualPlayback)}</h2>
<p>${_h(L(context).helpManualPlaybackDetails)}</p>
<p>${_h(L(context).helpManualPlaybackTap)}</p>
<p>${_h(L(context).helpManualPlaybackSwipe)}</p>
<p>${_h(L(context).helpManualPlaybackSwipeHold)}</p>
<p>${_h(L(context).helpManualPlaybackTapHold)}</p>

<h2>${_h(L(context).helpManualOptions)}</h2>
<p>${_h(L(context).helpManualOptionsDetails)}</p>
<p>${_h(L(context).helpManualOptionsLocateFile)}</p>
''',
      showGooglePlayLink: true,
      license: HelpPageLicense.gpl3,
      author: 'Алексей Парфёнов (Alexey Parfenov) aka ZXED',
      authorWebsite: 'https://alkatrazstudio.net/',
      libraries: [
        HelpPagePackage.flutter('just_audio', HelpPageLicense.mit),
        HelpPagePackage.flutter('audio_service', HelpPageLicense.mit),
        HelpPagePackage.flutter('audio_session', HelpPageLicense.mit),
        HelpPagePackage.flutter('shared_preferences', HelpPageLicense.bsd3),
        HelpPagePackage.flutter('flex_color_scheme', HelpPageLicense.bsd3),
        HelpPagePackage.flutter('provider', HelpPageLicense.mit),
        HelpPagePackage.flutter('super_tooltip', HelpPageLicense.mit),
        HelpPagePackage.flutter('flutter_gen', HelpPageLicense.mit),
        HelpPagePackage.flutter('flutter_lints', HelpPageLicense.bsd3),
        HelpPagePackage.flutter('collection', HelpPageLicense.bsd3),
        HelpPagePackage.flutter('path', HelpPageLicense.bsd3),
      ],
      assets: [
        HelpPagePackage.foss(
          name: 'Music Folder SVG Vector',
          url: 'https://www.svgrepo.com/svg/5688/music-folder',
          license: HelpPageLicense.ccZero1
        )
      ],
    ))
  );
}
