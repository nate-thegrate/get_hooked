import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get_hooked/get_hooked.dart';

import '../main.dart';

enum Setup {
  animatedContainer,
  coloredBoxBuilder,
  refWatchBuilder,
  refWatchClass,
  customPaint,
  refPaint,
  refPaintClass,
  renderGet,
  renderGetClass,
  renderScopedGet,
  renderScopedGetClass,
  customRenderObject,
}

final getSetup = Get.it(Setup.coloredBoxBuilder);

const int rows = 60;
const int columns = 50;

const duration = Duration(milliseconds: 500);
final getHue = Get.it(0.0);
final getColor = Get.vsyncValue(const Color(0xffff0000), duration: duration);
void adjustHue([_]) {
  getHue.emit((getHue.value + 30) % 360);
  if (getSetup.value != Setup.animatedContainer) {
    getColor.value = HSVColor.fromAHSV(1, getHue.value, 1, 1).toColor();
  }
}

const scaffoldKey = GlobalObjectKey<ScaffoldState>('scaffold');

const Widget child = SizedBox.expand();

class BenchmarkApp extends StatefulWidget {
  const BenchmarkApp({super.key});

  @override
  State<BenchmarkApp> createState() => _BenchmarkAppState();
}

class _BenchmarkAppState extends State<BenchmarkApp> {
  late final Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(duration, adjustHue);
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: true,
      home: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.only(top: 170),
          child: Scaffold(
            drawer: ScreenSelect(),
            key: scaffoldKey,
            backgroundColor: Colors.white,
            body: ColorSlice(),
          ),
        ),
      ),
    );
  }
}

class ColorSlice extends HookWidget {
  const ColorSlice({super.key});

  static void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final funBox = Expanded(
      flex: 3,
      child: switch (ref.watch(getSetup)) {
        Setup.animatedContainer => ValueListenableBuilder(
          valueListenable: getHue.hooked,
          builder: (context, hue, child) {
            return AnimatedContainer(
              duration: duration,
              color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
            );
          },
        ),
        Setup.coloredBoxBuilder => ValueListenableBuilder(
          valueListenable: getColor.hooked,
          builder: (context, color, _) {
            return ColoredBox(color: color, child: child);
          },
        ),
        Setup.refWatchBuilder => HookBuilder(
          builder: (context) {
            final Color color = ref.watch(getColor);
            return ColoredBox(color: color, child: child);
          },
        ),
        Setup.refWatchClass => const RefWatchClass(),
        Setup.customPaint => CustomPaint(painter: CustomPainterClass(), child: child),
        Setup.refPaint => RefPaint((PaintRef ref) {
          ref
            ..setWillChangeHint()
            ..canvas.drawRect(Offset.zero & ref.size, Paint()..color = ref.watch(getColor));
        }),
        Setup.refPaintClass => const RefPaintClass(),
        Setup.renderGet => RenderGet(
          get: getColor,
          render: (context) => RenderColoredBox(color: getColor.value),
          listen: (renderObject) => renderObject.color = getColor.value,
          child: child,
        ),
        Setup.renderGetClass => const RenderGetClass(),
        Setup.renderScopedGet => RenderGet.scoped(
          get: getColor,
          render: (context, value) => RenderColoredBox(color: value),
          listen: (render, value) => render.color = value,
          child: child,
        ),
        Setup.renderScopedGetClass => const RenderScopedGetClass(),
        Setup.customRenderObject => const CustomRenderObject(),
      },
    );

    return Column(
      children: [
        const Spacer(),
        for (int i = 0; i < rows; i++) ...[
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Spacer(),
                for (int i = 0; i < columns; i++) ...[funBox, const Spacer()],
              ],
            ),
          ),
          const Spacer(),
        ],
        const SizedBox(
          height: 64,
          child: Row(
            children: [
              IconButton(onPressed: openDrawer, icon: Icon(Icons.menu)),
              Expanded(child: Center(child: BenchmarkDropdown())),
            ],
          ),
        ),
      ],
    );
  }
}

class RefWatchClass extends HookWidget {
  const RefWatchClass({super.key});

  @override
  Widget build(BuildContext context) {
    final Color color = ref.watch(getColor);
    return ColoredBox(color: color, child: child);
  }
}

class BenchmarkDropdown extends HookWidget {
  const BenchmarkDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      value: ref.watch(getSetup),
      items: useMemoized(
        () => [
          for (final value in Setup.values)
            DropdownMenuItem(value: value, child: Text(value.name)),
        ],
      ),
      onChanged: getSetup.emit,
    );
  }
}

class RefPaintClass extends RefPaint {
  const RefPaintClass({super.key}) : super.constructor();

  @override
  void paint(PaintRef ref) {
    ref
      ..setWillChangeHint()
      ..canvas.drawRect(Offset.zero & ref.size, Paint()..color = ref.watch(getColor));
  }
}

class CustomPainterClass extends CustomPainter {
  CustomPainterClass() : super(repaint: getColor.hooked);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = getColor.value);
  }

  /// Designed to use a single delegate.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => throw Error();
}

class RenderGetClass extends RenderGetBase {
  const RenderGetClass({super.key}) : super(child: child);

  @override
  GetVsyncValue<Color> get get => getColor;

  @override
  void listen(RenderColoredBox renderObject) => renderObject.color = get.value;

  @override
  RenderColoredBox render(BuildContext context) {
    return RenderColoredBox(color: get.value);
  }
}

class RenderScopedGetClass extends RenderScopedGetBase<Color> {
  const RenderScopedGetClass({super.key}) : super(child: child);

  @override
  GetVsyncValue<Color> get get => getColor;

  @override
  void listen(RenderColoredBox renderObject, Color value) {
    renderObject.color = value;
  }

  @override
  RenderColoredBox render(BuildContext context, Color value) {
    return RenderColoredBox(color: value);
  }
}

class BottomButton extends HookWidget {
  const BottomButton(this.setup, {super.key});

  final Setup setup;

  @override
  Widget build(BuildContext context) {
    final Setup value = ref.watch(getSetup);
    return Expanded(
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(),
          backgroundColor: value == setup ? Colors.cyanAccent : Colors.blueGrey,
          foregroundColor: value == setup ? Colors.black : Colors.white,
        ),
        onPressed: () {
          getSetup.value = setup;
        },
        child: Center(child: Text(setup.name)),
      ),
    );
  }
}

class CustomRenderObject extends SingleChildRenderObjectWidget {
  const CustomRenderObject({super.key}) : super(child: child);

  @override
  RenderBox createRenderObject(BuildContext context) => _RenderAnimatedColoredBox();
}

class _RenderAnimatedColoredBox extends RenderProxyBoxWithHitTestBehavior {
  _RenderAnimatedColoredBox() : super(behavior: HitTestBehavior.opaque) {
    getColor.hooked.addListener(markNeedsPaint);
  }

  @override
  void dispose() {
    getColor.hooked.removeListener(markNeedsPaint);
    super.dispose();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context
      ..canvas.drawRect(offset & size, Paint()..color = getColor.value)
      ..setWillChangeHint();
  }
}

/// This one is just copy-pasted from the Flutter framework.
class RenderColoredBox extends RenderProxyBoxWithHitTestBehavior {
  RenderColoredBox({required Color color})
    : _color = color,
      super(behavior: HitTestBehavior.opaque);

  /// The fill color for this render object.
  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (value == _color) {
      return;
    }
    _color = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // It's tempting to want to optimize out this `drawRect()` call if the
    // color is transparent (alpha==0), but doing so would be incorrect. See
    // https://github.com/flutter/flutter/pull/72526#issuecomment-749185938 for
    // a good description of why.
    if (size > Size.zero) {
      context.canvas.drawRect(offset & size, Paint()..color = color);
    }
    if (this.child != null) {
      context.paintChild(this.child!, offset);
    }
  }
}
