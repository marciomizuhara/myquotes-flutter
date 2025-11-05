flutter clean
flutter build apk --release
adb -s RQ8R406D7GD install -r build/app/outputs/flutter-apk/app-release.apk
