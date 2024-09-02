CALL flutter clean
CALL flutter pub get
CALL copy /y ..\flutter_key.properties .\android
CALL copy /y ..\lfq.keystore .\android\app
CALL flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
CALL del /q /S "android\flutter_key.properties"
CALL del /q /S "android\app\lfq.keystore"