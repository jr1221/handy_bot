import 'dart:convert';
import 'dart:io';

import '../lib/src/commands/info/feedback_model.dart';

/// Environment variables
/// HANDYBOT_FEEDBACK_LOG_PATH
void main(List<String> args) {
  File feedbackFile = File(Platform.environment['HANDYBOT_FEEDBACK_LOG_PATH']!);
  for (String line in feedbackFile.readAsLinesSync()) {
    final feedback = FeedbackModel.fromJson(jsonDecode(line.trim()));
    print(
        '${feedback.recievedAt.toLocal().toString()} -- ${feedback.username}: \n${feedback.feedbackInput} \n');
  }
}
