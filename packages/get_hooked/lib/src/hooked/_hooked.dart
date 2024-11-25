import 'package:meta/meta.dart';

import 'builder.dart';
import 'renderer.dart';

@internal
abstract final class Hooked {
  static HookElement? builder;
  static RenderHookElement? renderer;
}
