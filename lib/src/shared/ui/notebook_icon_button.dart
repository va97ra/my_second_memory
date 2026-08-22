import 'package:flutter/material.dart';

/// Side of every icon button that sits on the paper.
///
/// The feed header and the card action rail share it so a screenful of
/// buttons reads as one set of keys rather than an assortment of sizes.
const double notebookIconButtonSize = 34;

/// [IconButton.styleFrom] pinned to [notebookIconButtonSize].
///
/// The notebook theme still supplies the paper fill, the border and the
/// raised edge; this only fixes the box.
///
/// [shrinkTapTarget] drops the invisible padding Material adds to reach a
/// 48 px touch target. Use it only where the surrounding layout cannot spare
/// the room, as the card action rail cannot.
ButtonStyle notebookIconButtonStyle({
  Color? foregroundColor,
  bool shrinkTapTarget = false,
}) {
  return IconButton.styleFrom(
    foregroundColor: foregroundColor,
    minimumSize: const Size(notebookIconButtonSize, notebookIconButtonSize),
    maximumSize: const Size(notebookIconButtonSize, notebookIconButtonSize),
    padding: EdgeInsets.zero,
    tapTargetSize: shrinkTapTarget
        ? MaterialTapTargetSize.shrinkWrap
        : MaterialTapTargetSize.padded,
  );
}
