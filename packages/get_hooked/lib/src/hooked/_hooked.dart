import 'builder.dart';
import 'renderer.dart';

abstract final class Hooked {
  static HookElement? builder;
  static RenderHookElement? renderer;
}
