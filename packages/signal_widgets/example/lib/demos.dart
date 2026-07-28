import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:signal_widgets/signal_widgets.dart';

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.controls = const [],
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> controls;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(height: 180, width: double.infinity, child: child),
              ),
            ),
            if (controls.isNotEmpty) ...[const SizedBox(height: 12), ...controls],
          ],
        ),
      ),
    );
  }
}

class _SignalSlider extends StatelessWidget {
  const _SignalSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
  });

  final String label;
  final Signal<double> value;
  final double min;
  final double max;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final v = value.value;
        return Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(
                '$label\n${v.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            Expanded(
              child: Slider(
                value: v.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: (next) => value.value = next,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SampleBox extends StatelessWidget {
  const _SampleBox({this.label = 'child', this.color = Colors.indigo});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

final opacity = signal(0.85);

class OpacityDemo extends StatelessWidget {
  const OpacityDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SignalOpacity',
      subtitle: 'Updates RenderOpacity without rebuilding the child.',
      controls: [_SignalSlider(label: 'opacity', value: opacity, min: 0, max: 1)],
      child: Center(child: SignalOpacity((_) => opacity.value, child: const FlutterLogo(size: 96))),
    );
  }
}

final padding = signal(16.0);

class PaddingDemo extends StatelessWidget {
  const PaddingDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SignalPadding',
      subtitle: 'Insets the child from an EdgeInsetsGeometry computer.',
      controls: [_SignalSlider(label: 'padding', value: padding, min: 0, max: 48, divisions: 24)],
      child: Center(
        child: ColoredBox(
          color: Colors.indigo.shade100,
          child: SignalPadding(
            (_) => EdgeInsets.all(padding.value),
            child: const SizedBox.square(dimension: 80, child: _SampleBox(label: 'padded')),
          ),
        ),
      ),
    );
  }
}

final dimension = signal(120.0);

class SizedBoxDemo extends StatelessWidget {
  const SizedBoxDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SignalSizedBox',
      subtitle: 'Tight size from a BoxSize computer (square here).',
      controls: [_SignalSlider(label: 'size', value: dimension, min: 40, max: 150, divisions: 22)],
      child: Center(
        child: SignalSizedBox(
          (_) => BoxSize.square(dimension.value),
          child: const _SampleBox(label: 'sized'),
        ),
      ),
    );
  }
}

final maxWidth = signal(180.0);

class ConstraintsDemo extends StatelessWidget {
  const ConstraintsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SignalConstraints',
      subtitle: 'Additional BoxConstraints applied to the child.',
      controls: [_SignalSlider(label: 'maxW', value: maxWidth, min: 60, max: 280, divisions: 22)],
      child: Align(
        alignment: Alignment.center,
        child: SignalConstraints(
          (_) => BoxConstraints(maxWidth: maxWidth.value),
          child: const _SampleBox(label: 'max-width\nconstrained', color: Colors.teal),
        ),
      ),
    );
  }
}

final alignmentX = signal(0.0);
final alignmentY = signal(0.0);

class AlignDemo extends StatelessWidget {
  const AlignDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SignalAlign',
      subtitle: 'Positions a child with AlignmentGeometry.',
      controls: [
        _SignalSlider(label: 'x', value: alignmentX, min: -1, max: 1),
        _SignalSlider(label: 'y', value: alignmentY, min: -1, max: 1),
      ],
      child: SignalAlign(
        (_) => Alignment(alignmentX.value, alignmentY.value),
        child: const SizedBox.square(
          dimension: 56,
          child: _SampleBox(label: 'align', color: Colors.deepPurple),
        ),
      ),
    );
  }
}

final aspectRatio = signal(1.5);

class AspectRatioDemo extends StatelessWidget {
  const AspectRatioDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SignalAspectRatio',
      subtitle: 'Forces width:height ratio from a double computer.',
      controls: [_SignalSlider(label: 'ratio', value: aspectRatio, min: 0.5, max: 2.5)],
      child: Center(
        child: SizedBox(
          width: 200,
          child: Center(
            child: SignalAspectRatio(
              (_) => aspectRatio.value,
              child: const _SampleBox(label: 'aspect', color: Colors.orange),
            ),
          ),
        ),
      ),
    );
  }
}

final rotation = signal(0.0);
final scale = signal(1.0);

class TransformDemo extends StatelessWidget {
  const TransformDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SignalTransform',
      subtitle: 'Applies a Matrix4; the child widget is not rebuilt.',
      controls: [
        _SignalSlider(label: 'rotate', value: rotation, min: 0, max: math.pi * 2),
        _SignalSlider(label: 'scale', value: scale, min: 0.4, max: 1.6),
      ],
      child: Center(
        child: SignalTransform(
          (_) {
            final s = scale.value;
            return Matrix4.identity()
              ..translateByDouble(0, 0, 0, 1)
              ..rotateZ(rotation.value)
              ..scaleByDouble(s, s, 1, 1);
          },
          alignment: Alignment.center,
          child: const SizedBox.square(
            dimension: 72,
            child: _SampleBox(label: 'xform', color: Colors.pink),
          ),
        ),
      ),
    );
  }
}

final decorationHue = signal(210.0);

class DecorationDemo extends StatelessWidget {
  const DecorationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SignalDecoration',
      subtitle: 'Reactive BoxDecoration / ShapeDecoration with optional clipping.',
      controls: [
        _SignalSlider(label: 'hue', value: decorationHue, min: 0, max: 360, divisions: 36),
      ],
      child: Center(
        child: SignalDecoration(
          (_) => BoxDecoration(
            color: HSLColor.fromAHSL(1, decorationHue.value, 0.65, 0.55).toColor(),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(blurRadius: 12, offset: Offset(0, 4), color: Colors.black26),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: const SizedBox.square(
            dimension: 100,
            child: Center(
              child: Text(
                'decorated',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final clipRadius = signal(28.0);

class ClipDemo extends StatelessWidget {
  const ClipDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SignalClip.path / .shape',
      subtitle: 'Clips with a Path or ShapeBorder; size is passed into the callback.',
      controls: [_SignalSlider(label: 'radius', value: clipRadius, min: 0, max: 60, divisions: 30)],
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: SizedBox.square(
                dimension: 110,
                child: SignalClip.shape(
                  (context, size) =>
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(clipRadius.value)),
                  child: const _SampleBox(label: '.shape', color: Colors.blueGrey),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SizedBox.square(
                dimension: 110,
                child: SignalClip.path((context, size) {
                  final r = clipRadius.value.clamp(0.0, size.shortestSide / 2);
                  return Path()
                    ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r)));
                }, child: const _SampleBox(label: '.path', color: Colors.brown)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final paintHue = signal(160.0);

class PaintDemo extends StatelessWidget {
  const PaintDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SignalPaint',
      subtitle: 'Custom paint with (context, canvas, size); tracks .value during paint.',
      controls: [_SignalSlider(label: 'hue', value: paintHue, min: 0, max: 360, divisions: 36)],
      child: SignalPaint((context, canvas, size) {
        final color = HSLColor.fromAHSL(1, paintHue.value, 0.7, 0.5).toColor();
        final paint = Paint()..color = color;
        final center = size.center(Offset.zero);
        canvas.drawCircle(center, size.shortestSide * 0.35, paint);
        canvas.drawCircle(
          center,
          size.shortestSide * 0.18,
          Paint()..color = Colors.white.withValues(alpha: 0.85),
        );
        context.setWillChangeHint();
      }),
    );
  }
}

final shaderT = signal(0.35);

class ShaderMaskDemo extends StatelessWidget {
  const ShaderMaskDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SignalShaderMask',
      subtitle: 'Builds a Shader from (context, bounds); repaints on signal change.',
      controls: [_SignalSlider(label: 'stop', value: shaderT, min: 0, max: 1)],
      child: Center(
        child: SignalShaderMask(
          (context, bounds) {
            final t = shaderT.value;
            return ui.Gradient.linear(
              bounds.topLeft,
              bounds.bottomRight,
              [Colors.indigo, Colors.pinkAccent, Colors.amber],
              [0.0, t.clamp(0.05, 0.95), 1.0],
            );
          },
          blendMode: BlendMode.srcATop,
          child: const Text(
            'SHADER',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }
}

final positionLeft = signal(24.0);
final positionTop = signal(24.0);

class PositionDemo extends StatelessWidget {
  const PositionDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SignalPosition (+ SignalParentData)',
      subtitle: 'Stack parent data from a Rect computer — no rebuild to reposition.',
      controls: [
        _SignalSlider(label: 'left', value: positionLeft, min: 0, max: 200, divisions: 40),
        _SignalSlider(label: 'top', value: positionTop, min: 0, max: 120, divisions: 24),
      ],
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0x11000000))),
          SignalPosition.rect(
            (_) => Rect.fromLTWH(positionLeft.value, positionTop.value, 72, 72),
            child: const _SampleBox(label: 'pos', color: Colors.cyan),
          ),
        ],
      ),
    );
  }
}

final passThrough = signal(true);

class PointerDemo extends StatelessWidget {
  const PointerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SignalPointer',
      subtitle: 'Ignore/absorb hits from a bool computer (evaluated at hit-test time).',
      controls: [
        SignalBuilder(
          builder: (context) {
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('pass through'),
              subtitle: Text(
                passThrough.value
                    ? 'overlay ignored — button reachable'
                    : 'overlay interactable — button blocked',
              ),
              value: passThrough.value,
              onChanged: (v) => passThrough.value = v,
            );
          },
        ),
      ],
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Underlying button pressed')));
              },
              child: const Text('Press me'),
            ),
          ),
          SignalPointer(
            // Interactable when *not* passing through (overlay takes hits).
            (_) => !passThrough.value,
            absorb: false,
            child: const ColoredBox(color: Color(0x33FF0000)),
          ),
        ],
      ),
    );
  }
}

final layoutFraction = signal(0.45);

class LayoutDemo extends StatelessWidget {
  const LayoutDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SignalLayout',
      subtitle: 'Custom multi-child layout; signal reads during performLayout relayout.',
      controls: [_SignalSlider(label: 'split', value: layoutFraction, min: 0.15, max: 0.85)],
      child: _SplitSignalLayout(
        fraction: layoutFraction,
        top: const _SampleBox(label: 'top', color: Colors.green),
        bottom: const _SampleBox(label: 'bottom', color: Colors.deepOrange),
      ),
    );
  }
}

class _SplitSignalLayout extends SignalLayout {
  const _SplitSignalLayout({required this.fraction, required this.top, required this.bottom});

  final ReadonlySignal<double> fraction;
  final Widget top;
  final Widget bottom;

  @override
  SignalLayoutState<_SplitSignalLayout> createState() => _SplitSignalLayoutState();
}

class _SplitSignalLayoutState extends SignalLayoutState<_SplitSignalLayout> {
  late final top = delegate((w) => w.top);
  late final bottom = delegate((w) => w.bottom);

  @override
  void performLayout(BuildContext context) {
    final f = widget.fraction.value;
    top.layoutFractionalRect(Rect.fromLTWH(0, 0, 1, f));
    bottom.layoutFractionalRect(Rect.fromLTWH(0, f, 1, 1 - f));
  }
}
