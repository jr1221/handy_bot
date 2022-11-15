import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import '../../project_constants.dart';

final ChatCommand helpCommand = ChatCommand(
    'help',
    ProjectConstants.commandDefinitions['help']!,
    id('help', (IChatContext context) {
      EmbedBuilder helpEmbed = EmbedBuilder()
        ..title = 'Bot Help'
        ..description = 'See bot commands'
        ..author = ProjectConstants.stdEmbedAuthor
        ..timestamp = DateTime.now();
      ProjectConstants.commandDefinitions.forEach((key, value) {
        helpEmbed.addField(name: key, content: value, inline: true);
      });

      context.respond(MessageBuilder.embed(helpEmbed));
    }));
