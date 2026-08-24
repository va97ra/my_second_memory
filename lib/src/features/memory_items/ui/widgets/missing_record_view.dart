import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/screen_chrome.dart';

/// Экран записи, которой нет: её никогда не было по этому адресу.
class MissingRecordView extends StatelessWidget {
  const MissingRecordView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppPageAppBar(onBack: onBack, title: Text(strings.editRecord)),
      body: Center(child: Text(strings.recordNotFound)),
    );
  }
}
