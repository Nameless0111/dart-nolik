import 'dart:io';
import 'dart:math';

void main() {
  print('Добро пожаловать в Крестики-нолики (консоль)!');

  while (true) {
    final mode = _chooseMode();
    _playGame(modeAgainstRobot: mode == 2);

    stdout.write('\nСыграть ещё раз? (y/n): ');
    final again = stdin.readLineSync()?.trim().toLowerCase();
    if (again != 'y' && again != 'yes') {
      print('Спасибо за игру!');
      break;
    }
  }
}

int _chooseMode() {
  while (true) {
    print('\nВыберите режим игры:');
    print('1. Игрок против игрока');
    print('2. Игрок против робота');
    print('3. Выход');
    stdout.write('Ваш выбор: ');
    final choice = stdin.readLineSync()?.trim();
    switch (choice) {
      case '1':
        return 1;
      case '2':
        return 2;
      case '3':
        exit(0);
      default:
        print('Неверный выбор. Введите 1, 2 или 3.');
    }
  }
}

void _playGame({required bool modeAgainstRobot}) {
  final size = _readBoardSize();
  final game = TicTacToe(size: size);

  final isXFirst = Random().nextBool();
  var current = isXFirst ? 'X' : 'O';
  print('\nСтарт игры: поле ${size}x$size. Первый ход: $current');
  if (modeAgainstRobot) {
    print('Режим: Вы (X) против Робота (O)');
  }

  game.printBoard();

  while (true) {
    int row, col;

    if (modeAgainstRobot && current == 'O') {
      final mv = game.chooseRobotMove();
      row = mv[0];
      col = mv[1];
      print('\nХод робота (O): ${row + 1} ${col + 1}');
    } else {
      final move = _readHumanMove(game, current);
      row = move[0];
      col = move[1];
    }

    game.place(row, col, current);
    game.printBoard();

    final result = game.checkEnd();
    if (result != null) {
      if (result == 'draw') {
        print('\nНичья! Все клетки заняты.');
      } else {
        print('\nПобеда игрока $result!');
      }
      return;
    }

    current = current == 'X' ? 'O' : 'X';
  }
}

int _readBoardSize() {
  while (true) {
    stdout.write('\nВведите размер поля (3-9): ');
    final s = stdin.readLineSync()?.trim();
    final n = int.tryParse(s ?? '');
    if (n != null && n >= 3 && n <= 9) return n;
    print('Некорректный ввод. Введите целое число от 3 до 9.');
  }
}

List<int> _readHumanMove(TicTacToe game, String player) {
  while (true) {
    stdout.write('\nХод игрока $player. Введите строку и столбец (например: 1 2): ');
    final parts = (stdin.readLineSync() ?? '').trim().split(RegExp(r'\s+'));
    if (parts.length != 2) {
      print('Нужно ввести два числа через пробел.');
      continue;
    }
    final r = int.tryParse(parts[0]);
    final c = int.tryParse(parts[1]);
    if (r == null || c == null) {
      print('Некорректные числа.');
      continue;
    }
    final row = r - 1;
    final col = c - 1;
    if (!game.isValid(row, col)) {
      print('Некорректный ход. Клетка занята или вне поля.');
      continue;
    }
    return [row, col];
  }
}

class TicTacToe {
  TicTacToe({required this.size})
      : board = List.generate(size, (_) => List.filled(size, '.'));

  final int size;
  final List<List<String>> board;

  void printBoard() {
    final header = List.generate(size, (i) => '${i + 1}').join(' ');
    print('\n   $header');
    for (var i = 0; i < size; i++) {
      print('${i + 1}  ' + board[i].join(' '));
    }
  }

  bool isValid(int row, int col) {
    return row >= 0 && row < size && col >= 0 && col < size && board[row][col] == '.';
  }

  void place(int row, int col, String player) {
    board[row][col] = player;
  }

  String? checkEnd() {
    if (_hasWin('X')) return 'X';
    if (_hasWin('O')) return 'O';
    if (_isFull()) return 'draw';
    return null;
  }

  bool _isFull() => board.every((r) => r.every((c) => c != '.'));

  // Победа определяется как любые ТРИ подряд (по горизонтали, вертикали, обе диагонали)
  bool _hasWin(String p) {
    const need = 3;

    bool inBounds(int r, int c) => r >= 0 && r < size && c >= 0 && c < size;

    // Проверяем все клетки как старт последовательности длиной 3 в 4 направлениях
    const dirs = [
      [0, 1], // горизонталь
      [1, 0], // вертикаль
      [1, 1], // диагональ ↘
      [1, -1], // диагональ ↙
    ];

    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board[r][c] != p) continue;
        for (final d in dirs) {
          final dr = d[0], dc = d[1];
          var ok = true;
          for (var k = 1; k < need; k++) {
            final rr = r + dr * k;
            final cc = c + dc * k;
            if (!inBounds(rr, cc) || board[rr][cc] != p) {
              ok = false;
              break;
            }
          }
          if (ok) return true;
        }
      }
    }
    return false;
  }

  List<int> chooseRobotMove() {
    // 1) Попробовать выиграть ходом O
    final win = _bestSingleStep('O');
    if (win != null) return win;

    // 2) Заблокировать победу X
    final block = _bestSingleStep('X');
    if (block != null) return block;

    // 3) Преференции: центр (если нечётный размер), затем углы, затем любые свободные
    final prefs = <List<int>>[];

    // центр
    if (size.isOdd) {
      final m = size ~/ 2;
      if (board[m][m] == '.') prefs.add([m, m]);
    }

    // углы
    final corners = [
      [0, 0],
      [0, size - 1],
      [size - 1, 0],
      [size - 1, size - 1],
    ];
    for (final c in corners) {
      if (board[c[0]][c[1]] == '.') prefs.add(c);
    }

    // остальные
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board[r][c] == '.') prefs.add([r, c]);
      }
    }

    if (prefs.isEmpty) return [0, 0];
    return prefs[Random().nextInt(prefs.length)];
  }

  // Ищет ход, который завершает три в ряд для указанного игрока
  List<int>? _bestSingleStep(String player) {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board[r][c] != '.') continue;
        board[r][c] = player;
        final won = _hasWin(player);
        board[r][c] = '.';
        if (won) return [r, c];
      }
    }
    return null;
  }
}

// (удалены шаблонные строки с повторным main и лишним import)
