// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';

import '../widgets/loading_indicator.dart';

class FutureWithSpinner<T> extends StatelessWidget
{
  final Future<T> future;
  final Widget Function(T data) childFunc;

  const FutureWithSpinner({
    required this.future,
    required this.childFunc
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
        future: future,
        builder: (context, snapshot) {
          var data = snapshot.data;
          if (snapshot.hasData && data != null) {
            return childFunc(data);
          } else if(snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          return const LoadingIndicator();
        }
    );
  }
}
