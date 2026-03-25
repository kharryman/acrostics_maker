#!/bin/bash
echo "Stopping any running Flutter processes..."
pkill -f flutter
echo "Removing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData
echo "Removing Xcode/Archives..."
rm -rf ~/Library/Developer/Xcode/Archives/*
echo "Shutting down sim controllers..."
xcrun simctl shutdown all
echo "Cleaning project..."
flutter clean
echo "Getting packages..."
flutter pub get
echo "Removing old IPA..."
rm -f build/ios/ipa/*.ipa
echo "Building iOS IPA (release)..."
flutter build ipa --release
echo "Running release notes script..."
node node_trans_release_notes_ios.js
echo "Deploying with Fastlane..."
cd ios
bundle exec fastlane deploy
cd ..
echo "Done."