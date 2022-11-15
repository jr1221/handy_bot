import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_lavalink/nyxx_lavalink.dart';

import '../../project_constants.dart';
import 'musical_state.dart';

const Converter<int> volumeConverter = IntConverter(min: 0, max: 100);

class MusicalCommand {
  final MusicalState _musical;

  MusicalCommand(
      {required Snowflake vcChannelGuildId,
      required Snowflake vcChannelId,
      required ICluster cluster,
      required INyxxWebsocket outerBot})
      : _musical = MusicalState(
            vcChannelGuildId: vcChannelGuildId,
            vcChannelId: vcChannelId,
            cluster: cluster,
            outerBot: outerBot);

  ChatGroup get musicalGroup =>
      ChatGroup('musical', ProjectConstants.commandDefinitions['musical']!,
          children: [
            ChatCommand(
                'join',
                'Join the VC',
                id('join', (IChatContext context) async {
                  await _musical.initializationStatus;
                  _musical.join();
                })),
            ChatCommand(
                'leave',
                'Leave the VC',
                id('leave', (IChatContext context) async {
                  await _musical.initializationStatus;
                  _musical.leave();
                })),
            ChatCommand(
                'play',
                'Play the current media',
                id('play', (IChatContext context) async {
                  await _musical.initializationStatus;
                  _musical.play();
                })),
            ChatCommand(
                'pause',
                'Pause the current media',
                id('pause', (IChatContext context) async {
                  await _musical.initializationStatus;
                  _musical.pause();
                })),
            ChatCommand(
                'skip',
                'Skip the current media',
                id('skip', (IChatContext context) async {
                  await _musical.initializationStatus;
                  _musical.skip();
                })),
            ChatCommand(
                'shutdown',
                'Shutdown the node (irreversible)!',
                id('shutdown', (IChatContext context) async {
                  await _musical.initializationStatus;
                  _musical.shutdown();
                })),
            ChatCommand(
                'clear',
                'Clear the queue',
                id('clear', (IChatContext context) async {
                  await _musical.initializationStatus;
                  _musical.clear();
                })),
            ChatCommand(
                'now',
                'Show info about the current media',
                id('now', (IChatContext context) async {
                  await _musical.initializationStatus;
                  context.respond(MessageBuilder.content(_musical.now()));
                })),
            ChatCommand(
                'queue',
                'Show info about the queue',
                id('queue', (IChatContext context) async {
                  await _musical.initializationStatus;
                  context.respond(MessageBuilder.content(_musical.queue()));
                })),
            ChatCommand(
                'info',
                'Show info about the server',
                id('info', (IChatContext context) async {
                  await _musical.initializationStatus;
                  context.respond(MessageBuilder.content(_musical.info()));
                })),
            ChatCommand(
                'volume',
                'Change the volume',
                id('volume', (IChatContext context,
                    @UseConverter(volumeConverter)
                    @Description('0 to 100')
                        volume) async {
                  await _musical.initializationStatus;
                  context.respond(MessageBuilder.content(
                      _musical.volume(volume) ?? 'Success!'));
                })),
            ChatCommand(
                'seek',
                'Go to a certain spot in the media',
                id('seek', (IChatContext context,
                    @Description('Minutes from start') min,
                    @Description('Seconds from minute') sec) async {
                  await _musical.initializationStatus;
                  context.respond(MessageBuilder.content(
                      _musical.seek(min, sec) ?? 'Success!'));
                })),
            ChatCommand(
                'add',
                'Add a song to the queue',
                id('add', (IChatContext context,
                    @Name('url')
                    @Description('URL of song on yt, soundcloud, etc')
                        addUrl) async {
                  await _musical.initializationStatus;
                  context.respond(
                      MessageBuilder.content(await _musical.add(addUrl)));
                }))
          ]);
}
