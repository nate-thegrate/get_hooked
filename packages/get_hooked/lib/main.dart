import 'package:flutter/material.dart';
import 'package:get_hooked/get_hooked.dart';

final getCount = Get.value(0);

class App extends MaterialApp {
  const App({super.key}) : super(debugShowCheckedModeBanner: false, home: _home);

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
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: incrementCounter,
      tooltip: 'Increment',
      child: Icon(Icons.add),
    ),
  );

  static Widget _builder(BuildContext context) {
    return AppBar(title: const Text('"Get Hooked" Demo'));
  }

  static Widget _hookBuilder(BuildContext context) {
    return Text(
      Use.watch(getCount).toString(),
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }

  static void incrementCounter() {
    getCount.update((value) => value + 1);
  }
}

void main() => runApp(const App());
