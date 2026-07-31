## 0.1.1
- Remove `SignalElement` and `SignalStatefulElement` from hidden APIs
  - The intent was that developers shouldn't need to access the `Element` subtypes,
    but in practice it was causing confusion, since it was sometimes misread as hiding the entire `SignalStatefulWidget` API

## 0.1.0
- Initial release: high-performance Flutter widgets driven by `signals_flutter`
- Core: `ElementSignal`, `SingleChildSignalElement`
- Widgets: `SignalOpacity`, `SignalPadding`, `SignalSizedBox`, `SignalConstraints`,
  `SignalAlign`, `SignalAspectRatio`, `SignalTransform`, `SignalDecoration`,
  `SignalClip`, `SignalPaint`, `SignalShaderMask`, `SignalPointer`,
  `SignalPosition` / `SignalParentData`, `SignalLayout`
- Example gallery app demonstrating each widget
