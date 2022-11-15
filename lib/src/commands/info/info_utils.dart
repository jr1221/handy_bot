import 'dart:io' show Platform, ProcessInfo;

String get platformVersion => Platform.version.split("(").first;

String get operatingSystemName => Platform.operatingSystem; // TODO

String memoryUsage() {
  final current = (ProcessInfo.currentRss / 1024 / 1024).toStringAsFixed(2);
  final rss = (ProcessInfo.maxRss / 1024 / 1024).toStringAsFixed(2);
  return "$current/${rss}MB";
}
