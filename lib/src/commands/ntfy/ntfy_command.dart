import 'package:handy_bot/handy_bot.dart';
import 'package:handy_bot/src/commands/ntfy/ntfy_state.dart';
import 'package:ntfy_dart/ntfy_dart.dart';
import 'package:nyxx/nyxx.dart' hide ActionTypes;
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';

class NtfyCommand {
  final NtfyState _ntfyState;

  // <---- PUBLISH COMPONENT IDs ---->

  // Publish root buttons
  static const String ntfyPublishViewActionButtonId =
      'ntfy-publish-viewaction-button';
  static const String ntfyPublishBroadcastActionButtonId =
      'ntfy-publish-broadcastaction-button';
  static const String ntfyPublishHttpActionButtonId =
      'ntfy-publish-httpaction-button';
  static const String ntfyPublishOptsButtonId = 'ntfy-publish-opts-button';
  static const String ntfyPublishButtonId = 'ntfy-publish-blank-button';
  static const String ntfyPublishAdvOptsButtonId =
      'ntfy-publish-advopts-button';

  // Publish root priority select
  static const String ntfyPublishPrioritySelectId =
      'ntfy-publish-priority-select';

  // Publish basic options keys
  static const String ntfyPublishOptsInputMessageId =
      'ntfy-publish-opts-modal-message';
  static const String ntfyPublishOptsInputTitleId =
      'ntfy-publish-opts-modal-title';
  static const String ntfyPublishOptsInputFilenameId =
      'ntfy-publish-opts-modal-filename';
  static const String ntfyPublishOptsInputTagsId =
      'ntfy-publish-opts-modal-tags';
  static const String ntfyPublishOptsInputAttachmentId =
      'ntfy-publish-opts-modal-attachment';

  // Publish advanced options keys
  static const String ntfyPublishAdvOptsInputEmailId =
      'ntfy-publish-advopts-modal-email';
  static const String ntfyPublishAdvOptsInputClickId =
      'ntfy-publish-advopts-modal-click';
  static const String ntfyPublishAdvOptsInputIconId =
      'ntfy-publish-advopts-modal-icon';
  static const String ntfyPublishAdvOptsInputAuthUsernameId =
      'ntfy-publish-advopts-modal-authusername';
  static const String ntfyPublishAdvOptsInputAuthPasswordId =
      'ntfy-publish-advopts-modal-authpassword';

  // Publish view action keys
  static const String ntfyPublishViewActionInputLabelId =
      'ntfy-publish-viewaction-modal-label';
  static const String ntfyPublishViewActionInputUrlId =
      'ntfy-publish-viewaction-modal-url';
  static const String ntfyPublishViewActionInputClearId =
      'ntfy-publish-viewaction-modal-clear';

  // Publish broadcast action keys
  static const String ntfyPublishBroadcastActionInputLabelId =
      'ntfy-publish-broadcastaction-modal-label';
  static const String ntfyPublishBroadcastActionInputIntentId =
      'ntfy-publish-broadcastaction-modal-intent';
  static const String ntfyPublishBroadcastActionInputExtrasId =
      'ntfy-publish-broadcastaction-modal-extras';
  static const String ntfyPublishBroadcastActionInputClearId =
      'ntfy-publish-broadcastaction-modal-clear';

  // Publish http action keys
  static const String ntfyPublishHttpActionInputLabelId =
      'ntfy-publish-httpaction-modal-label';
  static const String ntfyPublishHttpActionInputUrlId =
      'ntfy-publish-httpaction-modal-url';
  static const String ntfyPublishHttpActionInputHeadersId =
      'ntfy-publish-httpaction-modal-headers';
  static const String ntfyPublishHttpActionInputBodyId =
      'ntfy-publish-httpaction-modal-body';
  static const String ntfyPublishHttpActionInputClearId =
      'ntfy-publish-httpaction-modal-clear';

  // <---- POLL COMPONENT IDs ---->

  // Poll root buttons
  static const String ntfyPollFetchButtonId = 'ntfy-poll-fetch-button';
  static const String ntfyPollFilterButtonId = 'ntfy-poll-filter-button';

  // Poll root priority select
  static const String ntfyPollPriorityId = 'ntfy-poll-priority-multiselect';

  // Poll filter modal keys
  static const String ntfyPollFilterInputMessageId =
      'ntfy-poll-filter-modal-message';
  static const String ntfyPollFilterInputTitleId =
      'ntfy-poll-filter-modal-title';
  static const String ntfyPollFilterInputTagsId = 'ntfy-poll-filter-modal-tags';
  static const String ntfyPollFilterInputIdId = 'ntfy-poll-filter-modal-id';

  Map<IUser, PublishableMessage> publishQueue = {};
  Map<IUser, PollWrapper> pollQueue = {};

  NtfyCommand() : _ntfyState = NtfyState();

  static ComponentMessageBuilder _messagesToDiscordComponents(
      List<MessageResponse> messages) {
    ComponentMessageBuilder leadMessage = ComponentMessageBuilder();
    List<EmbedBuilder> embedMessages = [];

    for (final message in messages.reversed) {
      embedMessages.add(_messageToDiscordBuilder(message));
    }
    if (embedMessages.length > 10) {
      leadMessage.content =
          'Cannot show ${embedMessages.length - 10} additional messages, please filter for them!';
      embedMessages.removeRange(10, embedMessages.length);
    }
    leadMessage.embeds = embedMessages.reversed.toList();
    if (leadMessage.embeds == null || leadMessage.embeds!.isEmpty) {
      leadMessage.content = 'There are no cached messages to display!';
    }
    return leadMessage;
  }

  static EmbedBuilder _messageToDiscordBuilder(MessageResponse message) {
    EmbedBuilder messageEmbed = EmbedBuilder()
      ..author = (EmbedAuthorBuilder()..name = message.topic)
      ..timestamp = message.time
      ..title = message.title
      ..description = message.message
      ..url = message.click?.toString()
      ..footer = (EmbedFooterBuilder()..text = message.id);

    if (message.priority != null) {
      messageEmbed.color = _priorityToDiscordColor(message.priority!);
    }

    if (message.tags != null) {
      messageEmbed.addField(name: 'Tags', content: message.tags!.join(','));
    }
    if (message.attachment != null) {
      messageEmbed.addField(
          name: message.attachment!.name, content: message.attachment!.url);
    }
    if (message.actions != null) {
      for (final action in message.actions!) {
        switch (action.action) {
          case ActionTypes.view:
            messageEmbed.addField(
                name: action.label, content: '(view action) ${action.url}');
            break;
          case ActionTypes.broadcast:
            messageEmbed.addField(
                name: action.label,
                content:
                    '(broadcast action) ${action.intent == null ? '' : 'intent: ${action.intent}'}. ${action.extras == null ? '' : 'extras: ${action.extras}'} ');
            break;
          case ActionTypes.http:
            messageEmbed.addField(
                name: action.label,
                content:
                    '(http action) ${action.method ?? 'POST'} ${action.url}. ${action.headers == null ? '' : 'headers: ${action.headers}'}. ${action.body == null ? '' : 'body: ${action.body}'}.');
            break;
        }
      }
    }

    return messageEmbed;
  }

  static DiscordColor _priorityToDiscordColor(PriorityLevels priorityLevel) {
    switch (priorityLevel) {
      case PriorityLevels.min:
        return DiscordColor.gray;
      case PriorityLevels.low:
        return DiscordColor.green;
      case PriorityLevels.none:
        return DiscordColor.none;
      case PriorityLevels.high:
        return DiscordColor.orange;
      case PriorityLevels.max:
        return DiscordColor.red;
    }
  }

  ChatGroup get ntfyGroup =>
      ChatGroup('ntfy', ProjectConstants.commandDefinitions['ntfy']!,
          children: [
            ChatCommand(
                'help',
                'Get info about ntfy',
                id('ntfy-help', (IChatContext context) {
                  EmbedBuilder aboutEmbed = EmbedBuilder()
                    ..title = 'About Ntfy'
                    //   ..description = 'How ntfy works'
                    ..author = ProjectConstants.stdEmbedAuthor
                    ..addField(
                        name: 'What can this do?',
                        content:
                            'This feature can send push notifications to phones, websites, and other internet connected devices using the ntfy software suite')
                    ..addField(
                        name: 'How do I get started?',
                        content:
                            'Read the below info, then use /ntfy publish and set the topic name to send your first message, and receive messages on the devices using the download links below')
                    ..addField(
                        name: 'Topics',
                        content:
                            'Each ntfy message is sent to a topic which the receiver decides to listen to. '
                            ' It can be named anything, but anyone can also use this topic name and send messages to you, so pick something hard to guess!')
                    ..addField(
                        name: 'Send a message',
                        content:
                            'Use /ntfy publish to send a message, inputting your topic.  A screen will be sent back askng for extra configurations.  '
                            'These basic options are self explanatory')
                    ..addField(
                        name: 'Receive a message on device',
                        content:
                            'To receive the message you send, use the web, android, or ios apps (or the API described on the site) and add your unique topic when prompted')
                    ..addField(
                        name: 'Receive a message on discord',
                        content:
                            'For the bot to reply to you with the message you subscribed to, use /ntfy subscribe with your topic.  '
                            'This can be done with multiple topics, just remember to CLEAR the list of topics when you are done')
                    ..addField(
                        name: 'More tips',
                        content:
                            'Messages are usually not stored for a long period of time, so your receiver must be on and setup BEFORE you publish. To get old messages, use the /ntfy poll option.  '
                            'NOTICE: Messages are not secured in any way, do not share sensitive data to be messaged');

                  ComponentMessageBuilder aboutResponse =
                      ComponentMessageBuilder()
                        ..embeds = [aboutEmbed]
                        ..addComponentRow(ComponentRowBuilder()
                          ..addComponent(LinkButtonBuilder(
                              'Web receiver', 'https://ntfy.sh/app'))
                          ..addComponent(LinkButtonBuilder('Android receiver',
                              'https://play.google.com/store/apps/details?id=io.heckel.ntfy'))
                          ..addComponent(LinkButtonBuilder('IOS receiver',
                              'https://apps.apple.com/us/app/ntfy/id1625396347'))
                          ..addComponent(LinkButtonBuilder(
                              'Ntfy Site', 'https://ntfy.sh/')));

                  context.respond(aboutResponse);
                })),
            ChatCommand(
                'publish',
                'Send a message',
                id('ntfy-publish', (IChatContext context,
                    @Description('Unique topic name')
                        String topic,
                    [@Description('schedule message to send at ISO 8601 date')
                        DateTime? schedSet,
                    @Description('cache values on server')
                        bool? cache,
                    @Description('use FCM to send messages')
                        bool? firebase]) async {
                  // add topic, cache, delay, and firebase to message
                  publishQueue[context.user] = PublishableMessage(topic: topic)
                    ..cache = cache
                    ..firebase = firebase
                    ..delay = schedSet;

                  ComponentMessageBuilder askOps = ComponentMessageBuilder()
                    ..content =
                        'Configure your message below: (can only click each button once).'
                    ..addComponentRow(ComponentRowBuilder()
                      ..addComponent(
                          MultiselectBuilder(ntfyPublishPrioritySelectId, [
                        MultiselectOptionBuilder('minimum', 'min'),
                        MultiselectOptionBuilder('low', 'low'),
                        MultiselectOptionBuilder('none', 'none')
                          ..description = 'Default',
                        MultiselectOptionBuilder('high', 'high'),
                        MultiselectOptionBuilder('maximum', 'max'),
                      ])
                            ..placeholder =
                                '(Optional) Select a priority level'))
                    ..addComponentRow(ComponentRowBuilder()
                      ..addComponent(ButtonBuilder('View',
                          ntfyPublishViewActionButtonId, ButtonStyle.danger))
                      ..addComponent(ButtonBuilder(
                          'Broadcast',
                          ntfyPublishBroadcastActionButtonId,
                          ButtonStyle.danger))
                      ..addComponent(ButtonBuilder('HTTP',
                          ntfyPublishHttpActionButtonId, ButtonStyle.danger)))
                    ..addComponentRow(ComponentRowBuilder()
                      ..addComponent(ButtonBuilder(
                          'Publish', ntfyPublishButtonId, ButtonStyle.primary))
                      ..addComponent(ButtonBuilder('Customize',
                          ntfyPublishOptsButtonId, ButtonStyle.primary))
                      ..addComponent(ButtonBuilder('Advanced',
                          ntfyPublishAdvOptsButtonId, ButtonStyle.secondary)));

                  await context.respond(askOps);

                  // handle priority selection, responding with confirmation TODO: fix select/T
                  context
                      .awaitSelection<MultiselectOptionBuilder>(
                          ntfyPublishPrioritySelectId)
                      .then((event) {
                    publishQueue[event.user]?.priority =
                        PriorityLevels.values.byName(event.selected.value);
                    event.respond(ComponentMessageBuilder()
                      ..content = 'Priority of ${event.selected.value} saved!'
                      ..componentRows = []);
                  });

                  // handle publish button, responding with message receipt returned by server
                  context
                      .awaitButtonPress(ntfyPublishButtonId)
                      .then((event) async {
                    await event.acknowledge();
                    final apiResponse =
                        await _ntfyState.publish(publishQueue[event.user]!);
                    event.respond(ComponentMessageBuilder()
                      ..embeds = [_messageToDiscordBuilder(apiResponse)]
                      ..content = 'How the message will look over discord:');
                    publishQueue.remove(event.user);
                  });

                  // handle customize (opts) button, responding with modal
                  context
                      .awaitButtonPress(ntfyPublishOptsButtonId)
                      .then((event) => event.getModal(
                            title: 'Create message',
                            components: [
                              (TextInputBuilder(ntfyPublishOptsInputMessageId,
                                  TextInputStyle.paragraph, 'Message')
                                ..required = false
                                ..placeholder = 'Enter message here...'),
                              (TextInputBuilder(ntfyPublishOptsInputTitleId,
                                  TextInputStyle.short, 'Title')
                                ..required = false
                                ..placeholder = 'Enter title here...'),
                              (TextInputBuilder(ntfyPublishOptsInputTagsId,
                                  TextInputStyle.short, 'Tags & Emojis')
                                ..required = false
                                ..placeholder =
                                    'Enter comma seperated list here...'),
                              (TextInputBuilder(
                                  ntfyPublishOptsInputAttachmentId,
                                  TextInputStyle.short,
                                  'URL of Attachment')
                                ..required = false
                                ..placeholder =
                                    'Enter URL of attachment here...'),
                              (TextInputBuilder(
                                  ntfyPublishOptsInputFilenameId,
                                  TextInputStyle.short,
                                  'Filename of attachment')
                                ..required = false
                                ..placeholder =
                                    'Enter filename of attachment here...'),
                            ],
                          ) // handle opts modal, responding with confirmation
                              .then((event) async {
                            publishQueue[event.user]?.message =
                                event[ntfyPublishOptsInputMessageId]
                                    .emptyToNull();
                            event[ntfyPublishOptsInputMessageId];
                            publishQueue[event.user]?.title =
                                event[ntfyPublishOptsInputTitleId]
                                    .emptyToNull();
                            publishQueue[event.user]?.tags =
                                event[ntfyPublishOptsInputTagsId]
                                    .emptyToNull()
                                    ?.split(',');

                            // if empty return null else return Uri.tryParse attachment url
                            publishQueue[event.user]?.attach = event[
                                            ntfyPublishOptsInputAttachmentId]
                                        .emptyToNull() ==
                                    null
                                ? null
                                : Uri.tryParse(
                                    event[ntfyPublishOptsInputAttachmentId]);

                            publishQueue[event.user]?.filename =
                                event[ntfyPublishOptsInputFilenameId]
                                    .emptyToNull();

                            await event.respond(MessageBuilder.content(
                                'Info saved.  Remember to click Publish to send your message!'));
                          }));

                  // handle advanced opts button, responding with modal
                  context
                      .awaitButtonPress(ntfyPublishAdvOptsButtonId)
                      .then((event) => event.getModal(
                            title: 'Advanced options',
                            components: [
                              (TextInputBuilder(ntfyPublishAdvOptsInputEmailId,
                                  TextInputStyle.short, 'Email')
                                ..required = false
                                ..placeholder =
                                    'Enter email to be notified here...'),
                              (TextInputBuilder(ntfyPublishAdvOptsInputClickId,
                                  TextInputStyle.short, 'Click URL')
                                ..required = false
                                ..placeholder =
                                    'Enter url to open when clicked on android...'),
                              (TextInputBuilder(ntfyPublishAdvOptsInputIconId,
                                  TextInputStyle.short, 'Icon URL')
                                ..required = false
                                ..placeholder =
                                    'Enter icon URL to see on android...'),
                              (TextInputBuilder(
                                  ntfyPublishAdvOptsInputAuthUsernameId,
                                  TextInputStyle.short,
                                  'Authorization')
                                ..required = false
                                ..placeholder = 'Enter username here...'),
                              (TextInputBuilder(
                                  ntfyPublishAdvOptsInputAuthPasswordId,
                                  TextInputStyle.short,
                                  ' ')
                                ..required = false
                                ..placeholder = 'Enter password here...'),
                            ],
                          ) // handle adv opts modal, responding with confirmation
                              .then((event) {
                            String extraProblems = '';

                            publishQueue[event.user]?.email =
                                event[ntfyPublishAdvOptsInputEmailId]
                                    .emptyToNull();

                            // if Uri.tryParse click url is null, add notif to extra problems
                            publishQueue[event.user]?.click = Uri.tryParse(
                                event[ntfyPublishAdvOptsInputClickId]);
                            if (publishQueue[event.user]?.click == null) {
                              extraProblems += 'Invalid click URL\n';
                            }

                            // if icon is empty return null else return Uri.tryParse icon
                            publishQueue[event.user]?.icon =
                                event[ntfyPublishAdvOptsInputIconId]
                                            .emptyToNull() ==
                                        null
                                    ? null
                                    : Uri.tryParse(
                                        event[ntfyPublishAdvOptsInputIconId]);

                            // if auth user + password not empty add auth
                            if (event[ntfyPublishAdvOptsInputAuthUsernameId]
                                    .isNotEmpty &&
                                event[ntfyPublishAdvOptsInputAuthUsernameId]
                                    .isNotEmpty) {
                              publishQueue[event.user]?.addAuthentication(
                                  username: event[
                                      ntfyPublishAdvOptsInputAuthUsernameId],
                                  password: event[
                                      ntfyPublishAdvOptsInputAuthUsernameId]);
                              // if one or other auth user + password not empty notif that auth set failed
                            } else if (event[
                                        ntfyPublishAdvOptsInputAuthUsernameId]
                                    .isNotEmpty ||
                                event[ntfyPublishAdvOptsInputAuthUsernameId]
                                    .isNotEmpty) {
                              extraProblems +=
                                  'Must give username and password for auth!\n';
                            }

                            event.respond(MessageBuilder.content(
                                '$extraProblems Advanced info saved.  Remember to click Publish to send your message!'));
                          }));

                  // handle view action button, responding with modal
                  context.awaitButtonPress(ntfyPublishViewActionButtonId).then(
                      (event) =>
                          event.getModal(title: 'Add view action', components: [
                            (TextInputBuilder(ntfyPublishViewActionInputLabelId,
                                TextInputStyle.short, 'Label')
                              ..required = true
                              ..placeholder = 'Enter action button label...'),
                            (TextInputBuilder(ntfyPublishViewActionInputUrlId,
                                TextInputStyle.short, 'URL')
                              ..required = true
                              ..placeholder = 'Enter URL to open...'),
                            (TextInputBuilder(ntfyPublishViewActionInputClearId,
                                TextInputStyle.short, 'Clear?')
                              ..required = false
                              ..placeholder =
                                  'default: false -- Clear notification after opened (true/false)...'),
                          ]) // handle view modal, responding with confirmation
                              .then((event) async {
                            String extraProblems = '';

                            Uri? url;
                            bool? clear;

                            // notif of url invalid
                            url = Uri.tryParse(
                                event[ntfyPublishViewActionInputUrlId]);
                            if (url == null) {
                              extraProblems += 'Invalid URL\n';
                            }

                            // parse clear to true or false, set to default false if failure
                            if (event[ntfyPublishViewActionInputClearId]
                                    .toLowerCase() ==
                                'true') {
                              clear = true;
                            } else if (event[ntfyPublishViewActionInputClearId]
                                    .toLowerCase() ==
                                'false') {
                              clear = false;
                            } else {
                              extraProblems +=
                                  'Invalid clear (not true or false)\n';
                              clear = false;
                            }

                            //  url not null (since valid one required), send confirmation, else send warning
                            if (url != null) {
                              publishQueue[event.user]?.addViewAction(
                                  label:
                                      event[ntfyPublishViewActionInputLabelId],
                                  url: url,
                                  clear: clear);

                              await event.respond(MessageBuilder.content(
                                  '$extraProblems View action saved.  Remember to click Publish to send your message!'));
                            } else {
                              await event.respond(MessageBuilder.content(
                                  '$extraProblems Failure: Please resend command and change your input to try again!'));
                            }
                          }));

                  // handle broadcast button, responding with modal
                  context
                      .awaitButtonPress(ntfyPublishBroadcastActionButtonId)
                      .then((event) => event
                              .getModal(title: 'Add broadcast action', components: [
                            (TextInputBuilder(
                                ntfyPublishBroadcastActionInputLabelId,
                                TextInputStyle.short,
                                'Label')
                              ..required = true
                              ..placeholder = 'Enter action button label...'),
                            (TextInputBuilder(
                                ntfyPublishBroadcastActionInputIntentId,
                                TextInputStyle.short,
                                'Intent')
                              ..required = false
                              ..placeholder =
                                  'Enter android intent name (default io.heckel.ntfy.USER_ACTION)...'),
                            (TextInputBuilder(
                                ntfyPublishBroadcastActionInputExtrasId,
                                TextInputStyle.short,
                                'Extras')
                              ..required = false
                              ..placeholder =
                                  'Enter android intent extras as <param>=<value>,<param>=<value>...'),
                            (TextInputBuilder(
                                ntfyPublishBroadcastActionInputClearId,
                                TextInputStyle.short,
                                'Clear?')
                              ..required = false
                              ..placeholder =
                                  'default: false -- Clear notification after opened (true/false)...'),
                          ]) // handle broadcast modal, responding with confirmation
                              .then((event) async {
                            String extraProblems = '';

                            // parse clear setting to default (false) and notif if not parsed
                            bool? clear;
                            if (event[ntfyPublishBroadcastActionInputClearId]
                                    .toLowerCase() ==
                                'true') {
                              clear = true;
                            } else if (event[
                                        ntfyPublishBroadcastActionInputClearId]
                                    .toLowerCase() ==
                                'false') {
                              clear = false;
                            } else {
                              extraProblems +=
                                  'Invalid clear (not true or false)\n';
                              clear = false;
                            }

                            // parse extras, warning if not parsed, null if not present
                            Map<String, String>? extras = {};
                            if (event[ntfyPublishBroadcastActionInputExtrasId]
                                .isNotEmpty) {
                              try {
                                for (final splitComma in event[
                                        ntfyPublishBroadcastActionInputExtrasId]
                                    .split(',')) {
                                  extras[splitComma.split('=').first] =
                                      splitComma.split('=').last;
                                }
                              } catch (_) {
                                extraProblems +=
                                    'Error parsing extras.  Ensure format is correct\n';
                                extras = null;
                              }
                            } else {
                              extras = null;
                            }

                            // add action with parsed
                            publishQueue[event.user]?.addBroadcastAction(
                              label:
                                  event[ntfyPublishBroadcastActionInputLabelId],
                              intent: event[
                                  ntfyPublishBroadcastActionInputIntentId],
                              extras: extras,
                              clear: clear,
                            );
                            await event.respond(MessageBuilder.content(
                                '$extraProblems View action saved.  Remember to click Publish to send your message!'));
                          }));

                  // handle http button, responding with modal
                  context.awaitButtonPress(ntfyPublishHttpActionButtonId).then(
                      (event) =>
                          event.getModal(title: 'Add HTTP action', components: [
                            (TextInputBuilder(ntfyPublishHttpActionInputLabelId,
                                TextInputStyle.short, 'Label')
                              ..required = true
                              ..placeholder = 'Enter action button label...'),
                            (TextInputBuilder(ntfyPublishHttpActionInputUrlId,
                                TextInputStyle.short, 'URL')
                              ..required = true
                              ..placeholder = 'Enter URL to open...'),
                            (TextInputBuilder(
                                ntfyPublishHttpActionInputHeadersId,
                                TextInputStyle.short,
                                'Headers')
                              ..required = false
                              ..placeholder =
                                  'Enter headers as <param>=<value>,<param>=<value>...'),
                            (TextInputBuilder(ntfyPublishHttpActionInputBodyId,
                                TextInputStyle.short, 'Body')
                              ..required = false
                              ..placeholder = 'Enter http body...'),
                            (TextInputBuilder(ntfyPublishHttpActionInputClearId,
                                TextInputStyle.short, 'Clear?')
                              ..required = false
                              ..placeholder =
                                  'default: false -- Clear notification after opened (true/false)...'),
                          ]) // handle http modal, responding with confirmation
                              .then((httpModalEvent) async {
                            // if url valid (since required) continue
                            if (Uri.tryParse(httpModalEvent[
                                    ntfyPublishHttpActionInputUrlId]) !=
                                null) {
                              String extraProblems = '';

                              // parse clear, if fail set to default (false) and notif
                              bool clear;
                              if (httpModalEvent[
                                          ntfyPublishHttpActionInputClearId]
                                      .toLowerCase() ==
                                  'true') {
                                clear = true;
                              } else if (httpModalEvent[
                                          ntfyPublishHttpActionInputClearId]
                                      .toLowerCase() ==
                                  'false') {
                                clear = false;
                              } else {
                                extraProblems +=
                                    'Invalid clear (not true or false)\n';
                                clear = false;
                              }

                              // parse headers, if empty null, if fail notif and set to null
                              Map<String, String>? headers = {};
                              if (httpModalEvent[
                                      ntfyPublishHttpActionInputHeadersId]
                                  .isNotEmpty) {
                                try {
                                  for (final splitComma in httpModalEvent[
                                          ntfyPublishHttpActionInputHeadersId]
                                      .split(',')) {
                                    headers[splitComma.split('=').first] =
                                        splitComma.split('=').last;
                                  }
                                } catch (_) {
                                  extraProblems +=
                                      'Error parsing headers.  Ensure format is correct\n';
                                  headers = null;
                                }
                              } else {
                                headers = null;
                              }

                              // handle http action select and add HTTP action, responding with confirmation TODO: fix select/T
                              httpModalEvent.getSelection<
                                      MultiselectOptionBuilder>(
                                  [
                                    MultiselectOptionBuilder('POST', 'POST')
                                      ..description = 'recommended',
                                    MultiselectOptionBuilder('PUT', 'PUT'),
                                    MultiselectOptionBuilder('GET', 'GET')
                                  ],
                                  MessageBuilder.content(
                                      '$extraProblems View action saved.  Choose the request method from the dropdown to finalize.')).then(
                                  (httpTypeSelect) {
                                // must use context.user here unfortunately
                                publishQueue[context.user]?.addHttpAction(
                                    label: httpModalEvent[
                                        ntfyPublishHttpActionInputLabelId],
                                    url: Uri.parse(httpModalEvent[
                                        ntfyPublishHttpActionInputUrlId]),
                                    headers: headers,
                                    method: MethodTypes.values
                                        .byName(httpTypeSelect.value),
                                    body: httpModalEvent[
                                        ntfyPublishHttpActionInputBodyId],
                                    clear: clear);
                                httpModalEvent.respond(MessageBuilder.content(
                                    'Method ${httpTypeSelect.label} saved!'));
                              });
                            } else {
                              await httpModalEvent.respond(MessageBuilder.content(
                                  'Please check your inputted URL and try again!'));
                            }
                          }));
                })),
            ChatCommand(
                'poll',
                'search recently sent messages',
                id('ntfy-poll', (
                  IChatContext context,
                  @Name('topic')
                  @Description('topic or topics to search by, comma separated')
                      String topics, [
                  @Description('more recent than this ISO 8601 date')
                      DateTime? since,
                  @Description('also show messages scheduled to sent')
                      bool? scheduled,
                ]) async {
                  if (topics.split(',').isNotEmpty) {
                    pollQueue[context.user] = PollWrapper(topics.split(','))
                      ..since = since
                      ..scheduled = scheduled;

                    ComponentMessageBuilder askOpts = ComponentMessageBuilder()
                      ..componentRows = [
                        ComponentRowBuilder()
                          ..addComponent(
                              MultiselectBuilder(ntfyPollPriorityId, [
                            MultiselectOptionBuilder('minimum', 'min'),
                            MultiselectOptionBuilder('low', 'low'),
                            MultiselectOptionBuilder('none', 'none'),
                            MultiselectOptionBuilder('high', 'high'),
                            MultiselectOptionBuilder('maximum', 'max'),
                          ])
                                ..placeholder =
                                    'Choose priority(s) to filter by'
                                ..maxValues = 4),
                        ComponentRowBuilder()
                          ..addComponent(ButtonBuilder('Fetch',
                              ntfyPollFetchButtonId, ButtonStyle.primary))
                          ..addComponent(ButtonBuilder('More filters',
                              ntfyPollFilterButtonId, ButtonStyle.secondary))
                      ];

                    context.respond(askOpts);

                    // handle poll filter button, responding with modal
                    context.awaitButtonPress(ntfyPollFilterButtonId).then(
                        (event) =>
                            event.getModal(title: 'Add filters', components: [
                              (TextInputBuilder(ntfyPollFilterInputMessageId,
                                  TextInputStyle.paragraph, 'By message')
                                ..placeholder =
                                    'Enter exact message to filter by...'
                                ..required = false),
                              (TextInputBuilder(ntfyPollFilterInputTitleId,
                                  TextInputStyle.short, 'By title')
                                ..placeholder =
                                    'Enter exact title to filter by...'
                                ..required = false),
                              (TextInputBuilder(ntfyPollFilterInputTagsId,
                                  TextInputStyle.short, 'By tag(s)')
                                ..placeholder =
                                    'Enter comma separated list of tags to filter by...'
                                ..required = false),
                              (TextInputBuilder(ntfyPollFilterInputIdId,
                                  TextInputStyle.short, 'By ID')
                                ..placeholder =
                                    'Enter exact message ID to filter by...'
                                ..required = false),
                            ]) // handle filter modal, responding with confirmation
                                .then((event) {
                              if (pollQueue[event.user]?.filters != null) {
                                pollQueue[event.user]?.filters
                                  ?..message =
                                      event[ntfyPollFilterInputMessageId]
                                          .emptyToNull()
                                  ..title = event[ntfyPollFilterInputTitleId]
                                      .emptyToNull()
                                  ..tags = event[ntfyPollFilterInputTagsId]
                                      .emptyToNull()
                                      ?.split(',')
                                  ..id = event[ntfyPollFilterInputIdId]
                                      .emptyToNull();
                              } else {
                                pollQueue[event.user]?.filters = FilterOptions(
                                    message: event[ntfyPollFilterInputMessageId]
                                        .emptyToNull(),
                                    title: event[ntfyPollFilterInputTitleId]
                                        .emptyToNull(),
                                    tags: event[ntfyPollFilterInputTagsId]
                                        .emptyToNull()
                                        ?.split(','),
                                    id: event[ntfyPollFilterInputIdId]
                                        .emptyToNull());
                              }
                              event.respond(
                                  MessageBuilder.content('Filters saved'));
                            }));
                    // handle priorities multiselect, responding with confirmation TODO: fix select/T
                    context
                        .awaitMultiSelection<MultiselectOptionBuilder>(
                      ntfyPollPriorityId,
                    )
                        .then((event) {
                      final priorities = event.selected
                          .map<PriorityLevels>(
                              (e) => PriorityLevels.values.byName(e.value))
                          .toList();
                      if (pollQueue[event.user]?.filters != null) {
                        pollQueue[event.user]?.filters?.priority = priorities;
                      } else {
                        pollQueue[event.user]?.filters =
                            FilterOptions(priority: priorities);
                      }
                      event.respond(
                          MessageBuilder.content('Priority(s) saved!'));
                    });

                    // handle fetch button, responding with the results of the server poll
                    context
                        .awaitButtonPress(ntfyPollFetchButtonId)
                        .then((event) async {
                      if (pollQueue[event.user] != null) {
                        final polled =
                            await _ntfyState.poll(pollQueue[event.user]!);

                        event.respond(_messagesToDiscordComponents(polled));
                        pollQueue.remove(event.user);
                      }
                    });
                  } else {
                    context.respond(MessageBuilder.content(
                        'Could not parse topics, please try again.'));
                  }
                })),
            ChatCommand(
                'subscribe',
                'Configure bot responses when a message is sent',
                id('ntfy-subscribe', (IChatContext context) {
                  context.respond(MessageBuilder.content(
                      'This functionality is not yet available.  Please see /ntfy info to setup notifications for a message.'));
                }))
          ]);
}

extension EmptyCheck on String {
  String? emptyToNull() {
    return isNotEmpty ? this : null;
  }
}

class PollWrapper {
  List<String> topics;

  DateTime? since;

  bool? scheduled;

  FilterOptions? filters;

  PollWrapper(this.topics);
}
