import 'package:logging/logging.dart';

void setupLogging() {
  Logger.root.level = Level.ALL; // Set the minimum level of logs to be recorded
  Logger.root.onRecord.listen((record) {
    // In a real app, you might send this to a remote logging service
    // (e.g., Sentry, Firebase Crashlytics, etc.)
    // For now, we'll just print it to the console.
    print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');

    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('StackTrace: ${record.stackTrace}');
    }
  });
}
