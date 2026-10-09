import 'dart:math' as math;

import 'moscow_metro_data.dart';

/// Линия метро. [branches] — станции по порядку (у Филёвской есть ответвление).
class MetroLine {
  const MetroLine(this.id, this.number, this.name, this.color, this.argb,
      {required this.circle, required this.branches});

  final String id;
  final String number;
  final String name;

  /// Цвет словами для подсказки: «синяя».
  final String color;
  final int argb;

  /// Кольцо: за последней станцией снова первая.
  final bool circle;
  final List<List<int>> branches;
}

/// Станция одной линии (пересадочный узел — несколько станций).
class MetroStation {
  const MetroStation(this.line, this.name, this.lat, this.lng);

  final String line;
  final String name;
  final double lat;
  final double lng;

  bool get hasCoords => lat != 0 && lng != 0;
}

/// Поездка по одной линии без пересадок.
class MetroLeg {
  const MetroLeg(this.line, this.stations, this.toward);

  final MetroLine line;

  /// Станции по пути, первая — где сели, последняя — где вышли.
  final List<MetroStation> stations;

  /// «В сторону …»: конечная, а на кольце — следующая станция.
  final String toward;

  int get stops => stations.length - 1;
  MetroStation get from => stations.first;
  MetroStation get to => stations.last;
}

/// Маршрут: поездки с пересадками между ними и примерное время.
class MetroRoute {
  const MetroRoute(this.legs, this.minutes);

  final List<MetroLeg> legs;
  final int minutes;

  int get transfers => legs.length - 1;
}

class _Edge {
  const _Edge(this.to, this.minutes, {required this.ride});

  final int to;
  final double minutes;
  final bool ride;
}

/// Схема метро и поиск самого быстрого пути (Дейкстра).
/// Время — оценка: езда по расстоянию между станциями, переход — по длине перехода.
class MetroMap {
  MetroMap(this.lines, this.stations, List<(int, int, int)> transfers) {
    _edges = List.generate(stations.length, (_) => <_Edge>[]);
    for (final line in lines) {
      for (final branch in line.branches) {
        for (var i = 0; i + 1 < branch.length; i++) {
          _ride(branch[i], branch[i + 1]);
        }
        if (line.circle) _ride(branch.last, branch.first);
      }
    }
    for (final (a, b, meters) in transfers) {
      final m = transferMinutes + meters / walkPerMinute;
      _edges[a].add(_Edge(b, m, ride: false));
      _edges[b].add(_Edge(a, m, ride: false));
    }
  }

  static final moscow = MetroMap(moscowLines, moscowStations, moscowTransfers);

  /// Ждать поезд в начале.
  static const waitMinutes = 2.0;

  /// Переход: спуститься, подняться, дождаться поезда (+ сама ходьба).
  static const transferMinutes = 2.0;
  static const walkPerMinute = 70.0;

  /// При выборе пути пересадка «стоит» дороже — чтобы не гонять человека ради минуты.
  static const transferPenalty = 3.0;

  final List<MetroLine> lines;
  final List<MetroStation> stations;
  late final List<List<_Edge>> _edges;

  MetroLine lineOf(MetroStation s) => lines.firstWhere((l) => l.id == s.line);

  void _ride(int a, int b) {
    final m = _rideMinutes(stations[a], stations[b]);
    _edges[a].add(_Edge(b, m, ride: true));
    _edges[b].add(_Edge(a, m, ride: true));
  }

  /// Разгон, торможение, стоянка + в среднем 45 км/ч.
  static double _rideMinutes(MetroStation a, MetroStation b) {
    if (!a.hasCoords || !b.hasCoords) return 2.5;
    return 0.6 + distanceKm(a, b) / 0.75;
  }

  static double distanceKm(MetroStation a, MetroStation b) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final x = (rad(b.lng) - rad(a.lng)) * math.cos((rad(a.lat) + rad(b.lat)) / 2);
    final y = rad(b.lat) - rad(a.lat);
    return math.sqrt(x * x + y * y) * r;
  }

  /// Самый удобный путь между любыми станциями из [from] и из [to] (номера станций).
  MetroRoute? route(Set<int> from, Set<int> to) {
    if (from.isEmpty || to.isEmpty) return null;
    final n = stations.length;
    final cost = List<double>.filled(n, double.infinity);
    final prev = List<int>.filled(n, -1);
    final done = List<bool>.filled(n, false);
    for (final s in from) {
      cost[s] = 0;
    }
    while (true) {
      var u = -1;
      for (var i = 0; i < n; i++) {
        if (!done[i] && cost[i].isFinite && (u < 0 || cost[i] < cost[u])) u = i;
      }
      if (u < 0) return null;
      if (to.contains(u)) return _build(u, prev);
      done[u] = true;
      for (final e in _edges[u]) {
        final c = cost[u] + e.minutes + (e.ride ? 0 : transferPenalty);
        if (c < cost[e.to]) {
          cost[e.to] = c;
          prev[e.to] = u;
        }
      }
    }
  }

  MetroRoute _build(int end, List<int> prev) {
    final path = <int>[end];
    while (prev[path.last] >= 0) {
      path.add(prev[path.last]);
    }
    final nodes = path.reversed.toList();
    final legs = <MetroLeg>[];
    var minutes = waitMinutes;
    var run = <int>[nodes.first];
    void close() {
      if (run.length > 1) legs.add(_leg(run));
    }

    for (var i = 1; i < nodes.length; i++) {
      final a = nodes[i - 1], b = nodes[i];
      final edge = _edges[a].firstWhere((e) => e.to == b);
      minutes += edge.minutes;
      if (edge.ride) {
        run.add(b);
      } else {
        close();
        run = [b];
      }
    }
    close();
    return MetroRoute(legs, minutes.round());
  }

  MetroLeg _leg(List<int> run) {
    final line = lineOf(stations[run.first]);
    final a = run[run.length - 2], b = run.last;
    String toward;
    if (line.circle) {
      toward = stations[run[1]].name;
    } else {
      final branch = line.branches.firstWhere(
        (br) => br.contains(a) && br.contains(b),
        orElse: () => line.branches.first,
      );
      final forward = branch.indexOf(b) > branch.indexOf(a);
      toward = stations[forward ? branch.last : branch.first].name;
    }
    return MetroLeg(line, [for (final s in run) stations[s]], toward);
  }
}
