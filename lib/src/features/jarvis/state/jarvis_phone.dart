import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'jarvis_outcome.dart';

final jarvisPhoneProvider = Provider<JarvisPhone>((ref) => const JarvisPhone());

/// Руки Джарвиса в телефоне: фонарик, «Часы», набор номера, сообщения и
/// приложения (`PhoneActions.kt`).
///
/// Звонок и сообщение не уходят сами — открывается набор номера или чат с
/// готовым текстом, а нажимает человек. Контакты читаются, только когда
/// назвали, кому звонить, и только с разрешения.
class JarvisPhone {
  const JarvisPhone();

  static const _channel = MethodChannel('ezhednevnik_v2/phone');

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<T?> _call<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<JarvisOutcome> run(PhoneCommand command) async {
    if (!_supported) return const JarvisOutcome(PhoneReplies.notHere);
    switch (command) {
      case PhoneTorch(:final on):
        final done = await _call<bool>('torch', {'on': on}) == true;
        return JarvisOutcome(PhoneReplies.torch(on: on, done: done));
      case PhoneAlarm(:final minutes):
        final done = await _call<bool>('setAlarm',
                {'hour': minutes ~/ 60, 'minute': minutes % 60}) ==
            true;
        return JarvisOutcome(PhoneReplies.alarm(minutes, done: done));
      case PhoneTimer(:final seconds):
        final done = await _call<bool>('setTimer', {'seconds': seconds}) == true;
        return JarvisOutcome(PhoneReplies.timer(seconds, done: done));
      case PhoneOpenApp(:final name):
        final label = await _call<String>('openApp', {'query': name});
        return JarvisOutcome(
            label == null ? PhoneReplies.noApp(name) : PhoneReplies.opened(label));
      case PhoneCall(:final who):
        final contact = await _contact(who);
        if (contact == null) return JarvisOutcome(PhoneReplies.notFound(who));
        if (contact.number.isEmpty) {
          return const JarvisOutcome(PhoneReplies.contactsDenied);
        }
        final done = await _call<bool>('dial', {'number': contact.number}) == true;
        return JarvisOutcome(done
            ? PhoneReplies.dialing(contact.name)
            : PhoneReplies.noMessenger(PhoneMessenger.sms));
      case PhoneMessage(:final who, :final text, :final app):
        // Telegram номер по ссылке не откроет: текст уходит в него, а чат
        // человек выбирает сам.
        final contact = app == PhoneMessenger.telegram
            ? (name: who, number: '')
            : await _contact(who);
        if (contact == null) return JarvisOutcome(PhoneReplies.notFound(who));
        if (app != PhoneMessenger.telegram && contact.number.isEmpty) {
          return const JarvisOutcome(PhoneReplies.contactsDenied);
        }
        final done = await _call<bool>('message', {
              'number': contact.number,
              'text': text,
              'app': app.name,
            }) ==
            true;
        return JarvisOutcome(done
            ? PhoneReplies.written(contact.name, app)
            : PhoneReplies.noMessenger(app));
    }
  }

  /// Контакт по имени в любом падеже или номер, названный цифрами. Номер
  /// пустой — нет разрешения на контакты; null — такого контакта нет.
  Future<({String name, String number})?> _contact(String who) async {
    final digits = who.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.length >= 5) return (name: digits, number: digits);
    final rows = await _call<List<Object?>>('contacts');
    if (rows == null) return (name: who, number: '');
    final contacts = [
      for (final row in rows.whereType<Map<Object?, Object?>>())
        (name: '${row['name']}', number: '${row['number']}'),
    ];
    final best = bestContact(who, [for (final c in contacts) c.name]);
    return best == null ? null : contacts[best];
  }
}
