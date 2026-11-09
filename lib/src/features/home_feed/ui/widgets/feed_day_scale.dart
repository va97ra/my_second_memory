/// Какой день на какой высоте шкалы. День записи стоит там, где её подняли, и
/// шкала отсчитывает дни от него: выше раньше, ниже позже, как в самой ленте.
class FeedDayScale {
  FeedDayScale({
    required this.ownDay,
    required this.ownY,
    required this.cellExtent,
  });

  final DateTime ownDay;
  final double ownY;
  final double cellExtent;

  /// На сколько точек шкала уехала, пока палец держали у её края.
  double shift = 0;

  int indexAt(double y) => ((y - ownY + shift) / cellExtent).round();

  double centerOf(int index) => ownY + index * cellExtent - shift;

  DateTime dayOf(int index) =>
      DateTime(ownDay.year, ownDay.month, ownDay.day + index);
}
