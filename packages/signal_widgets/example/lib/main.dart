import 'package:flutter/material.dart';

import 'demos.dart';

void main() => runApp(const SignalWidgetsGallery());

class SignalWidgetsGallery extends StatelessWidget {
  const SignalWidgetsGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'signal_widgets',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const GalleryHome(),
    );
  }
}

class GalleryHome extends StatelessWidget {
  const GalleryHome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('signal_widgets gallery')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Each demo tracks signals during recompute, paint, or layout. '
            'Children stay stable while render objects update.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          const OpacityDemo(),
          const PaddingDemo(),
          const SizedBoxDemo(),
          const ConstraintsDemo(),
          const AlignDemo(),
          const AspectRatioDemo(),
          const TransformDemo(),
          const DecorationDemo(),
          const ClipDemo(),
          const PaintDemo(),
          const ShaderMaskDemo(),
          const PositionDemo(),
          const PointerDemo(),
          const LayoutDemo(),
        ],
      ),
    );
  }
}
