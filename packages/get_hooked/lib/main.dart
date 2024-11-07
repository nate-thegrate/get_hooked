import 'package:flutter/material.dart';
import 'package:get_hooked/get_hooked.dart';

final counter = Get.value(0);

void incrementCounter() {
  counter.update((value) => value + 1);
}

Widget builder(BuildContext context) {
  return AppBar(title: const Text('"Get Hooked" Demo'));
}

Widget hookBuilder(BuildContext context) {
  return Text(
    Use.watch(counter).toString(),
    style: Theme.of(context).textTheme.headlineMedium,
  );
}

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Builder(builder: builder),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You have pushed the button this many times:'),
              HookBuilder(builder: hookBuilder),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: incrementCounter,
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ),
      ),
    ),
  );
}
