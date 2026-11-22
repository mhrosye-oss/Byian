#!/usr/bin/env bash
set -eu

mkdir -p build/startup-diagnostics
collect_diagnostics() {
  adb logcat -d -v time > build/startup-diagnostics/logcat.txt || true
  adb exec-out screencap -p > build/startup-diagnostics/screen.png || true
  adb shell dumpsys activity activities > build/startup-diagnostics/activities.txt || true
}
trap collect_diagnostics EXIT

# The integration test checks that a clean debug launch reaches the app.
flutter test integration_test/app_startup_test.dart -d emulator-5554

# Independently install and launch the release-mode APK built by this job.
adb uninstall com.itqan.itqan || true
adb install build/app/outputs/flutter-apk/app-x86_64-release.apk
adb logcat -c
adb shell am start -n com.itqan.itqan/.MainActivity
sleep 30
adb shell pidof com.itqan.itqan
adb shell dumpsys activity activities \
  | grep -E 'mResumedActivity|topResumedActivity' \
  | grep -F 'com.itqan.itqan'
