import 'windows_desktop_contract.dart';
import 'windows_desktop_stub.dart'
    if (dart.library.io) 'windows_desktop_io.dart';

export 'windows_desktop_contract.dart';

final WindowsDesktopPlatform windowsDesktopPlatform =
    createWindowsDesktopPlatform();
