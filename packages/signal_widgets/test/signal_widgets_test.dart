import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_widgets/signal_widgets.dart';

void main() {
  testWidgets('SignalOpacity applies signal value and updates without rebuild', (
    tester,
  ) async {
    final opac = signal(0.5);
    var childBuilds = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SignalOpacity(
          (_) => opac.value,
          child: Builder(
            builder: (context) {
              childBuilds++;
              return const SizedBox(width: 10, height: 10);
            },
          ),
        ),
      ),
    );

    final renderOpacity = tester.renderObject<RenderOpacity>(
      find.byType(SignalOpacity),
    );
    expect(renderOpacity.opacity, 0.5);
    expect(childBuilds, 1);

    opac.value = 0.25;
    await tester.pump();

    expect(renderOpacity.opacity, 0.25);
    expect(childBuilds, 1);
  });

  testWidgets('SignalPadding applies signal padding without rebuild', (tester) async {
    final pad = signal(8.0);
    var childBuilds = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: SignalPadding(
              (_) => EdgeInsets.all(pad.value),
              child: Builder(
                builder: (context) {
                  childBuilds++;
                  return const ColoredBox(color: Colors.blue);
                },
              ),
            ),
          ),
        ),
      ),
    );

    final childBox = tester.renderObject<RenderBox>(
      find.descendant(of: find.byType(SignalPadding), matching: find.byType(ColoredBox)),
    );
    expect(childBox.size, const Size(84, 84));
    expect(childBuilds, 1);

    pad.value = 20.0;
    await tester.pump();
    expect(childBox.size, const Size(60, 60));
    expect(childBuilds, 1);
  });

  testWidgets('SignalSizedBox sizes from signal', (tester) async {
    final dim = signal(50.0);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SignalSizedBox(
            (_) => BoxSize.square(dim.value),
            child: const ColoredBox(color: Colors.red),
          ),
        ),
      ),
    );

    final box = tester.renderObject<RenderBox>(find.byType(SignalSizedBox));
    expect(box.size, const Size(50, 50));

    dim.value = 80.0;
    await tester.pump();
    expect(box.size, const Size(80, 80));
  });

  testWidgets('SignalPosition.rect updates stack child from signal', (tester) async {
    final left = signal(10.0);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            SignalPosition.rect(
              (_) => Rect.fromLTWH(left.value, 0, 20, 20),
              child: const SizedBox(width: 20, height: 20),
            ),
          ],
        ),
      ),
    );

    final parentData = tester.renderObject(find.byType(SizedBox)).parentData! as StackParentData;
    expect(parentData.left, 10.0);

    left.value = 40.0;
    await tester.pump();
    expect(parentData.left, 40.0);
  });

  testWidgets('SignalPaint subscribes to signals and repaints without rebuild', (tester) async {
    final color = signal(const Color(0xFF00FF00));
    var paintCount = 0;
    var childBuilds = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: SignalPaint(
              (context, canvas, size) {
                canvas.drawRect(Offset.zero & size, Paint()..color = color.value);
                paintCount++;
              },
              child: Builder(
                builder: (context) {
                  childBuilds++;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(paintCount, greaterThan(0));
    expect(childBuilds, 1);

    final before = paintCount;
    color.value = const Color(0xFFFF0000);
    await tester.pump();
    expect(paintCount, greaterThan(before));
    expect(childBuilds, 1);
  });
}
