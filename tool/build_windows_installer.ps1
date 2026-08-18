$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$flutterPath = Join-Path $projectRoot '.tools\flutter\bin\flutter.bat'
$installerScript = Join-Path $projectRoot 'installer\ezhednevnik_v2.iss'
$portableCompiler = Join-Path $projectRoot '.tools\inno-setup-7.0.2\ISCC.exe'

$versionLine = Select-String -LiteralPath (Join-Path $projectRoot 'pubspec.yaml') -Pattern '^version:\s*([^+\s]+)'
if (-not $versionLine) {
  throw 'Could not read the application version from pubspec.yaml.'
}
$appVersion = $versionLine.Matches[0].Groups[1].Value

$isccCommand = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
$isccPath = if ($isccCommand) { $isccCommand.Source } else { $portableCompiler }
if (-not (Test-Path -LiteralPath $isccPath)) {
  throw 'Inno Setup compiler was not found. Install Inno Setup 7 or place its portable files in .tools\inno-setup-7.0.2.'
}

Push-Location $projectRoot
try {
  & $flutterPath build windows --release --no-pub
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter Windows build failed with exit code $LASTEXITCODE."
  }

  & $isccPath "/DAppVersion=$appVersion" $installerScript
  if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compilation failed with exit code $LASTEXITCODE."
  }
} finally {
  Pop-Location
}
