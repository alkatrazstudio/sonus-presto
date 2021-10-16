// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

extension CollectionsEx<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) f) {
    for(var item in this) {
      if(f(item))
        return item;
    }
    return null;
  }
}
