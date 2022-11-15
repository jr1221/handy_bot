import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import '../../project_constants.dart';
import 'chess_state.dart';

class ChessCommand {
  final ChessState _chess;

  ChessCommand() : _chess = ChessState();

  static const String wrongUserCheckId = 'wrong-check-user';

  static const List<String> squareLetters = [
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h'
  ];

  ChatGroup get chessGroup => ChatGroup(
        'chess',
        ProjectConstants.commandDefinitions['chess']!,
        children: [
          ChatCommand(
              'board',
              'Show the current situation',
              id('chess-board', (IChatContext context) {
                context.respond(MessageBuilder.content(_chess.gameBoard()));
              })),
          ChatCommand(
              'get-moves',
              'Get a list of all moves, optionally from a certain square',
              id('chess-get-moves', (IChatContext context,
                  [@Name('square')
                  @Description('Certain square to get options for')
                      ChessSquare? certainSquare]) {
                context.respond(
                    MessageBuilder.content(_chess.getMoves(certainSquare)));
              })),
          ChatCommand(
              'start',
              'Start a new game with 2 users',
              id('chess-start', (IChatContext context,
                  @Name('white')
                  @Description('White player')
                      IMember whitePlayer,
                  @Name('black')
                  @Description('Black player')
                      IMember blackPlayer) async {
                context.respond(MessageBuilder.content(_chess.start(
                    await whitePlayer.user.getOrDownload(),
                    await blackPlayer.user.getOrDownload())));
              })),
          ChatCommand(
              'move',
              'Move your piece',
              id('chess-move', (IChatContext context,
                  @Name('from')
                  @Description('Square the piece is on')
                      ChessSquare fromCmd,
                  @Name('to')
                  @Description('Square the piece will go to')
                      ChessSquare toCmd,
                  [@Name('promote')
                  @Description('Piece letter to promote pawn to')
                      String? promotion]) {
                context.respond(MessageBuilder.content(
                    _chess.move(fromCmd, toCmd, promotion)));
              }),
              singleChecks: [_turnMoveCheck])
        ],
      );

  final Converter<ChessSquare> squareConverter = Converter<ChessSquare>(
    (viewRaw, context) {
      String view = viewRaw.getQuotedWord();
      try {
        view = view.trim().toLowerCase();
        if (!squareLetters.contains(view.substring(0, 1))) {
          throw Exception;
        }
        if ((!(int.parse(view.substring(1, 2)) >= 1)) ||
            (!(int.parse(view.substring(1, 2)) <= 8))) {
          throw Exception;
        }
        return ChessSquare(
            row: view.substring(0, 1), col: int.parse(view.substring(1, 2)));
      } catch (_) {
        return null;
      }
    },
  );

  Check get _turnMoveCheck =>
      Check(((context) => _chess.validateTurn(context.user)),
          name: wrongUserCheckId, allowsDm: false);
}
