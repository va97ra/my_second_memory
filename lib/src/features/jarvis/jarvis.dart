/// Джарвис: голосовой помощник, который ведёт календарь, записи, финансы и
/// настройки словами.
///
/// Снаружи фича видна только отсюда: остальное — её кухня.
library;

export 'state/jarvis_bank_notices.dart'
    show
        jarvisBankAccessProvider,
        jarvisBankNoticesProvider,
        jarvisBankWatcherProvider;
export 'state/jarvis_briefings.dart'
    show
        jarvisBriefingSettingsProvider,
        jarvisBriefingsProvider,
        jarvisSpeakRemindersProvider;
export 'state/jarvis_brain_providers.dart'
    show gigaChatClientProvider, gigaChatKeyProvider;
export 'state/jarvis_controller.dart';
export 'state/jarvis_wake_controller.dart' show jarvisWakeEnabledProvider;
export 'ui/jarvis_sheet.dart';
export 'ui/jarvis_wake_host.dart';
