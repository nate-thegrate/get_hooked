import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:get_hooked/get_hooked.dart';

final getCount = Get.it(0);

Widget _counterText(BuildContext context) {
  return TextGetter(getCount, style: MaterialTextStyle.headlineMedium);
}

class Counter extends MaterialApp {
  const Counter({super.key})
    : super(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          appBar: AppBarConst(title: Text('"Get Hooked" Demo')),
          drawer: ScreenSelect(),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('You have pushed the button this many times:'),
                Builder(builder: _counterText),
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

  static void _incrementCounter() => getCount.value += 1;
}
