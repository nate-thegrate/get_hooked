## 0.3.0
- Decided that `RenderHookElement` is too convoluted!
  - API has been reworked into `RefPaint`
- A bunch of benchmarking!
- `RenderGet`, a super-performant render object widget


## 0.2.2
- Small optimization for `RenderHookElement`: no longer performs a redundant
  equality check for `Ref.watch()` calls
  - The `_ValueListenableHook` class has been factored out, for the same reason.


## 0.2.1
- Lots of documentation added!
- Introduced a `ScopedGet` API, for objects that should only be accessed via scoping.
- Tweaked `RenderHookElement` to properly respond to Hot Reload.
- Fixed a pinned dependency since pub.dev was mad :(


## 0.2.0
- `RenderHookElement`
  - A new Hook class that allows re-rendering widgets while skipping the build phase entirely!
  - 2 widgets implemented so far:
    - `HookDecoration`, similar to DecoratedBox but can render with a `Clip` behavior
    - `HookPaint`, a variation of CustomPaint that doesn't require an additional class declaration
- Fixed various bugs I'd previously introduced…\
  now I just need to add a bunch of missing documentation :)


## 0.1.0
- Scoping!
  - It bothered me to just not have this feature :)
  - Plus, now the `Ref` class is actually more than just a namespace!
- In-house hooks!
  - New API needs 1 class declaration instead of 2
  - No need for list equality, thanks to [`Record`](https://dart.dev/language/records) types!
- Proxies!
  - Multiple values can be combined into a single Get object…
  - ***and*** multiple values can be combined using a `Ref.select()` hook.
- Almost certainly introduced one or more bugs, plus there are many Hooks that I have yet to add :)


## 0.0.2
- Grinding out those pub points!
  - Fix a syntax error (`AnimationController.repeat` doesn't have a `count` param in stable yet)
  - Make pubspec description >= 60 chars
  - The fancy images weren't showing up… not sure if it's a security thing
    or if it was the syntax I used, but regardless I decided to split the README into
    a "GitHub-optimized version" and a "pub.dev version"
    

## 0.0.1

- Initial release!
- Introduce several cool new APIs:
  - `Get`
  - `Use`
  - `Vsync`
  - `AsyncNotifier`
  - `ProxyNotifier`
  - `ValueAnimation`
- …and other new APIs which aren't quite as cool.