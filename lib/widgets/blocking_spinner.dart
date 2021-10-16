// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../util/locale_helper.dart';
import '../widgets/loading_indicator.dart';

enum BlockingSpinnerState {
  hidden,
  shown,
  interrupted
}

class BlockingSpinnerModel extends ChangeNotifier {
  var state = BlockingSpinnerState.hidden;

  void setState(BlockingSpinnerState newState) {
    state = newState;
    notifyListeners();
  }
}

class BlockingSpinner extends StatelessWidget {
  static final model = BlockingSpinnerModel();

  const BlockingSpinner();

  static Future<T> showWhile<T>(Future<T> Function() func) async {
    model.setState(BlockingSpinnerState.shown);
    try {
      var result = await func();
      model.setState(BlockingSpinnerState.hidden);
      return result;
    } catch(e) {
      model.setState(BlockingSpinnerState.hidden);
      rethrow;
    }
  }

  static bool get isInterrupted => model.state == BlockingSpinnerState.interrupted;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => model,
      child: Builder(
        builder: (context) {
          var model = context.watch<BlockingSpinnerModel>();
          if(model.state == BlockingSpinnerState.hidden)
            return const SizedBox.shrink();

          return Container(
            color: const Color.fromARGB(128, 0, 0, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const LoadingIndicator(),
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: ElevatedButton(
                    child: Text(L(context).btnCancel),
                    onPressed: () {
                      model.setState(BlockingSpinnerState.interrupted);
                    }
                  )
                )
              ]
            ),
            constraints: const BoxConstraints.expand()
          );
        }
      )
    );
  }
}
