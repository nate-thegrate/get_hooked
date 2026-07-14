import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_hooked/get_hooked.dart';

/// A simple [RefLayout] that splits its area into top and bottom halves.
class _SplitLayout extends RefLayout {
  const _SplitLayout({required this.topChild, required this.bottomChild});

  final Widget topChild;
  final Widget bottomChild;

  @override
  RefLayoutState<_SplitLayout> createState() => _SplitLayoutState();
}

class _SplitLayoutState extends RefLayoutState<_SplitLayout> {
  late final top = delegate((w) => w.topChild);
  late final bottom = delegate((w) => w.bottomChild);

  @override
  void performLayout(LayoutRef ref) {
    top.layoutFractionalRect(const Rect.fromLTWH(0, 0, 1, 0.5));
    bottom.layoutFractionalRect(const Rect.fromLTWH(0, 0.5, 1, 0.5));
  }
}

/// A [RefLayout] that uses the `layout()` + `positionAt()` APIs.
class _ManualLayout extends RefLayout {
  const _ManualLayout({required this.child});

  final Widget child;

  @override
  RefLayoutState<_ManualLayout> createState() => _ManualLayoutState();
}

class _ManualLayoutState extends RefLayoutState<_ManualLayout> {
  late final content = delegate((w) => w.child);

  @override
  void performLayout(LayoutRef ref) {
    final Size childSize = content.layout();
    ref.size = childSize;
    content.offset = .zero;
  }
}

void main() {
  group('RefLayout', () {
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

      // Find the RenderRefLayout.
      final RenderBox renderObject = tester.renderObject<RenderBox>(find.byType(_SplitLayout));
      expect(renderObject.size, const Size(400, 600));

      // Verify children render boxes are correctly positioned.
      final children = <RenderBox>[];
      renderObject.visitChildren((child) => children.add(child as RenderBox));
      expect(children.length, 2);

      // Top child: offset (0,0), size 400x300.
      final topParentData = children[0].parentData! as BoxParentData;
      expect(topParentData.offset, Offset.zero);
      expect(children[0].size, const Size(400, 300));

      // Bottom child: offset (0,300), size 400x300.
      final bottomParentData = children[1].parentData! as BoxParentData;
      expect(bottomParentData.offset, const Offset(0, 300));
      expect(children[1].size, const Size(400, 300));
    });

    testWidgets('delegates are initialized without overriding initState', (tester) async {
      // This test verifies that the dry run during mount initializes the
      // late final delegate fields, so no initState override is needed.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: _SplitLayout(topChild: SizedBox.expand(), bottomChild: SizedBox.expand()),
            ),
          ),
        ),
      );

      // If delegates weren't initialized, the widget would have thrown
      // a LateInitializationError. Reaching this point means success.
      expect(tester.takeException(), isNull);

      final RenderBox renderObject = tester.renderObject<RenderBox>(find.byType(_SplitLayout));
      expect(renderObject.size, const Size(200, 200));
    });

    testWidgets('getDryLayout returns the correct size', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: _ManualLayout(child: SizedBox(width: 100, height: 50))),
        ),
      );

      final RenderBox renderObject = tester.renderObject<RenderBox>(find.byType(_ManualLayout));
      // The _ManualLayout sets its own size to the child's size.
      expect(renderObject.size, const Size(100, 50));

      // getDryLayout should produce the same result via dry run.
      final Size drySize = renderObject.getDryLayout(
        const BoxConstraints(maxWidth: 400, maxHeight: 600),
      );
      expect(drySize, const Size(100, 50));
    });

    testWidgets('updates correctly when widget configuration changes', (tester) async {
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

      // Change the parent size.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 300,
              height: 400,
              child: _SplitLayout(topChild: SizedBox.expand(), bottomChild: SizedBox.expand()),
            ),
          ),
        ),
      );

      expect(renderObject.size, const Size(300, 400));

      final children = <RenderBox>[];
      renderObject.visitChildren((child) => children.add(child as RenderBox));

      // Top child: 300x200
      expect(children[0].size, const Size(300, 200));
      // Bottom child: 300x200
      final bottomData = children[1].parentData! as BoxParentData;
      expect(bottomData.offset, const Offset(0, 200));
      expect(children[1].size, const Size(300, 200));
    });

    testWidgets('paints without errors', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: _SplitLayout(
                topChild: ColoredBox(color: Color(0xFFFF0000)),
                bottomChild: ColoredBox(color: Color(0xFF0000FF)),
              ),
            ),
          ),
        ),
      );

      // No exceptions during paint.
      expect(tester.takeException(), isNull);
    });

    testWidgets('gesture localPosition accounts for layout paint offsets', (tester) async {
      // Regression: hit-testing children with a manual position shift (without
      // [BoxHitTestResult.addWithPaintOffset]) left the hit-test transform stack
      // missing the paint offset, so PointerEvent.localPosition was wrong for
      // descendants of padded RefLayouts.
      Offset? localPosition;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: _PaddingLayout(
                padding: const EdgeInsets.all(50),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (details) => localPosition = details.localPosition,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );

      // Global center of the padded child content is (200, 200) in the 400x400
      // host; the child's top-left is at (50, 50), so local should be (150, 150).
      await tester.tapAt(tester.getCenter(find.byType(_PaddingLayout)));
      expect(localPosition, const Offset(150, 150));
    });
  });
}

/// A [RefLayout] that insets its child, similar to PaperPadding in tic_tac_go.
class _PaddingLayout extends RefLayout {
  const _PaddingLayout({required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  RefLayoutState<_PaddingLayout> createState() => _PaddingLayoutState();
}

class _PaddingLayoutState extends RefLayoutState<_PaddingLayout> {
  late final content = delegate((w) => w.child);

  @override
  void performLayout(LayoutRef ref) {
    content.layoutPadding(widget.padding);
  }
}
