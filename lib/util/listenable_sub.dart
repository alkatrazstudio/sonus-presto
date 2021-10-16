// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/foundation.dart';

class ListenableSub {
  ListenableSub(
    this.listenable,
    this.callback
  ) {
    listenable.addListener(callback);
  }

  final Listenable listenable;
  final VoidCallback callback;

  void dispose() {
    listenable.removeListener(callback);
  }
}
