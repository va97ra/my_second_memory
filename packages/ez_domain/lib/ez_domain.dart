/// Модели и чистые правила приложения.
///
/// Пакет не зависит от Flutter, от базы данных и от сети: всё здесь можно
/// выполнить и проверить без запуска приложения. Riverpod-провайдеры живут в
/// приложении, а не тут — провайдер это способ доставки, а не правило.
library;

export 'src/assistant/agenda_speech.dart';
export 'src/assistant/brain_instructions.dart';
export 'src/assistant/butler_persona.dart';
export 'src/assistant/calculation_phrases.dart'
    show calculationReply, spokenNumber;
export 'src/assistant/clarification_phrases.dart';
export 'src/assistant/currency_phrases.dart' show currencyReply;
export 'src/assistant/day_question_phrases.dart'
    show holidaysReply, shiftReply;
export 'src/assistant/finance_phrases.dart' show financeReply;
export 'src/assistant/jarvis_command.dart';
export 'src/assistant/jarvis_command_parser.dart';
export 'src/assistant/jarvis_replies.dart';
export 'src/assistant/record_lookup.dart';
export 'src/assistant/moment_hits.dart' show PhraseRepeat, PhraseRepeatKind;
export 'src/assistant/russian_words.dart'
    show capitalizeFirst, joinWithAnd, lowerFirst, normalizePhrase, searchStems;
export 'src/assistant/small_talk.dart';
export 'src/assistant/spoken_moments.dart';
export 'src/assistant/task_phrase.dart';
export 'src/assistant/unit_phrases.dart' show unitReply;
export 'src/assistant/wake_word.dart' show WakeWord;
export 'src/calculator/calculator_engine.dart';
export 'src/calculator/calculator_types.dart';
export 'src/finance/exchange_rates.dart';
export 'src/finance/finance_entry.dart';
export 'src/finance/finance_summary.dart';
export 'src/accounts/account_item.dart';
export 'src/calendar/holiday_calendar_service.dart';
export 'src/calendar/production_calendar.dart';
export 'src/calendar/iso_week.dart';
export 'src/calendar/workday_progress.dart';
export 'src/calendar/holiday_definition.dart';
export 'src/calendar/holiday_fixed_table.dart';
export 'src/calendar/holiday_observance_table.dart';
export 'src/calendar/holiday_occurrence.dart';
export 'src/calendar/holiday_russian_table.dart';
export 'src/feed/feed_rules.dart';
export 'src/language/russian_plural.dart';
export 'src/feed/memory_search.dart';
export 'src/memory/memory_item.dart';
export 'src/memory/memory_move.dart';
export 'src/memory/reminder_rules.dart';
export 'src/memory/memory_status.dart';
export 'src/memory/memory_title.dart';
export 'src/memory/memory_type.dart';
export 'src/memory/voice_note.dart';
export 'src/recurrence/recurrence_occurrence_exception.dart';
export 'src/recurrence/recurrence_dates.dart';
export 'src/recurrence/recurrence_projection_service.dart';
export 'src/recurrence/recurrence_series.dart';
export 'src/recurrence/recurrence_split.dart';
export 'src/shifts/shift_alarm_times.dart';
export 'src/shifts/shift_presets.dart';
export 'src/shifts/shift_schedule.dart';
export 'src/shifts/shift_schedule_deduplication.dart';
export 'src/sync/sync_backend_config.dart';
export 'src/sync/sync_merge.dart';
export 'src/sync/sync_models.dart';
export 'src/sync/sync_mutation_observer.dart';
export 'src/tools/tool_data.dart';
export 'src/tools/unit_converter.dart';
