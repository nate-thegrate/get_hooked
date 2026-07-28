import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_widgets/signal_widgets.dart';

/// A simple [SignalLayout] that splits its area into top and bottom halves.
class _SplitLayout extends SignalLayout {
  const _SplitLayout({required this.topChild, required this.bottomChild});

  final Widget topChild;
  final Widget bottomChild;

  @override
  SignalLayoutState<_SplitLayout> createState() => _SplitLayoutState();
}

class _SplitLayoutState extends SignalLayoutState<_SplitLayout> {
  late final top = delegate((w) => w.topChild);
  late final bottom = delegate((w) => w.bottomChild);

  @override
  void performLayout(BuildContext context) {
    top.layoutFractionalRect(const Rect.fromLTWH(0, 0, 1, 0.5));
    bottom.layoutFractionalRect(const Rect.fromLTWH(0, 0.5, 1, 0.5));
  }
}

/// A [SignalLayout] that uses the `layout()` + offset APIs.
class _ManualLayout extends SignalLayout {
  const _ManualLayout({required this.child});

  final Widget child;

  @override
  SignalLayoutState<_ManualLayout> createState() => _ManualLayoutState();
}

class _ManualLayoutState extends SignalLayoutState<_ManualLayout> {
  late final content = delegate((w) => w.child);

  @override
  void performLayout(BuildContext context) {
    final Size childSize = content.layout();
    size = childSize;
    content.offset = Offset.zero;
  }
}

/// A [SignalLayout] whose split ratio is driven by a signal.
class _SignalSplitLayout extends SignalLayout {
  const _SignalSplitLayout({required this.topFraction, required this.topChild, required this.bottomChild});

  final ReadonlySignal<double> topFraction;
  final Widget topChild;
  final Widget bottomChild;

  @override
  SignalLayoutState<_SignalSplitLayout> createState() => _SignalSplitLayoutState();
}

class _SignalSplitLayoutState extends SignalLayoutState<_SignalSplitLayout> {
  late final top = delegate((w) => w.topChild);
  late final bottom = delegate((w) => w.bottomChild);

  @override
  void performLayout(BuildContext context) {
    final double fraction = widget.topFraction.value;
    top.layoutFractionalRect(Rect.fromLTWH(0, 0, 1, fraction));
    bottom.layoutFractionalRect(Rect.fromLTWH(0, fraction, 1, 1 - fraction));
  }
}

void main() {
  group('SignalLayout', () {
    testWidgets('lays out children in the correct positions', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 600,
              child: _SplitLayout(topChild: SizedBox.expand(), bottomChild: SizedBox.expand()),
            ),
          ),
        ),
      );

      final RenderBox renderObject = tester.renderObject<RenderBox>(find.byType(_SplitLayout));
      expect(renderObject.size, const Size(400, 600));

      final children = <RenderBox>[];
      renderObject.visitChildren((child) => children.add(child as RenderBox));
      expect(children.length, 2);

      final topParentData = children[0].parentData! as BoxParentData;
      expect(topParentData.offset, Offset.zero);
      expect(children[0].size, const Size(400, 300));

      final bottomParentData = children[1].parentData! as BoxParentData;
      expect(bottomParentData.offset, const Offset(0, 300));
      expect(children[1].size, const Size(400, 300));
    });

    testWidgets('delegates are initialized without overriding initState', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox.square(
              dimension: 200,
              child: _SplitLayout(topChild: SizedBox.expand(), bottomChild: SizedBox.expand()),
            ),
          ),
        ),
      );

      expect(find.byType(_SplitLayout), findsOneWidget);
    });

    testWidgets('manual layout sizes to child', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: _ManualLayout(child: SizedBox(width: 100, height: 50))),
        ),
      );

      final RenderBox renderObject = tester.renderObject<RenderBox>(find.byType(_ManualLayout));
      expect(renderObject.size, const Size(100, 50));
    });

    testWidgets('relayouts when a signal read during performLayout changes', (tester) async {
      final topFraction = signal(0.25);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: _SignalSplitLayout(
                topFraction: topFraction,
                topChild: const SizedBox.expand(),
                bottomChild: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      final RenderBox renderObject = tester.renderObject<RenderBox>(
        find.byType(_SignalSplitLayout),
      );
      final children = <RenderBox>[];
      renderObject.visitChildren((child) => children.add(child as RenderBox));

      expect(children[0].size, const Size(400, 100));
      expect(children[1].size, const Size(400, 300));
      expect((children[1].parentData! as BoxParentData).offset, const Offset(0, 100));

      topFraction.value = 0.75;
      await tester.pump();

      expect(children[0].size, const Size(400, 300));
      expect(children[1].size, const Size(400, 100));
      expect((children[1].parentData! as BoxParentData).offset, const Offset(0, 300));
    });
  });
}
