@echo off
REM One-time setup for Windows: generates Android/iOS runners, creates env.json and fetches packages.
cd /d "%~dp0\.."

call flutter create . --org com.newsintel --project-name mini_news_intelligence --platforms=android,ios
if errorlevel 1 exit /b 1

powershell -NoProfile -Command ^
  "$m='android/app/src/main/AndroidManifest.xml';" ^
  "if ((Test-Path $m) -and -not (Select-String -Path $m -Pattern 'android.permission.INTERNET' -Quiet)) {" ^
  "  $c = Get-Content $m -Raw;" ^
  "  $c = $c -replace '(<manifest[^>]*>)', ('$1' + [Environment]::NewLine + '    <uses-permission android:name=\"android.permission.INTERNET\"/>');" ^
  "  Set-Content -Path $m -Value $c -NoNewline;" ^
  "  Write-Host 'Added INTERNET permission to' $m }"

if not exist env.json (
  copy env.example.json env.json >nul
  echo Created env.json - paste your NewsAPI key into it.
)

call flutter pub get
echo.
echo Done. Run:  flutter run --dart-define-from-file=env.json
