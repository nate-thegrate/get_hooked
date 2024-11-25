import 'dart:math' as math;

import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:get_hooked/get_hooked.dart';

final rng = math.Random();

final getCount = Get.it(0);

class Counter extends MaterialApp {
  const Counter({super.key})
    : super(debugShowCheckedModeBanner: false, home: _home);

  static const _home = Scaffold(
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: Builder(builder: _builder),
    ),
    drawer: ScreenSelect(),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('You have pushed the button this many times:'),
          HookBuilder(builder: _hookBuilder),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: incrementCounter,
      tooltip: 'Increment',
      child: Icon(Icons.add),
    ),
  );

  /// Maybe someday, [AppBar] will have a `const` constructor.
  static Widget _builder(BuildContext context) {
    return AppBar(title: const Text('"Get Hooked" Demo'));
  }

  static Widget _hookBuilder(BuildContext context) {
    return Text(
      Ref.watch(getCount).toString(),
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }

  static void incrementCounter() => getCount.value += 1;
}
