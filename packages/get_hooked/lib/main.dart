import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_hooked/get_hooked.dart';

final rng = math.Random();

void main() {
  runApp(const MainApp());
}

class MainApp extends HookWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorAnimation = Hooked.useValue(
      key: Colors,
      initialValue: Colors.black,
      duration: Durations.medium1,
    );

    return MaterialApp(
      home: Scaffold(
        backgroundColor: colorAnimation.value,
        body: Center(child: _CounterLabel()),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            colorAnimation.animateTo(Color(0xFF000000 + rng.nextInt(0x1000000)));
          },
          child: Icon(Icons.color_lens),
        ),
      ),
    );
  }
}

class _CounterLabel extends HookWidget {
  const _CounterLabel();

  @override
  Widget build(BuildContext context) {
    final Color value = useValueListenable(Hooked.getValue<Color>(key: Colors));
    return Text('Colorful!', style: TextTheme.of(context).headlineSmall!.copyWith(color: value));
  }
}
