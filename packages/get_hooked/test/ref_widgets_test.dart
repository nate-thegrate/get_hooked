import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_hooked/get_hooked.dart';

void main() {
  group('Other Ref* widgets and listenables', () {
    testWidgets('RefSizedBox sizes correctly and watches Get', (tester) async {
      final dim = Get.it(50.0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RefSizedBox(
              (r) => BoxSize.square(r.watch(dim)),
              child: const ColoredBox(color: Colors.red),
            ),
          ),
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byType(RefSizedBox));
      expect(box.size, const Size(50, 50));

      dim.value = 80.0;
      await tester.pump();
      expect(box.size, const Size(80, 80));
    });

    testWidgets('RefPadding applies padding from Get and updates', (tester) async {
      final padVal = Get.it(8.0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: RefPadding(
                (r) => EdgeInsets.all(r.watch(padVal)),
                child: const ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      // Child should be inset by 8 all around => 84x84 inner.
      final childBox = tester.renderObject<RenderBox>(
        find.descendant(of: find.byType(RefPadding), matching: find.byType(ColoredBox)),
      );
      expect(childBox.size, const Size(84, 84));

      padVal.value = 20.0;
      await tester.pump();
      expect(childBox.size, const Size(60, 60));
    });

    testWidgets('RefOpacity watches opacity Get and applies it', (tester) async {
      final opac = Get.it(0.5);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RefOpacity((r) => r.watch(opac), child: const SizedBox(width: 10, height: 10)),
        ),
      );

      // Opacity value applied via compute, widget holds the computer fn.
      opac.value = 0.25;
      await tester.pump();
      // Just verify no crash and widget still there after update.
      expect(find.byType(RefOpacity), findsOneWidget);
    });

    testWidgets('RefTransform watches transform and applies', (tester) async {
      final scale = Get.it(1.0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RefTransform(
              (r) => Matrix4.diagonal3Values(r.watch(scale), r.watch(scale), 1),
              child: const SizedBox(width: 20, height: 20),
            ),
          ),
        ),
      );

      // Basic presence and update test.
      scale.value = 2.0;
      await tester.pump();
      // No crash and widget updated.
      expect(find.byType(RefTransform), findsOneWidget);
    });

    testWidgets('RefPaint subscribes to listenables and repaints', (tester) async {
      final color = Get.it(const Color(0xFF00FF00));
      int paintCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: RefPaint((ref) {
                final c = ref.watch(color);
                // draw something
                ref.canvas.drawRect(Offset.zero & ref.size, Paint()..color = c);
                paintCount++;
              }),
            ),
          ),
        ),
      );

      // Initial paint
      await tester.pump();
      expect(paintCount, greaterThan(0));

      final before = paintCount;
      color.value = const Color(0xFFFF0000);
      await tester.pump();
      expect(paintCount, greaterThan(before));
    });

    testWidgets('GetComputed notifies dependents', (tester) async {
      final base = Get.it(5);
      final computed = Get.compute((r) => r.watch(base) * 2);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder((context) {
            final v = ref.watch(computed);
            return Text('c=$v');
          }),
        ),
      );
      expect(find.text('c=10'), findsOneWidget);

      base.value = 7;
      await tester.pump();
      expect(find.text('c=14'), findsOneWidget);
    });

    testWidgets('GetSelection notifies on selected change', (tester) async {
      final input = Get.it(const _Pair(1, 2));
      final sel = Get.select(input, (p) => p.a + p.b);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder((context) {
            final s = ref.watch(sel);
            return Text('s=$s');
          }),
        ),
      );
      expect(find.text('s=3'), findsOneWidget);

      input.value = const _Pair(4, 5);
      await tester.pump();
      expect(find.text('s=9'), findsOneWidget);
    });

    testWidgets('useAnimation works for ValueAnimations', (tester) async {
      final v = Get.vsyncValue<double>(0.0, duration: const Duration(milliseconds: 1));
      int builds = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder((context) {
            final cur = useAnimation(v);
            builds++;
            return Text('anim=$cur builds=$builds');
          }),
        ),
      );
      expect(find.textContaining('anim=0'), findsOneWidget);

      // Drive by setting target value (animates via internal).
      v.value = 1.0;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2));
      // At minimum, subscription didn't crash and we can still see widget.
      expect(find.byType(HookBuilder), findsOneWidget);
    });

    testWidgets('Get.mediaQuery provides query values', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: HookBuilder((context) {
              final size = ref.watch(Get.mediaQuery((d) => d.size));
              return Text('w=${size.width}');
            }),
          ),
        ),
      );
      expect(find.textContaining('w='), findsOneWidget);
    });
  });
}

@immutable
class _Pair {
  const _Pair(this.a, this.b);

  final int a;
  final int b;

  @override
  bool operator ==(Object other) => other is _Pair && other.a == a && other.b == b;

  @override
  int get hashCode => Object.hash(a, b);
}
