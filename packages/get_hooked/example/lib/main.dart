import 'package:example/benchmark/benchmark.dart';
import 'package:example/counter/counter.dart';
import 'package:example/form/form.dart';
import 'package:flutter/material.dart';
import 'package:get_hooked/get_hooked.dart';

void main() => runApp(const App());

enum Screen { counter, form, benchmark }

final getScreen = Get.it(Screen.counter);

class App extends HookWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return switch (Ref.watch(getScreen)) {
      Screen.counter => const Counter(),
      Screen.form => const FormExampleApp(),
      Screen.benchmark => const BenchmarkApp(),
    };
  }
}

class ScreenSelect extends StatelessWidget {
  const ScreenSelect({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          for (final screen in Screen.values)
            ListTile(
              title: Text(screen.name),
              onTap: () {
                getScreen.value = screen;
                Scaffold.maybeOf(context)?.closeDrawer();
              },
            ),
        ],
      ),
    );
  }
}
