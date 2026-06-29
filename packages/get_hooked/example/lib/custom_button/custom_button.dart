import 'package:flutter/material.dart';
import 'package:get_hooked/get_hooked.dart';

import '../main.dart';

final _hovered = Get.vsyncValue(0.0, curve: Curves.ease);
final _elevation = Get.vsync(
  initialValue: 1.0,
  reverseDuration: Durations.short1,
  duration: Durations.short2,
);

class CustomButtonApp extends StatelessWidget {
  const CustomButtonApp({super.key});

  static ShapeDecoration _decorate(Ref ref) {
    final double hoverProgress = ref.watch(_hovered);
    final double elevation = ref.watch(_elevation);

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
  }

  static BoxSize _size(Ref ref) {
    return BoxSize(width: (ref.watch(_hovered) + 2) * 50, height: 50);
  }

  static void hover([_]) => _hovered.animateTo(1.0, duration: Durations.long1);
  static void endHover([_]) => _hovered.animateTo(0.0, duration: Durations.short2);

  static void tapDown([_]) => _elevation.reverse();
  static void tapUp([_]) => _elevation.forward();

  static Widget _label(BuildContext context) {
    final double elevation = ref.watch(_elevation);
    final double hovered = ref.watch(_hovered);
    final AnimationStatus status = ref.watch(_elevation.status);

    const suffix = 'ing';
    final int suffixLength = ((1 - elevation) * suffix.length).round();
    final bool hovering = hovered > 0.25;
    final String punctuation = switch (status) {
      AnimationStatus.dismissed => '!',
      AnimationStatus.forward || AnimationStatus.completed when hovering => '?',
      _ => '',
    };
    final String text = 'click${suffix.substring(0, suffixLength)} here$punctuation';

    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Custom button animation')),
        drawer: const ScreenSelect(),
        body: const Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: hover,
            onExit: endHover,
            child: TapRegion(
              onTapInside: tapDown,
              onTapUpInside: tapUp,
              child: RefDecoration(
                _decorate,
                child: RefSizedBox(_size, child: Center(child: RefBuilder(_label))),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
