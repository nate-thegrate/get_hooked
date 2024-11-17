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