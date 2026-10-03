import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'production_period_provider.dart';

final productionProgressProvider =
    Provider.family<ProductionProgress?, DateTime>((ref, month) => ref
        .watch(productionPeriodProvider(
            (date: month, period: ProductionPeriod.month)))
        .firstOrNull
        ?.progress);
