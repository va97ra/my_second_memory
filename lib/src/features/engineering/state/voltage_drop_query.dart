import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';

/// Поля расчёта падения напряжения, разобранные и проверенные.
///
/// Разбор отделён от расчёта нарочно. Раньше весь расчёт был обёрнут в
/// `catch`, и любая беда — пустое поле, ноль в сечении, ошибка в самом
/// расчёте — выглядела одинаково: «Введите корректное число». Теперь
/// негодное поле названо по имени, а до расчёта дело просто не доходит.
sealed class VoltageDropInput {
  const VoltageDropInput();
}

/// Поле, которое мешает посчитать, названо подписью — той же, что на экране.
class VoltageDropProblem extends VoltageDropInput {
  const VoltageDropProblem(this.field);

  final String field;
}

class VoltageDropQuery extends VoltageDropInput {
  const VoltageDropQuery({
    required this.currentA,
    required this.oneWayLengthM,
    required this.sectionMm2,
    required this.voltageV,
    required this.powerFactor,
    required this.limitPercent,
    required this.threePhase,
    required this.material,
    required this.routing,
  });

  final double currentA;
  final double oneWayLengthM;
  final double sectionMm2;
  final double voltageV;
  final double powerFactor;
  final double limitPercent;
  final bool threePhase;
  final ConductorMaterial material;
  final WireRouting routing;

  VoltageDropResult get result => voltageDrop(
        currentA: currentA,
        oneWayLengthM: oneWayLengthM,
        sectionMm2: sectionMm2,
        voltageV: voltageV,
        threePhase: threePhase,
        material: material,
        routing: routing,
        powerFactor: powerFactor,
      );

  /// Сечение, при котором линия уложится в норму, или `null`, если такого в
  /// стандартном ряду нет.
  double? get minimumSectionMm2 => minimumSectionForDrop(
        currentA: currentA,
        oneWayLengthM: oneWayLengthM,
        voltageV: voltageV,
        threePhase: threePhase,
        material: material,
        routing: routing,
        limitPercent: limitPercent,
        powerFactor: powerFactor,
      );

  /// Условия расчёта для сохранённой карточки: сохраняется то, из чего
  /// получен ответ, иначе через месяц ответ нечем объяснить.
  Map<String, double> get savedValues => {
        'voltageV': voltageV,
        'currentA': currentA,
        'powerFactor': powerFactor,
        'lengthM': oneWayLengthM,
        'sectionMm2': sectionMm2,
        'threePhase': threePhase ? 1 : 0,
        'aluminium': material == ConductorMaterial.aluminium ? 1 : 0,
        'routing': routing.index.toDouble(),
        'limitPercent': limitPercent,
      };
}

/// Разбирает поля экрана. Порядок проверок — порядок полей сверху вниз.
VoltageDropInput readVoltageDropInput({
  required AppStrings strings,
  required String voltage,
  required String load,
  required bool loadIsPower,
  required String powerFactor,
  required String length,
  required double sectionMm2,
  required double limitPercent,
  required bool threePhase,
  required ConductorMaterial material,
  required WireRouting routing,
}) {
  final voltageV = parseToolNumber(voltage);
  if (voltageV == null || voltageV <= 0) {
    return VoltageDropProblem(strings.voltage);
  }
  final loadValue = parseToolNumber(load);
  final loadLabel = loadIsPower ? strings.loadPower : strings.loadCurrent;
  if (loadValue == null || loadValue < 0) return VoltageDropProblem(loadLabel);
  final factor = parseToolNumber(powerFactor);
  if (factor == null || factor <= 0 || factor > 1) {
    return const VoltageDropProblem('cos φ');
  }
  final lengthM = parseToolNumber(length);
  if (lengthM == null || lengthM < 0) {
    return VoltageDropProblem(strings.oneWayLength);
  }
  return VoltageDropQuery(
    currentA: loadIsPower
        ? (threePhase
            ? threePhaseCurrent(
                powerW: loadValue * 1000,
                lineVoltageV: voltageV,
                powerFactor: factor,
              )
            : singlePhaseCurrent(
                powerW: loadValue * 1000,
                voltageV: voltageV,
                powerFactor: factor,
              ))
        : loadValue,
    oneWayLengthM: lengthM,
    sectionMm2: sectionMm2,
    voltageV: voltageV,
    powerFactor: factor,
    limitPercent: limitPercent,
    threePhase: threePhase,
    material: material,
    routing: routing,
  );
}
