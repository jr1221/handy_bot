import 'package:nyxx/nyxx.dart' show IUser;
import 'package:chess/chess.dart';

class ChessState {
  final Chess _chessGame = Chess();

  IUser? _whitePlayer;
  IUser? _blackPlayer;

  String _moveToString(Move move) {
    return '${move.piece.prettyName()} from ${move.fromAlgebraic} to ${move.toAlgebraic}';
  }

  List<String> _currentIssues() {
    List<String> currentIssues = [];
    if (_chessGame.in_check) {
      currentIssues.add('\u{2714} In check'); // Check mark
    }
    if (_chessGame.in_checkmate) {
      currentIssues
          .removeLast(); // get rid of check, as checkis true when checkmate is always
      currentIssues.add('\u{2611} In checkmate'); // Check mark with box
    }
    if (_chessGame.in_draw) {
      currentIssues.add('\u{1F6AB} In draw'); // no entry
    }
    if (_chessGame.in_stalemate) {
      currentIssues.add('\u{1F6AB} In stalemate'); // no entry
    }
    if (_chessGame.in_threefold_repetition) {
      currentIssues.add('\u{1F6AB} In threefold repetition'); // no entry
    }
    if (_chessGame.insufficient_material) {
      currentIssues.add('\u{1F6AB} Not enough pieces to continue'); // no entry
    }
    return currentIssues;
  }

  String _endTurnMessage() {
    StringBuffer messageBack = StringBuffer();

    if (_chessGame.game_over) {
      messageBack.writeln('\u{274C} Game Over!!'); // Red cross mark
      if (_chessGame.turn == Chess.WHITE) {
        messageBack.writeln(
            '\u{27A1}${_whitePlayer?.username}\u{1F532} won'); // Right arrow, white small-medium square
      } else {
        messageBack.writeln(
            '\u{27A1}${_whitePlayer?.username}\u{1F533} won'); // Right arrow, black small-medium square

      }
      messageBack.writeln('Use `start` to start a new game');
    } else if (_whitePlayer != null) {
      if (_chessGame.turn == Chess.WHITE) {
        messageBack.writeln(
            'It is ${_whitePlayer?.username}\'s\u{1F532} turn'); // white square
      } else {
        messageBack.writeln(
            'It is ${_blackPlayer?.username}\'s\u{1F533} turn'); // black square
      }
    } else {
      messageBack.writeln('Use `start` to start a new game');
    }

    final List<String> issues = _currentIssues();
    if (issues.isNotEmpty) {
      messageBack.writeAll(issues, '\n');
    }

    return messageBack.toString();
  }

//  bool get gameOver => _chess.game_over;

  String gameBoard() {
    StringBuffer messageBack = StringBuffer();
    messageBack.writeln('```${_chessGame.ascii}```');
    messageBack.writeln(_endTurnMessage());
    return messageBack.toString();
  }

  String history() {
    StringBuffer messageBack = StringBuffer();
    for (final state in _chessGame.history) {
      if (state.turn == Chess.WHITE) {
        messageBack.writeln(
            '\u{1F532}${state.move_number}: ${_moveToString(state.move)}'); // white square
      } else {
        messageBack.writeln(
            '\u{1F533}${state.move_number}: ${_moveToString(state.move)}'); // black square
      }
    }
    return messageBack.toString();
  }

  String getMoves(ChessSquare? certainSquare) {
    StringBuffer messageBack = StringBuffer();
    List<Move> possibleMoves;
    if (certainSquare != null) {
      possibleMoves = _chessGame
              .moves({"asObjects": true, "square": certainSquare.toString()})
          as List<Move>;
    } else {
      possibleMoves = _chessGame.moves({"asObjects": true}) as List<Move>;
    }

    if (possibleMoves.isNotEmpty) {
      if (certainSquare != null) {
        messageBack.writeln(
            '\u{2B07} Possible moves from ${certainSquare.toString()}:'); // down arrow
      } else {
        messageBack.writeln('\u{2B07} All possible moves:'); // down arrow
      }
      for (Move aMove in possibleMoves) {
        messageBack.writeln(_moveToString(aMove));
      }
    } else {
      if (certainSquare != null) {
        messageBack.writeln(
            '\u{274C} No moves from ${certainSquare.toString()}!'); // cross mark
      } else {
        messageBack.writeln('\u{274C} No moves!'); // cross mark
      }
    }
    messageBack.writeln(_endTurnMessage());
    return messageBack.toString();
  }

  String start(IUser whitePlayer, IUser blackPlayer) {
    _whitePlayer = whitePlayer;
    _blackPlayer = blackPlayer;

    StringBuffer messageBack = StringBuffer();
    _chessGame.reset();
    messageBack.writeln('Starting a new game...');
    messageBack.writeln(
        '(UPPERCASE) ${_whitePlayer?.username} \u{1F532}  \u{1F19A}  \u{1F533} ${_blackPlayer?.username} (lowercase)'); // white square, VS, black square
    messageBack.writeln(_endTurnMessage());
    return messageBack.toString();
  }

  String move(ChessSquare fromCmd, ChessSquare toCmd, String? promotion) {
    StringBuffer messageBack = StringBuffer();
    bool didMove = false;
    if (promotion == null) {
      didMove = _chessGame.move({
        "from": fromCmd.toString(),
        "to": toCmd.toString(),
      });
    } else {
      didMove = _chessGame.move({
        "from": fromCmd.toString(),
        "to": toCmd.toString(),
        "promotion": promotion, // TODO: check if promotion still works
      });
    }
    if (didMove) {
      messageBack.writeln('\u{2705} Move success'); // green check mark
      messageBack.writeln('```${_chessGame.ascii}```');
      messageBack.writeln(_moveToString(_chessGame.history.last.move));
    } else {
      messageBack.writeln('\u{274C} Move unsuccessful!'); // cross mark
    }
    messageBack.writeln(_endTurnMessage());
    return messageBack.toString();
  }

  bool validateTurn(IUser moveTry) {
    try {
      if (((moveTry.id == _whitePlayer?.id) &&
              (_chessGame.turn == Chess.WHITE)) ||
          ((moveTry.id == _blackPlayer?.id) &&
              (_chessGame.turn == Chess.BLACK))) {
        return true;
      }
    } catch (e) {
      print('Validate turn error: $e');
    }
    return false;
  }
}

class ChessSquare {
  final String row;
  final int col;

  ChessSquare({required this.row, required this.col});

  @override
  String toString() {
    return '$row$col';
  }
}

extension PrettyPieceNaming on PieceType {
  String prettyName() {
    switch (name.toString()) {
      case 'b':
        return 'BISHOP';
      case 'k':
        return 'KING';
      case 'q':
        return 'QUEEN';
      case 'p':
        return 'PAWN';
      case 'r':
        return 'ROOK';
      case 'n':
        return 'KNIGHT';
      default:
        throw UnimplementedError('Piece ${name.toString()} doesn\'t exist');
    }
  }
}
