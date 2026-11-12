import 'package:flutter/material.dart';

/// Буква размера: маленькая и большая рядом.
class SizeGlyph extends StatelessWidget {
  const SizeGlyph({super.key});

  @override
  Widget build(BuildContext context) => const Text.rich(
        TextSpan(children: [
          TextSpan(text: 'а', style: TextStyle(fontSize: 13)),
          TextSpan(
            text: 'А',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
        ]),
      );
}
