import 'package:example/benchmark/benchmark.dart';
import 'package:example/counter/counter.dart';
import 'package:example/custom_button/custom_button.dart';
import 'package:example/form/form.dart';
import 'package:example/ref_layout/ref_layout.dart';
import 'package:flutter/material.dart';
import 'package:get_hooked/get_hooked.dart';

void main() => runApp(const App());

enum Screen {
  counter,
  form,
  benchmark,
  button,
  refLayout;

  static final current = Get.it(counter);
}

class App extends HookWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return switch (ref.watch(Screen.current)) {
      Screen.counter => const Counter(),
      Screen.form => const FormExampleApp(),
      Screen.benchmark => const BenchmarkApp(),
      Screen.button => const CustomButtonApp(),
      Screen.refLayout => const RefLayoutApp(),
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
                Screen.current.value = screen;
                Scaffold.maybeOf(context)?.closeDrawer();
              },
            ),
        ],
      ),
    );
  }
}
