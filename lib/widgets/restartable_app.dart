// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';

class RestartableApp extends StatelessWidget {
  static var keyNotifier = ValueNotifier(UniqueKey());

  static void restart() {
    keyNotifier.value = UniqueKey();
  }

  const RestartableApp({
    required this.child
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: keyNotifier,
      builder: (context, UniqueKey value, _) {
        return KeyedSubtree(
          key: value,
          child: child
        );
      }
    );
  }
}
