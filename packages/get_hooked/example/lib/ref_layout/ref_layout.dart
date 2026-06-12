import 'package:flutter/material.dart';
import 'package:get_hooked/get_hooked.dart';

import '../main.dart';

class RefLayoutApp extends StatelessWidget {
  const RefLayoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBarConst(title: Text('RefLayout Example')),
        drawer: ScreenSelect(),
        body: RefLayoutExample(
          topChild: Padding(
            padding: .all(64),
            child: ClippedDecoration(
              decoration: BoxDecoration(
                color: Colors.green,
                image: DecorationImage(
                  image: NetworkImage(
                    'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(Radius.circular(32)),
                boxShadow: [BoxShadow(blurRadius: 16)],
              ),
              clipBehavior: Clip.antiAlias,
              child: ColoredBox(
                color: Colors.transparent,
                // color: Color(0xffffffff),
                child: Center(child: Text('hello')),
              ),
            ),
          ),
          bottomChild: ColoredBox(color: Colors.orange, child: SizedBox.expand()),
        ),
      ),
    );
  }
}

class TextBox extends StatelessWidget {
  const TextBox(this.text, {super.key, required this.color});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(child: Text(text, style: Theme.of(context).textTheme.displayMedium)),
    );
  }
}

class RefLayoutExample extends RefLayout {
  const RefLayoutExample({super.key, required this.topChild, required this.bottomChild});

  final Widget topChild;
  final Widget bottomChild;

  @override
  RefLayoutState<RefLayoutExample> createState() => _RefLayoutExampleState();
}

class _RefLayoutExampleState extends RefLayoutState<RefLayoutExample> {
  late final topChild = delegate((widget) => widget.topChild);
  late final bottomChild = delegate((widget) => widget.bottomChild);

  @override
  void performLayout(LayoutRef ref) {
    topChild.layoutFractionalRect(const Rect.fromLTWH(0, 0, 1, 0.5));
    bottomChild.layoutFractionalRect(const Rect.fromLTWH(0, 0.5, 1, 0.5));
  }
}
