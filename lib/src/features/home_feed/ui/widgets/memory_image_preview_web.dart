import 'package:flutter/material.dart';

class MemoryImagePreview extends StatelessWidget {
  const MemoryImagePreview({
    required this.path,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Image.network(path, fit: fit),
    );
  }
}
