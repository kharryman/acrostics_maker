CALL flutter clean
CALL flutter pub get
CALL copy /y ..\flutter_key.properties .\android
CALL copy /y ..\lfq.keystore .\android\app
CALL del /q /S ".\build\app\outputs\flutter-apk\app-release.apk"
CALL flutter build apk --release
CALL cd .\build\app\outputs\flutter-apk
CALL adb install app-release.apk
CALL cd ..\..\..\..
CALL del /q /S "android\flutter_key.properties"
CALL del /q /S "android\app\lfq.keystore"