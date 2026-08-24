import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'app_back_button.dart';
import 'header_metrics.dart';

class MainPageHeader extends StatelessWidget {
  const MainPageHeader({
    required this.title,
    this.backLocation,
    this.trailing,
    super.key,
  });

  final String title;
  final String? backLocation;

  /// Sits in the trailing slot, flush with the edge of the page.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          headerEdgeInset,
          4,
          headerEdgeInset,
          4,
        ),
        child: Row(
          children: [
            // A centred title needs the same width claimed on either side of
            // it, whether or not there is a back button to put there.
            SizedBox(
              width: notebookHeaderSlot,
              child: backLocation == null
                  ? null
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(fallbackLocation: backLocation!),
                    ),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            SizedBox(
              width: notebookHeaderSlot,
              child: trailing == null
                  ? null
                  : Align(alignment: Alignment.centerRight, child: trailing),
            ),
          ],
        ),
      ),
    );
  }
}
