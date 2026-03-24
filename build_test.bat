@ECHO OFF
CALL SET "isRelease=%1"
CALL ECHO PASSED isRelease = %isRelease%

if "%~1"=="" (
  CALL ECHO SETTING isRelease=y...
  CALL SET "isRelease=y"
)

CALL flutter clean
CALL flutter pub get
CALL copy /y ..\flutter_key.properties .\android
CALL copy /y ..\lfq.keystore .\android\app
IF "%isRelease%" == "y" (
  CALL ECHO BUILDING RELEASE APP, flutter build apk --release ...
  CALL flutter build apk --release
  CALL ECHO INSTALLING RELEASE APP, adb install ...
  adb install -r build/app/outputs/flutter-apk/app-release.apk
) ELSE (
  CALL ECHO BUILDING DEBUG APP, flutter build apk --debug ...
  CALL flutter build apk --debug
  CALL ECHO INSTALLING DEBUG APP, adb install ...
  adb install -r build/app/outputs/flutter-apk/app-debug.apk
)

CALL del /q /S "android\flutter_key.properties"
CALL del /q /S "android\app\lfq.keystore"