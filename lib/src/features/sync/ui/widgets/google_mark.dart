import 'package:flutter/material.dart';

/// Метка Google на кнопке входа.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Google',
      child: Text(
        'G',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
