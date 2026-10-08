/// Джарвис: голосовой помощник, который ведёт календарь, записи, финансы и
/// настройки словами.
///
/// Снаружи фича видна только отсюда: остальное — её кухня.
library;

export 'state/jarvis_brain_providers.dart'
    show gigaChatClientProvider, gigaChatKeyProvider;
export 'state/jarvis_controller.dart';
export 'ui/jarvis_sheet.dart';
