import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'subscription_term_sheet.dart';

/// Поля платежа: сумма, категория и срок подписки.
class PaymentFields extends StatelessWidget {
  const PaymentFields({super.key, 
    required this.amountController,
    required this.category,
    required this.locale,
    required this.onCategoryChanged,
    required this.onChanged,
    required this.subscriptionTermMonths,
    required this.onSubscriptionTermTap,
  });

  final TextEditingController amountController;
  final PaymentCategory category;
  final String locale;
  final ValueChanged<PaymentCategory> onCategoryChanged;
  final VoidCallback onChanged;
  final int? subscriptionTermMonths;
  final VoidCallback? onSubscriptionTermTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PaymentCategory>(
                    value: category,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    items: [
                      for (final value in PaymentCategory.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(
                            value.label(locale),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) onCategoryChanged(value);
                    },
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              SizedBox(
                width: 104,
                child: TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.end,
                  decoration: InputDecoration(
                    hintText: locale == 'ru' ? 'Сумма ₽' : 'Amount ₽',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          if (category == PaymentCategory.subscription &&
              onSubscriptionTermTap != null) ...[
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            InkWell(
              key: const ValueKey('subscription_term_picker'),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
              onTap: onSubscriptionTermTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 19,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locale == 'ru'
                              ? 'Срок подписки'
                              : 'Subscription term',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          subscriptionTermLabel(
                            subscriptionTermMonths,
                            locale,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
