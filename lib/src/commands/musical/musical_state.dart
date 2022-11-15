import 'package:nyxx/nyxx.dart'
    show INyxxWebsocket, IVoiceGuildChannel, Snowflake;
import 'package:nyxx_lavalink/nyxx_lavalink.dart';

class MusicalState {
  final Snowflake vcChannelGuildId;
  late IVoiceGuildChannel _vcChannel;
  late INode _localLavaNode;

  late Future<void> initializationStatus;

  MusicalState(
      {required this.vcChannelGuildId,
      required vcChannelId,
      required ICluster cluster,
      required INyxxWebsocket outerBot}) {
    initializationStatus =
        _initialize(cluster: cluster, bot: outerBot, channelId: vcChannelId);
  }

  Future<void> _initialize(
      {required ICluster cluster,
      required INyxxWebsocket bot,
      required Snowflake channelId}) async {
    await cluster.addNode(NodeOptions());
    _vcChannel = await bot.fetchChannel<IVoiceGuildChannel>(channelId);
    _localLavaNode = cluster.getOrCreatePlayerNode(vcChannelGuildId);
  }

  void _shutdown() {
    _localLavaNode.disconnect();
    _localLavaNode.shutdown();
    _vcChannel.disconnect();
    _vcChannel.dispose();
  }

  void join() {
    _vcChannel.connect();
  }

  void leave() {
    _vcChannel.disconnect();
  }

  void play() {
    _localLavaNode.resume(vcChannelGuildId);
  }

  void pause() {
    _localLavaNode.pause(vcChannelGuildId);
  }

  void skip() {
    _localLavaNode.skip(vcChannelGuildId);
  }

  void shutdown() {
    _shutdown();
  }

  void clear() {
    // TODO:
  }

  String now() {
    ITrackInfo nowInfo =
        _localLavaNode.players.entries.first.value.nowPlaying!.track.info!;
    return '```${nowInfo.title} by ${nowInfo.author},  ${((nowInfo.length) / 1000 / 60).truncate()}:${(((nowInfo.length) / 1000) - ((((nowInfo.length) / 1000 / 60).truncate() * 60))).toInt()}```';
  }

  String queue() {
    StringBuffer queueInfo = StringBuffer();
    queueInfo.write('```');
    try {
      for (final track in _localLavaNode.players.entries.first.value.queue) {
        queueInfo.writeln(
            "${track.track.info?.title ?? 'Unknown'} by ${track.track.info?.author ?? 'Unknown'},  ${((track.track.info?.length ?? 0) / 1000 / 60).truncate()}:${(((track.track.info?.length ?? 0) / 1000) - ((((track.track.info?.length ?? 0) / 1000 / 60).truncate() * 60))).toInt()} \n");
      }
    } catch (_) {
      return 'Nothing in queue';
    }
    queueInfo.write('```');
    return queueInfo.toString();
  }

  String info() {
    if (_localLavaNode.stats != null) {
      StringBuffer lavaInfo = StringBuffer();
      lavaInfo.write('```');
      lavaInfo.writeln(
          '${_localLavaNode.stats!.playingPlayers}/${_localLavaNode.stats!.players} players running');
      lavaInfo.writeln(
          '${(_localLavaNode.stats!.cpu.lavalinkLoad.toDouble()) / (_localLavaNode.stats!.cpu.lavalinkLoad.toDouble())}% of ${_localLavaNode.stats!.cpu.systemLoad}% system load is from this lavalink instance');
      lavaInfo.writeln('${_localLavaNode.stats!.memory.free} free memory');
      lavaInfo.writeln('${_localLavaNode.stats!.uptime} server uptime');
      lavaInfo.write('```');
      return lavaInfo.toString();
    }
    return 'Lavalink not initialized!';
  }

  String? volume(int volume) {
    _localLavaNode.volume(vcChannelGuildId, volume);
    return null;
  }

  String? seek(int minTo, int secTo) {
    try {
      _localLavaNode.seek(
          vcChannelGuildId, Duration(minutes: minTo, seconds: secTo));
    } catch (_) {
      return 'Invalid time - Enter it as <minutes>:<seconds>, not $seek';
    }
    return null;
  }

  Future<String> add(String addReq) async {
    final searchResults = await _localLavaNode.searchTracks(addReq);
    StringBuffer searchPrint = StringBuffer();
    searchPrint.write('```');
    int trackIndex = 1;
    for (ITrack track in searchResults.tracks) {
      searchPrint.writeln(
          '$trackIndex -- ${track.info?.title ?? 'Unknown'} by ${track.info?.author ?? 'Unknown'},  ${((track.info?.length ?? 0) / 1000 / 60).truncate()}:${(((track.info?.length ?? 0) / 1000) - ((((track.info?.length ?? 0) / 1000 / 60).truncate() * 60))).toInt()} ');
      trackIndex++;
    }
    searchPrint.write('```');
    _localLavaNode.play(vcChannelGuildId, searchResults.tracks[0]).queue();

    return searchPrint.toString();
  }
}
