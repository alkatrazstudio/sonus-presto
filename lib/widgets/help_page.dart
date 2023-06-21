// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../util/locale_helper.dart';
import '../util/swift_scroll_physics.dart';
import '../widgets/future_with_spinner.dart';

class Tab {
  final String Function(BuildContext) label;
  final IconData icon;
  final Future<String> Function(BuildContext) htmlFunc;
  Future<String>? _html;

  Tab({
    required this.label,
    required this.icon,
    required this.htmlFunc
  });

  Future<String> html(BuildContext context) {
    _html ??= htmlFunc(context);
    return _html!;
  }
}

String _h(String s) {
  return const HtmlEscape().convert(s);
}

class _KeyValRow {
  final String key;
  final String? keyLink;
  final String val;
  final String? valLink;

  _KeyValRow({
    required this.key,
    this.keyLink,
    required this.val,
    this.valLink
  });

  static String renderLink(String text, String? link) {
    if(link == null)
      return _h(text);
    return '<a href="${_h(link)}">${_h(text)}</a>';
  }

  static String renderRows(List<_KeyValRow> rows) {
    return rows.map((row) {
      return '<tr><td>${renderLink(row.key, row.keyLink)}</td><td>${renderLink(row.val, row.valLink)}</td></tr>';
    }).join();
  }

  static String renderParagraphs(List<_KeyValRow> rows) {
    return rows.map((row) {
      return '<strong style="font-size: ${FontSize.large.value}">${renderLink(row.key, row.keyLink)}:</strong>'
        '<div style="padding-bottom: 20">${renderLink(row.val, row.valLink)}</div>';
    }).join();
  }
}

class HelpPage extends StatefulWidget {
  const HelpPage();

  @override
  HelpPageState createState() => HelpPageState();

  static void open(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const HelpPage())
    );
  }
}

class HelpPageState extends State<HelpPage> {
  var selectedIndex = 0;

  var pageController = PageController(
    initialPage: 0,
    keepPage: true
  );
  var indexValue = ValueNotifier(0);

  var tabs = [
    manualTab(),
    aboutTab(),
    licensesTab()
  ];

  static const bsd = 'BSD 3-Clause';
  static const bsdUrl = 'https://opensource.org/licenses/BSD-3-Clause';
  static const mit = 'MIT';
  static const mitUrl = 'https://opensource.org/licenses/MIT';
  static const appBaseUrl = 'https://github.com/alkatrazstudio/sonus-presto';
  static const appBuildTimestamp = int.fromEnvironment('APP_BUILD_TIMESTAMP');
  static const appGitHash = String.fromEnvironment('APP_GIT_HASH');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appTitle)
      ),
      body: Center(
        child: PageView.builder(
          physics: const SwiftPageScrollPhysics(),
          itemBuilder: (context, index) {
            return SingleChildScrollView(
              key: PageStorageKey('help-tab:$index'),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: FutureWithSpinner<String>(
                  future: tabs[index].html(context),
                  childFunc: (html) {
                    return Html(
                      data: html,
                      extensions: const [
                        TableHtmlExtension()
                      ],
                      style: {
                        'th, td': Style(
                          fontSize: FontSize.large,
                          padding: HtmlPaddings.only(top: 10, bottom: 10, right: 20),
                          border: const Border(bottom: BorderSide(color: Colors.grey))
                        ),
                        'th + th, td + td': Style(
                          padding: HtmlPaddings.only(top: 10, bottom: 10, right: 0)
                        )
                      },
                      onLinkTap: (url, attributes, element) async {
                        if(url == null)
                          return;
                        var urlObj = Uri.parse(url);
                        if(!await canLaunchUrl(urlObj))
                          return;
                        await launchUrl(urlObj);
                      }
                    );
                  }
                )
              )
            );
          },
          itemCount: tabs.length,
          controller: pageController,
          onPageChanged: (value) {
            indexValue.value = value;
          }
        )
      ),
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: indexValue,
        builder: (context, int value, child) {
          return BottomNavigationBar(
            items: tabs.map((tab) => BottomNavigationBarItem(
              icon: Icon(tab.icon),
              label: tab.label(context)
            )).toList(),
            currentIndex: value,
            onTap: (newIndex) {
              pageController.animateToPage(
                newIndex,
                duration: const Duration(milliseconds: 200),
                curve: Curves.linear
              );
            }
          );
        }
      )
    );
  }

  static Tab manualTab() {
    return Tab(
      label: (context) => L(context).helpManual,
      icon: Icons.help,
      htmlFunc: (context) async => '''
        <h1 style="text-align: center">${_h(L(context).helpManual)}</h1>

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
      '''
    );
  }

  static Tab aboutTab() {
    return Tab(
      label: (context) => L(context).helpAbout,
      icon: Icons.music_note,
      htmlFunc: (context) async {
        var info = await PackageInfo.fromPlatform();
        var buildDate = DateTime.fromMillisecondsSinceEpoch(appBuildTimestamp * 1000);
        var buildStr = DateFormat.yMMMMd(L(context).localeName).format(buildDate);

        return '''
          <h1 style="text-align: center">${_h(appTitle)}</h1>
          <div style="text-align: center; padding-bottom: 50"><strong><em>v${_h(info.version)}</em></strong></div>
          ${_KeyValRow.renderParagraphs([
            _KeyValRow(key: L(context).helpAboutWebsite, val: appBaseUrl, valLink: appBaseUrl),
            _KeyValRow(key: L(context).helpAboutGooglePlay, val: 'https://play.google.com/store/apps/details?id=${info.packageName}', valLink: 'https://play.google.com/store/apps/details?id=${info.packageName}'),
            _KeyValRow(key: L(context).helpAboutIssues, val: '$appBaseUrl/issues', valLink: '$appBaseUrl/issues'),
            _KeyValRow(key: L(context).helpAboutChangelog, val: '$appBaseUrl/blob/master/CHANGELOG.md', valLink: '$appBaseUrl/blob/master/CHANGELOG.md'),
            _KeyValRow(key: L(context).helpAboutBuildDate, val: buildStr),
            _KeyValRow(key: L(context).helpAboutGitHash, val: appGitHash, valLink: '$appBaseUrl/tree/$appGitHash'),
            _KeyValRow(key: L(context).helpAboutPackageName, val: info.packageName),
            _KeyValRow(key: L(context).helpAboutBuildSignature, val: info.buildSignature),
            _KeyValRow(key: L(context).helpAboutBuildNumber, val: info.buildNumber),
            _KeyValRow(key: L(context).helpAboutLicense, val: 'GPLv3', valLink: 'https://www.gnu.org/licenses/gpl-3.0.txt'),
            _KeyValRow(key: L(context).helpAboutAuthor, val: 'Алексей Парфёнов (Alexey Parfenov) aka ZXED'),
            _KeyValRow(key: L(context).helpAboutAuthorWebsite, val: 'https://alkatrazstudio.net/', valLink: 'https://alkatrazstudio.net/')
          ])}
        ''';
      }
    );
  }

  static Tab licensesTab() {
    return Tab(
      label: (context) => L(context).helpLicenses,
      icon: Icons.sticky_note_2,
      htmlFunc: (context) async => '''
        <h1 style="text-align: center">${_h(L(context).helpLicenses)}</h1>

        <h2>${_h(L(context).helpLicensesLibraries)}</h2>
        <p>${_h(L(context).helpLicensesLibrariesDetails(appTitle))}</p>

        <table>
          <thead>
            <tr>
              <th>${_h(L(context).helpLicensesHeaderLibrary)}</th>
              <th>${_h(L(context).helpLicensesHeaderLicense)}</th>
            </tr>
          </thead>
          <tbody>
          ${_KeyValRow.renderRows([
            _KeyValRow(key: 'Flutter', keyLink: 'https://flutter.dev', val: bsd, valLink: bsdUrl),
            _KeyValRow(key: 'just_audio', keyLink: 'https://pub.dev/packages/just_audio', val: mit, valLink: mitUrl),
            _KeyValRow(key: 'audio_service', keyLink: 'https://pub.dev/packages/audio_service', val: mit, valLink: mitUrl),
            _KeyValRow(key: 'audio_session', keyLink: 'https://pub.dev/packages/audio_session', val: mit, valLink: mitUrl),
            _KeyValRow(key: 'Shared preferences', keyLink: 'https://pub.dev/packages/shared_preferences', val: bsd, valLink: bsdUrl),
            _KeyValRow(key: 'FlexColorScheme', keyLink: 'https://pub.dev/packages/flex_color_scheme', val: bsd, valLink: bsdUrl),
            _KeyValRow(key: 'provider', keyLink: 'https://pub.dev/packages/provider', val: mit, valLink: mitUrl),
            _KeyValRow(key: 'flutter_html', keyLink: 'https://pub.dev/packages/flutter_html', val: mit, valLink: mitUrl),
            _KeyValRow(key: 'flutter_html_table', keyLink: 'https://pub.dev/packages/flutter_html_table', val: mit, valLink: mitUrl),
            _KeyValRow(key: 'super_tooltip', keyLink: 'https://pub.dev/packages/super_tooltip', val: mit, valLink: mitUrl),
            _KeyValRow(key: 'url_launcher', keyLink: 'https://pub.dev/packages/url_launcher', val: bsd, valLink: bsdUrl),
            _KeyValRow(key: 'PackageInfoPlus', keyLink: 'https://pub.dev/packages/package_info_plus', val: bsd, valLink: bsdUrl),
            _KeyValRow(key: 'FlutterGen', keyLink: 'https://pub.dev/packages/flutter_gen', val: mit, valLink: mitUrl),
            _KeyValRow(key: 'intl', keyLink: ' https://pub.dev/packages/intl', val: bsd, valLink: bsdUrl),
            _KeyValRow(key: 'flutter_lints', keyLink: 'https://pub.dev/packages/flutter_lints', val: bsd, valLink: bsdUrl),
            _KeyValRow(key: 'collection', keyLink: 'https://pub.dev/packages/collection', val: bsd, valLink: bsdUrl),
            _KeyValRow(key: 'path', keyLink: 'https://pub.dev/packages/path', val: bsd, valLink: bsdUrl)
          ])}
          </tbody>
        </table>

        <h2>${_h(L(context).helpLicensesAssets)}</h2>
        <p>${_h(L(context).helpLicensesAssetsDetails(appTitle))}</p>

        <table>
          <thead>
            <tr>
              <th>${_h(L(context).helpLicensesHeaderAsset)}</th>
              <th>${_h(L(context).helpLicensesHeaderLicense)}</th>
            </tr>
          </thead>
          <tbody>
          ${_KeyValRow.renderRows([
            _KeyValRow(key: 'Music Folder SVG Vector', keyLink: 'https://www.svgrepo.com/svg/5688/music-folder', val: 'CC0', valLink: 'https://creativecommons.org/publicdomain/zero/1.0/legalcode'),
            _KeyValRow(key: 'Material design icons', keyLink: 'https://google.github.io/material-design-icons/', val: 'Apache License 2.0', valLink: 'https://www.apache.org/licenses/LICENSE-2.0.txt')
          ])}
          </tbody>
        </table>
      '''
    );
  }
}
