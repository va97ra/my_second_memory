import 'package:flutter/material.dart';

import 'main_page_header.dart';

/// Шапка главной страницы внутри прокрутки.
class MainSliverAppBar extends StatelessWidget {
  const MainSliverAppBar({
    required this.title,
    this.backLocation,
    this.trailing,
    super.key,
  });

  final String title;
  final String? backLocation;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: MainPageHeader(
        title: title,
        backLocation: backLocation,
        trailing: trailing,
      ),
    );
  }
}
