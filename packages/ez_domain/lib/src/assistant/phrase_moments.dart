import 'date_phrases.dart';
import 'moment_hits.dart';
import 'phrase_scan.dart';
import 'repeat_phrases.dart';
import 'russian_words.dart';
import 'time_phrases.dart';

/// Вынимает из фразы всё, что говорит о моменте дела.
///
/// Порядок важен: повторы — раньше дней недели, иначе «по вторникам» стало бы
/// одним вторником; «через 2 часа» — раньше часов, иначе стало бы «в 2 часа».
MomentHits collectMoments(PhraseScan scan, DateTime now) {
  final hits = MomentHits();
  collectRepeat(scan, hits);
  collectRelativeTime(scan, hits);
  collectDates(scan, hits, now);
  // Длительность раньше времени: «с 12 до 13» — не два времени, а начало и
  // длина.
  collectDuration(scan, hits);
  collectTimes(scan, hits);
  if (scan.takes(_allDay)) hits.allDay = true;
  if (scan.takes(_noDate)) hits.noDate = true;
  return hits;
}

final _allDay = phrasePattern('$wordStart(?:весь\\s+день|в\\s+течение\\s+дня'
    '|без\\s+времени|в\\s+любое\\s+время|любое\\s+время|не\\s+важно|неважно'
    '|когда\\s+угодно)$wordEnd');

final _noDate = phrasePattern('$wordStart(?:без\\s+даты|без\\s+дня|не\\s+знаю'
    '|когда-нибудь|когда\\s+нибудь|потом)$wordEnd');
