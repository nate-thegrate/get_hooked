import 'package:flutter/material.dart';
import 'package:get_hooked/get_hooked.dart';

import '../main.dart';

final count = Get.it(0);

class Counter extends StatelessWidget {
  const Counter({super.key});

  static void _incrementCounter() => count.value += 1;

  static Widget _counterText(BuildContext context) {
    return Text(ref.watch(count).toString(), style: TextTheme.of(context).headlineMedium);
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBarConst(title: Text('"Get Hooked" Demo')),
        drawer: ScreenSelect(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You have pushed the button this many times:'),
              HookBuilder(_counterText),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
