import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../navigation/page_turn_navigation.dart';
import '../../../../shared/ui/memory_card/sticker_paper.dart';
import '../../../../shared/ui/memory_card/sticker_strip.dart';
import '../../state/accounts_controller.dart';
import 'account_field_icons.dart';
import 'account_info_line.dart';
import 'account_password_row.dart';
import 'account_row_button.dart';
import 'account_tint.dart';
import 'account_tint_strip.dart';
import 'service_avatar.dart';

/// Карточка аккаунта на той же бумаге, что и записки: сервис и его поля.
/// Нажатие на карточку открывает её целиком, на букву — выбор цвета.
///
/// Получает идентификатор и читает аккаунт сама, из общего хранилища.
class AccountCard extends ConsumerStatefulWidget {
  const AccountCard({super.key, required this.accountId});

  /// Заголовок и пять полей, какое бы их число ни было заполнено: ряды сетки ровные.
  static const _lines = 6;
  static const _bodyInset = 3.0;

  static double heightOf(BuildContext context) =>
      StickerPaper.stripHeight +
      _bodyInset * 2 +
      AccountInfoLine.heightOf(context) * _lines;

  final String accountId;

  @override
  ConsumerState<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<AccountCard> {
  bool _picking = false;
  int? _pickedHue;

  void _togglePicker(AccountItem account) {
    setState(() {
      _picking = !_picking;
      _pickedHue = account.tintHue;
    });
  }

  Future<void> _savePicked(AccountItem account) async {
    final hue = _pickedHue;
    setState(() => _picking = false);
    if (hue == account.tintHue) return;
    await ref.read(accountsControllerProvider.notifier).update(
          hue == null
              ? account.copyWith(clearTintHue: true)
              : account.copyWith(tintHue: hue),
        );
  }

  Future<void> _open(AccountItem account) async {
    // Карточка успевает вернуться на место: переворот снимает страницу со снимка.
    await Future<void>.delayed(PressPulse.duration);
    if (!mounted) return;
    await context.pageTurnPush(
      '/accounts/item/${Uri.encodeComponent(account.id)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountByIdProvider(widget.accountId));
    if (account == null) return const SizedBox.shrink();
    final hue = _picking ? _pickedHue : account.tintHue;
    final accent = accountTintAccent(hue);

    return PressPulse(
      child: StickerPaper(
        accent: accent,
        tint: accountTintSurface(hue),
        strip: StickerStrip(
          accent: accent,
          label: AppStrings.of(context).account,
        ),
        child: NotebookPressable(
          key: ValueKey('account_card_${account.id}'),
          onTap: () => _open(account),
          borderRadius: BorderRadius.zero,
          pulse: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AccountCard._bodyInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  account: account,
                  accent: accent,
                  picker: _picking
                      ? AccountTintStrip(
                          hue: _pickedHue,
                          onChanged: (value) =>
                              setState(() => _pickedHue = value),
                          onDone: () => _savePicked(account),
                        )
                      : null,
                  onAvatarTap: () => _togglePicker(account),
                ),
                ..._lines(account),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Пустое поле не занимает строку: заполняют обычно два-три из пяти.
  List<Widget> _lines(AccountItem account) => [
        if (account.login.isNotEmpty)
          AccountInfoLine(icon: AccountFieldIcons.login, text: account.login),
        if (account.email.isNotEmpty)
          AccountInfoLine(icon: AccountFieldIcons.email, text: account.email),
        if (account.password.isNotEmpty)
          AccountPasswordRow(password: account.password),
        if (account.website.isNotEmpty)
          AccountInfoLine(
            icon: AccountFieldIcons.website,
            text: account.website,
          ),
        if (account.note.isNotEmpty)
          AccountInfoLine(icon: AccountFieldIcons.note, text: account.note),
      ];
}

/// Верх карточки: буква сервиса, рядом название или полоска выбора цвета.
class _Header extends StatelessWidget {
  const _Header({
    required this.account,
    required this.accent,
    required this.picker,
    required this.onAvatarTap,
  });

  final AccountItem account;
  final Color accent;
  final Widget? picker;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: AccountInfoLine.heightOf(context),
      child: Row(
        children: [
          Tooltip(
            message: AppStrings.of(context).accountColor,
            child: NotebookPressable(
              key: ValueKey('account_color_${account.id}'),
              onTap: onAvatarTap,
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: AccountRowButton.width,
                height: double.infinity,
                child: Center(
                  child: ServiceAvatar(
                    name: account.serviceName,
                    color: accent,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: picker ??
                Text(
                  account.serviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
