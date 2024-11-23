// ignore_for_file: constant_identifier_names, to match pub.dev

import 'package:example/faceoff/get_hooked.dart';
import 'package:example/faceoff/native.dart';
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:get_hooked/get_hooked.dart';

enum Package { native, get_hooked }

final getPackage = Get.it(Package.native);

enum WorkType {
  /// Task: generate a long list of random [bool] values that re-randomizes each frame.
  ///
  /// The widget should compute total number of `true` values
  /// (and [print] to verify that it works, but prints will be commented out during the benchmark).
  rebuilding,

  /// Task: Display a bunch of nested translucent colored widgets
  /// and change their color each frame.
  rerendering,
}

final getWorkType = Get.it(WorkType.rebuilding);

final getTaskCount = Get.it(10);

class Faceoff extends StatelessWidget {
  const Faceoff({super.key});

  static Widget _builder(BuildContext context) {
    return switch (Ref.watch(getPackage)) {
      Package.native => const NativeFaceoff(),
      Package.get_hooked => const GetHookedFaceoff(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ColoredBox(
        color: Color(0xFFE0E0FF),
        child: Padding(
          padding: EdgeInsets.only(top: 170),
          child: Scaffold(
            appBar: FaceoffAppBar(),
            drawer: ScreenSelect(),
            body: HookBuilder(builder: _builder),
          ),
        ),
      ),
    );
  }
}

class FaceoffAppBar extends HookWidget implements PreferredSizeWidget {
  const FaceoffAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Performance faceoff: ${Ref.watch(getPackage).name}'),
    );
  }
}
