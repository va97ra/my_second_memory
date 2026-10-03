class ProductionProgress {
  const ProductionProgress(this.elapsed, this.total);
  final int elapsed;
  final int total;
  int get remaining => total - elapsed;
}

/// Counts planned days. A null classification means the month is unknown.
ProductionProgress? workdayProgress(DateTime month,
        {required DateTime today,
        required bool? Function(DateTime) isWorkingDay,
        bool includeToday = false}) =>
    workdayRangeProgress(DateTime.utc(month.year, month.month),
        DateTime.utc(month.year, month.month + 1),
        today: today, isWorkingDay: isWorkingDay, includeToday: includeToday);

ProductionProgress? workdayRangeProgress(DateTime start, DateTime end,
    {required DateTime today,
    required bool? Function(DateTime) isWorkingDay,
    bool includeToday = false}) {
  final cutoff =
      DateTime.utc(today.year, today.month, today.day + (includeToday ? 1 : 0));
  var elapsed = 0;
  var total = 0;
  final limit = DateTime.utc(end.year, end.month, end.day);
  for (var date = DateTime.utc(start.year, start.month, start.day);
      date.isBefore(limit);
      date = date.add(const Duration(days: 1))) {
    final working = isWorkingDay(date);
    if (working == null) return null;
    if (working) {
      total++;
      if (date.isBefore(cutoff)) elapsed++;
    }
  }
  return ProductionProgress(elapsed, total);
}
