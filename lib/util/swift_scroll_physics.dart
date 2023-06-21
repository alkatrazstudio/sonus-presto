// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/widgets.dart';

class SwiftPageScrollPhysics extends PageScrollPhysics {
  const SwiftPageScrollPhysics({ ScrollPhysics? parent }): super(parent: parent);

  @override
  SwiftPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SwiftPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 100,
    stiffness: 100,
    damping: 1
  );
}
