import 'package:ez_design/ez_design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('page turn coordinator allows only one physical sheet at a time', () {
    final coordinator = PageTurnCoordinator();
    final outerPage = Object();
    final innerPage = Object();

    expect(coordinator.tryAcquire(innerPage), isTrue);
    expect(coordinator.isBusy, isTrue);
    expect(coordinator.tryAcquire(outerPage), isFalse);
    coordinator.release(outerPage);
    expect(coordinator.isBusy, isTrue);
    coordinator.release(innerPage);
    expect(coordinator.isBusy, isFalse);
    expect(coordinator.tryAcquire(outerPage), isTrue);
  });
}
