# signal_widgets

High-performance Flutter widgets powered by [signals](https://pub.dev/packages/signals_flutter).

Signal-backed counterparts to layout and painting primitives: update render objects when
signals change without rebuilding the child widget tree.

```dart
final opacity = signal(1.0);

SignalOpacity(
  (_) => opacity.value,
  child: const FlutterLogo(),
);
```

See the `example/` gallery for demos of every widget.
