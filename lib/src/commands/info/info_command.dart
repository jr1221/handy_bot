import 'dart:convert';
import 'dart:io';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';

import '../../project_constants.dart';
import 'feedback_model.dart';
import 'info_utils.dart';

class InfoCommand {
  final INyxxWebsocket outerBot;
  final File feedbackLog;

  static const String feedbackButtonId = 'feedback-button';
  static const String feedbackTextInputId = 'feedback-input';

  InfoCommand({required this.outerBot, required this.feedbackLog});

  ChatCommand get infoCommand => ChatCommand(
      'info',
      ProjectConstants.commandDefinitions['info']!,
      id('info', (IChatContext context) {
        EmbedBuilder infoEmbed = EmbedBuilder()
          ..title = 'Bot Info'
          ..description = 'See technical info'
          ..author = ProjectConstants.stdEmbedAuthor
          ..timestamp = DateTime.now()
          ..addField(
              name: 'Library',
              content: '[Nyxx](https://nyxx.l7ssha.xyz/) v${outerBot.version}',
              inline: true)
          ..addField(
              name: 'Start time',
              content: outerBot.startTime.toString(),
              inline: true)
          ..addField(name: 'Memory Usage', content: memoryUsage(), inline: true)
          ..addFooter((footer) {
            footer.text =
                'Dart SDK $platformVersion on ${operatingSystemName.onlyFirstCaps()}';
          });

        ComponentMessageBuilder infoResponse = ComponentMessageBuilder()
          ..embeds = [infoEmbed]
          ..addComponentRow(ComponentRowBuilder()
            ..addComponent(ButtonBuilder(
                'Give feedback', feedbackButtonId, ButtonStyle.primary))
            ..addComponent(
                LinkButtonBuilder('Source', ProjectConstants.sourceUrl)));

        context.respond(infoResponse);

        context
            .awaitButtonPress(feedbackButtonId, timeout: Duration(minutes: 5))
            .then((event) =>
                event.getModal(title: 'Give feedback', components: [
                  TextInputBuilder(feedbackTextInputId,
                      TextInputStyle.paragraph, 'Private feedback')
                    ..required = true
                    ..placeholder = 'Enter private feedback here...'
                ]).then((event) async {
                  if (event[feedbackTextInputId].isNotEmpty) {
                    final feedbackModel = FeedbackModel(
                        event.interactionEvent.receivedAt,
                        event.interaction.userAuthor?.username ?? 'Unknown',
                        event[feedbackTextInputId]);
                    feedbackLog.writeAsString('${jsonEncode(feedbackModel)}\n',
                        flush: true, mode: FileMode.append);
                    print('Received feedback!');
                    await event
                        .respond(MessageBuilder.content('Thanks for sharing!'));
                  }
                }));
      }));
}

extension Capitalize on String {
  String onlyFirstCaps() {
    String lowered = toLowerCase();
    return lowered.substring(0, 1).toUpperCase() + lowered.substring(1);
  }
}
