import 'dart:io';

import 'package:handy_bot/handy_bot.dart';
import 'package:handy_bot/src/commands/ntfy/ntfy_command.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_lavalink/nyxx_lavalink.dart';

/// Environment variables
/// HANDYBOT_API_TOKEN
///
/// (for info feedback storage)
/// HANDYBOT_FEEDBACK_LOG_PATH
///
/// (for single guild setup & lavalink)
/// HANDYBOT_GUILD_VC_CHANNEL_ID
/// HANDYBOT_GUILD_ID
/// HANDYBOT_CLUSTER_ID
Future<void> main() async {
  final envVars = Platform.environment;

  CommandsPlugin commands = CommandsPlugin(
      prefix: mentionOr((_) => '|'),
      guild: Snowflake(envVars['HANDYBOT_GUILD_ID']),
      options: CommandsOptions(
          type: CommandType.slashOnly,
          defaultResponseLevel: ResponseLevel.public));

  final outerBot = NyxxFactory.createNyxxWebsocket(
      envVars['HANDYBOT_API_TOKEN']!, GatewayIntents.allUnprivileged,
      options: ClientOptions(
          initialPresence: PresenceBuilder.of(
              status: UserStatus.online,
              activity: ActivityBuilder.game('The Game Of Life')),
          allowedMentions: AllowedMentions()
            ..allow(everyone: false, users: false, roles: false, reply: false)))
    ..registerPlugin(Logging()) // Default logging plugin
    ..registerPlugin(
        CliIntegration()) // Cli integration for nyxx allows stopping application via SIGTERM and SIGKILl
    ..registerPlugin(
        IgnoreExceptions()) // Plugin that handles uncaught exceptions that may occur
    ..registerPlugin(commands);

  final chessCommand = ChessCommand();

  final infoCommand = InfoCommand(
      outerBot: outerBot,
      feedbackLog: File(envVars['HANDYBOT_FEEDBACK_LOG_PATH']!));

  final musicalCommand = MusicalCommand(
      vcChannelGuildId: Snowflake(envVars['HANDYBOT_GUILD_ID']),
      vcChannelId: Snowflake(envVars['HANDYBOT_GUILD_VC_CHANNEL_ID']),
      cluster: ICluster.createCluster(
          outerBot, Snowflake(envVars['HANDYBOT_CLUSTER_ID'])),
      outerBot: outerBot);

  final ntfyCommand = NtfyCommand();

  Converter<DateTime> dateTimeConverter =
      Converter<DateTime>((viewRaw, context) {
    String view = viewRaw.getQuotedWord();
    return DateTime.tryParse(view);
  });

  commands
    ..addCommand(musicalCommand.musicalGroup)
    ..addCommand(chessCommand.chessGroup)
    ..addCommand(infoCommand.infoCommand)
    ..addCommand(helpCommand)
    ..addCommand(ntfyCommand.ntfyGroup);

  commands.addConverter(chessCommand.squareConverter);
  commands.addConverter(dateTimeConverter);

  commands.check(ChatCommandCheck());

  commands.onCommandError.listen((error) async {
    if (error is CommandInvocationException) {
      String? title;
      String? description;
      if (error is CheckFailedException) {
        switch (error.failed.name) {
          case ChessCommand.wrongUserCheckId:
            error.context.respond(MessageBuilder.content(
                'It isn\'t your turn in this chess game!'));
            return;
        }

        // Should not really hit these with slash commands
        final failed = error.failed;

        if (failed is CooldownCheck) {
          title = 'Command on cooldown';
          description =
              "You can't use this command right now because it is on cooldown. Please wait ${failed.remaining(error.context).toString()} and try again.";
        } else {
          title = "You can't use this command!";
          description =
              'This command can only be used by certain users in certain contexts.'
              ' Check that you have permission to execute the command, or contact a developer for more information.';
        }
      }

      // Should not hit these with slash commands
      else if (error is NotEnoughArgumentsException) {
        title = 'Not enough arguments';
        description = "You didn't provide enough arguments for this command."
            " Please try again and use the Slash Command menu for help, or contact a developer for more information.";
      } else if (error is BadInputException) {
        title = "Couldn't parse input";
        description =
            "Your command couldn't be executed because we were unable to understand your input."
            " Please try again with different inputs or contact a developer for more information.";
      } else if (error is UncaughtException) {
        print('Uncaught exception in command: ${error.exception}');
      }

      // Send a generic response using above [title] and [description] fills
      final embed = EmbedBuilder()
        ..color = DiscordColor.red
        ..title = title ?? 'An error has occurred'
        ..description = description ??
            "Your command couldn't be executed because of an error. Please contact a developer for more information."
        ..addFooter((footer) {
          footer.text = error.runtimeType.toString();
        })
        ..timestamp = DateTime.now();

      await error.context.respond(MessageBuilder.embed(embed));
      return;
    }

    if (error is BadInputException) {
      final context = error.context;
      if (error is ConverterFailedException &&
          context is InteractionChatContext) {
        await context.respond(MessageBuilder.content(
            '${error.input.getQuotedWord()} is not a valid square!'));
        return;
      }
    }

    print('Unhandled exception: $error');
  });

  outerBot.eventsRest.onRateLimited.listen((rateLimitedEvent) {
    print(
        rateLimitedEvent.response?.reasonPhrase ?? rateLimitedEvent.toString());
  });

  outerBot.connect();
}
