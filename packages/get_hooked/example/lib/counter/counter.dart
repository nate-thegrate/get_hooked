import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get_hooked/get_hooked.dart';

final rng = math.Random();

final getCount = Get.it(0);

final getColor = Get.it<Color>(Colors.blue);
void _randomColor([_]) {
  getColor.value = Color(rng.nextInt(0x1000000) + 0xff000000);
}

class Counter extends MaterialApp {
  const Counter({super.key})
    : super(debugShowCheckedModeBanner: false, home: _home);

  static const _home = Scaffold(
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: Builder(builder: _builder),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('You have pushed the button this many times:'),
          HookBuilder(builder: _hookBuilder),
          TapRegion(
            onTapInside: _randomColor,
            child: SizedBox.square(dimension: 300, child: MyPainter()),
          ),
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

class MyPainter extends HookPainter {
  const MyPainter({super.key});

  @override
  void paint(HookPaintContext context, Size size) {
    final Canvas canvas = context.stageCanvas();

    canvas.drawRect(Offset.zero & size, Paint()..color = Ref.watch(getColor));
  }
}
