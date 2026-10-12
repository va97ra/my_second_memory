import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Какая страница сейчас на экране, с днём, если он у неё есть; null — та,
/// которой у Джарвиса нет названия. Её отмечает оболочка при каждой смене
/// адреса.
///
/// По ней Джарвис понимает «что здесь» и видно ли калькулятор, на котором
/// он нажимает клавиши.
final jarvisPageProvider = StateProvider<OpenPlace?>((ref) => null);
