import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get_hooked/get_hooked.dart';

import '../main.dart';

class CustomButtonApp extends MaterialApp {
  const CustomButtonApp({super.key})
    : super(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          appBar: AppBarConst(title: Text('Custom Button: zero rebuilds')),
          drawer: ScreenSelect(),
          body: Center(child: GetButton.widget),
        ),
      );
}

abstract final class GetButton {
  static final hovered = Get.vsyncValue(0.0, curve: Curves.ease);
  static final elevation = Get.vsync(
    initialValue: 1.0,
    reverseDuration: Durations.short1,
    duration: Durations.short2,
  );
  static final text = Get.compute((ref) {
    const suffix = 'ing';
    final int suffixLength = ((1 - ref.watch(elevation)) * suffix.length).round();
    final bool hovering = ref.watch(hovered) > 0.25;
    final String punctuation = switch (elevation.status) {
      AnimationStatus.dismissed => '!',
      AnimationStatus.forward || AnimationStatus.completed when hovering => '?',
      _ => '',
    };
    return 'click${suffix.substring(0, suffixLength)} here$punctuation';
  });
  static final decoration = Get.compute((ref) {
    final double hoverProgress = ref.watch(hovered);
    final double elevation = ref.watch(GetButton.elevation);

    final Color? vibrant = Color.lerp(
      const Color(0xff0070ff),
      const Color(0xff8000ff),
      hoverProgress,
    );

    return ShapeDecoration(
      shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(hoverProgress * 32)),
      color: Color.lerp(Colors.black, vibrant, elevation),
      shadows: [
        BoxShadow(
          blurRadius: 2 * elevation,
          offset: Offset(0, elevation * 2),
          color: Colors.black87,
        ),
      ],
    );
  });

  static void hover([_]) => hovered.animateTo(1.0, duration: Durations.long1);
  static void endHover([_]) => hovered.animateTo(0.0, duration: Durations.short2);

  static void tapDown([_]) => elevation.reverse();
  static void tapUp([_]) => elevation.forward();

  static const widget = MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: hover,
    onExit: endHover,
    child: TapRegion(
      onTapInside: tapDown,
      onTapUpInside: tapUp,
      child: _DecoratedBox(child: _SizedBox(child: Center(child: _Text()))),
    ),
  );
}

class _Text extends StatelessWidget {
  const _Text();

  @override
  Widget build(BuildContext context) {
    return TextGetter(
      GetButton.text,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}

class _DecoratedBox extends RenderGetBase {
  const _DecoratedBox({super.child});

  @override
  GetT<Decoration> get get => GetButton.decoration;

  @override
  RenderClippedDecoration render(BuildContext context) {
    return RenderClippedDecoration(decoration: get.value, clipBehavior: Clip.antiAlias);
  }

  @override
  void listen(RenderClippedDecoration renderObject) {
    renderObject.decoration = get.value;
  }
}

class _SizedBox extends RenderGetBase {
  const _SizedBox({super.child});

  @override
  GetT<double> get get => GetButton.hovered;

  BoxConstraints get constriants {
    return BoxConstraints.tight(Size((get.value + 2) * 50, 50));
  }

  @override
  void listen(RenderConstrainedBox renderObject) {
    renderObject.additionalConstraints = constriants;
  }

  @override
  RenderConstrainedBox render(BuildContext context) {
    return RenderConstrainedBox(additionalConstraints: constriants);
  }
}

Widget _counterText(BuildContext context) {
  throw Error();
}

class BeautifulButton extends MaterialApp {
  const BeautifulButton({super.key})
    : super(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          appBar: AppBarConst(title: Text('"Get Hooked" Demo')),
          drawer: ScreenSelect(),
          body: Center(child: Builder(builder: _counterText)),
        ),
      );
}
