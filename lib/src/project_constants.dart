import 'package:nyxx/nyxx.dart';

class ProjectConstants {
  static const Map<String, String> commandDefinitions = {
    'musical': 'Play Music in VCs', // lavalink_command.dart
    'chess': 'Play 1v1 chess', // chess_command.dart
    'info': 'Get info about the bot', // main.dart
    'help': 'See this help message', // main.dart
    'ntfy':
        'Send notifications to other devices using ntfy.sh' // ntfy_command.dart
  };

  static const String sourceUrl = 'https://github.com/jr1221/handy_bot';

  static final EmbedAuthorBuilder stdEmbedAuthor = EmbedAuthorBuilder()
    ..name = 'Jack1221#6744'
    ..url = sourceUrl
    ..iconUrl = 'https://avatars.githubusercontent.com/u/53871299?v=4';
}
