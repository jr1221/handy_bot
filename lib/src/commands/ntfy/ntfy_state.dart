import 'package:handy_bot/src/commands/ntfy/ntfy_command.dart';
import 'package:ntfy_dart/ntfy_dart.dart';

class NtfyState {
  final NtfyClient _client = NtfyClient();

  void changeBasePath(Uri basePath) {
    _client.changeBasePath(basePath);
  }

  Future<MessageResponse> publish(PublishableMessage message) {
    return _client.publishMessage(message);
  }

  Future<List<MessageResponse>> poll(PollWrapper opts) {
    return _client.pollMessages(opts.topics,
        since: opts.since,
        scheduled: opts.scheduled ?? false,
        filters: opts.filters);
  }
}
