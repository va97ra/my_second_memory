#ifndef AppVersion
  ; Держится на 1.1.0, пока обновление не выложено в RuStore. Значение
  ; можно передать снаружи: ISCC /DAppVersion=1.2.0
  #define AppVersion "1.1.0"
#endif

#define AppName "Ежедневник V2"
#define AppExeName "ezhednevnik_v2.exe"
#define AppUrlScheme "io.supabase.ezhednevnik"
#define ReleaseDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{1761B760-80ED-490E-BC9F-9FA028AB8944}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
VersionInfoVersion={#AppVersion}
VersionInfoProductName={#AppName}
DefaultDirName={localappdata}\Programs\{#AppName}
DefaultGroupName={#AppName}
DisableDirPage=no
DisableProgramGroupPage=yes
AllowNoIcons=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
WizardStyle=modern dynamic
Compression=lzma2/ultra64
SolidCompression=yes
; Restart Manager здесь бесполезен: приложение живёт в трее и на его вежливую
; просьбу закрыться не выходит, а прячется. Закрываем сами, в [Code].
CloseApplications=no
UsePreviousAppDir=yes
UsePreviousTasks=yes
OutputDir=..\windows\release
OutputBaseFilename=Ezhednevnik-V2-Setup-{#AppVersion}-x64
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Classes\{#AppUrlScheme}"; ValueType: string; ValueName: ""; ValueData: "URL:{#AppName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\{#AppUrlScheme}"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\{#AppUrlScheme}\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"" ""%1"""

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Приложение сворачивается в трей и продолжает держать свои файлы: в Windows
// у окна стоит setPreventClose, и закрытие окна его не завершает. Поэтому
// перед установкой поверх старой версии и перед удалением процесс гасится
// явно — иначе установщик упирается в занятый файл и просит перезагрузку.
procedure StopRunningApp;
var
  ResultCode: Integer;
begin
  // Сначала по-хорошему: вдруг когда-нибудь научится выходить сам.
  Exec(
    ExpandConstant('{sys}\taskkill.exe'),
    '/IM "{#AppExeName}"',
    '',
    SW_HIDE,
    ewWaitUntilTerminated,
    ResultCode
  );
  Sleep(1500);
  // Затем принудительно. Если процесса уже нет, taskkill просто ничего не
  // сделает — отдельная проверка не нужна.
  Exec(
    ExpandConstant('{sys}\taskkill.exe'),
    '/F /IM "{#AppExeName}"',
    '',
    SW_HIDE,
    ewWaitUntilTerminated,
    ResultCode
  );
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  StopRunningApp;
  Result := '';
end;

function InitializeUninstall(): Boolean;
begin
  StopRunningApp;
  Result := True;
end;
