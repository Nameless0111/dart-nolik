import 'dart:io';
import 'dart:math';

// Модель корабля
class Ship {
  final String name;
  final int size;
  final List<Position> positions;
  final bool isHorizontal;
  bool isDestroyed;

  Ship({
    required this.name,
    required this.size,
    required this.positions,
    required this.isHorizontal,
    this.isDestroyed = false,
  });

  // Проверка, попал ли выстрел в корабль
  bool isHit(Position position) {
    return positions.any((pos) => pos.x == position.x && pos.y == position.y);
  }

  // Проверка, уничтожен ли корабль
  bool checkDestroyed(List<Position> hitPositions) {
    isDestroyed = positions.every((pos) => 
        hitPositions.any((hit) => hit.x == pos.x && hit.y == pos.y));
    return isDestroyed;
  }
}

// Позиция на поле
class Position {
  final int x;
  final int y;

  Position(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

// Игровое поле
class GameBoard {
  final int size;
  late List<List<String>> board;
  final List<Ship> ships;
  final List<Position> shots;

  GameBoard(this.size) : ships = [], shots = [] {
    board = List.generate(size, (_) => List.filled(size, ' '));
  }

  // Размещение корабля
  bool placeShip(Ship ship) {
    // Проверка, что корабль помещается на поле
    for (var pos in ship.positions) {
      if (pos.x < 0 || pos.x >= size || pos.y < 0 || pos.y >= size) {
        return false;
      }
      if (board[pos.x][pos.y] != ' ') {
        return false;
      }
    }

    // Проверка, что корабли не соприкасаются
    for (var pos in ship.positions) {
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          int newX = pos.x + dx;
          int newY = pos.y + dy;
          if (newX >= 0 && newX < size && newY >= 0 && newY < size) {
            if (board[newX][newY] != ' ') {
              return false;
            }
          }
        }
      }
    }

    // Размещение корабля
    for (var pos in ship.positions) {
      board[pos.x][pos.y] = 'S';
    }
    ships.add(ship);
    return true;
  }

  // Выстрел
  String shoot(Position position) {
    if (position.x < 0 || position.x >= size || position.y < 0 || position.y >= size) {
      return 'out_of_bounds';
    }

    if (shots.any((shot) => shot.x == position.x && shot.y == position.y)) {
      return 'already_shot';
    }

    shots.add(position);

    for (var ship in ships) {
      if (ship.isHit(position)) {
        board[position.x][position.y] = 'X';
        ship.checkDestroyed(shots);
        return ship.isDestroyed ? 'destroyed' : 'hit';
      }
    }

    board[position.x][position.y] = 'O';
    return 'miss';
  }

  // Проверка, все ли корабли уничтожены
  bool allShipsDestroyed() {
    return ships.every((ship) => ship.isDestroyed);
  }

  // Отображение поля (для игрока)
  void displayBoard({bool hideShips = false}) {
    print('   ${List.generate(size, (i) => String.fromCharCode(65 + i)).join(' ')}');
    for (int i = 0; i < size; i++) {
      String row = '${i + 1} ';
      for (int j = 0; j < size; j++) {
        String cell = board[i][j];
        if (hideShips && cell == 'S') {
          cell = ' ';
        }
        row += ' $cell';
      }
      print(row);
    }
  }

  // Отображение поля противника (скрывает корабли)
  void displayOpponentBoard() {
    print('   ${List.generate(size, (i) => String.fromCharCode(65 + i)).join(' ')}');
    for (int i = 0; i < size; i++) {
      String row = '${i + 1} ';
      for (int j = 0; j < size; j++) {
        String cell = board[i][j];
        if (cell == 'S') {
          cell = ' ';
        }
        row += ' $cell';
      }
      print(row);
    }
  }
}

// Игрок
class Player {
  final String name;
  final GameBoard board;
  final bool isBot;

  Player({
    required this.name,
    required this.board,
    this.isBot = false,
  });

  // Размещение кораблей игроком
  void placeShips() {
    if (isBot) {
      _placeShipsBot();
      return;
    }

    print('\n=== РАЗМЕЩЕНИЕ КОРАБЛЕЙ ===');
    print('Игрок: $name');
    print('Размер поля: ${board.size}x${board.size}');

    List<Map<String, int>> shipConfigs = _getShipConfigs();
    
    for (var config in shipConfigs) {
      int count = config['count']!;
      int size = config['size']!;
      
      for (int i = 0; i < count; i++) {
        bool placed = false;
        while (!placed) {
          board.displayBoard();
          print('\nРазмещение корабля размером $size палуб(ы)');
          print('Осталось разместить: ${count - i} кораблей');
          
          Position? startPos = _getPositionInput('Введите начальную координату (например, A1):');
          if (startPos == null) continue;
          
          String direction = _getDirectionInput();
          if (direction.isEmpty) continue;
          
          List<Position> positions = _calculateShipPositions(startPos, size, direction == 'h');
          Ship ship = Ship(
            name: 'Корабль $size палуб',
            size: size,
            positions: positions,
            isHorizontal: direction == 'h',
          );
          
          if (board.placeShip(ship)) {
            print('Корабль размещен успешно!');
            placed = true;
          } else {
            print('Нельзя разместить корабль в этом месте!');
          }
        }
      }
    }
  }

  // Размещение кораблей ботом
  void _placeShipsBot() {
    List<Map<String, int>> shipConfigs = _getShipConfigs();
    Random random = Random();
    
    for (var config in shipConfigs) {
      int count = config['count']!;
      int size = config['size']!;
      
      for (int i = 0; i < count; i++) {
        bool placed = false;
        int attempts = 0;
        
        while (!placed && attempts < 100) {
          int x = random.nextInt(board.size);
          int y = random.nextInt(board.size);
          bool isHorizontal = random.nextBool();
          
          List<Position> positions = _calculateShipPositions(Position(x, y), size, isHorizontal);
          Ship ship = Ship(
            name: 'Корабль $size палуб',
            size: size,
            positions: positions,
            isHorizontal: isHorizontal,
          );
          
          if (board.placeShip(ship)) {
            placed = true;
          }
          attempts++;
        }
      }
    }
  }

  // Получение конфигурации кораблей в зависимости от размера поля
  List<Map<String, int>> _getShipConfigs() {
    if (board.size == 8) {
      return [
        {'count': 1, 'size': 4},
        {'count': 2, 'size': 3},
        {'count': 3, 'size': 2},
        {'count': 4, 'size': 1},
      ];
    } else if (board.size == 10) {
      return [
        {'count': 1, 'size': 4},
        {'count': 2, 'size': 3},
        {'count': 3, 'size': 2},
        {'count': 4, 'size': 1},
      ];
    } else if (board.size == 14) {
      return [
        {'count': 2, 'size': 4},
        {'count': 3, 'size': 3},
        {'count': 4, 'size': 2},
        {'count': 5, 'size': 1},
      ];
    }
    return [];
  }

  // Выстрел игрока (нельзя стрелять в уже обстрелянные клетки)
  Position? makeMove(List<Position> forbiddenShots) {
    if (isBot) {
      return _makeBotMove(forbiddenShots);
    }

    print('\n=== ХОД ИГРОКА $name ===');
    while (true) {
      Position? pos = _getPositionInput('Введите координату для выстрела (например, A1):');
      if (pos == null) continue;
      final alreadyShot = forbiddenShots.any((p) => p == pos);
      if (alreadyShot) {
        print('Вы уже стреляли в эту клетку. Выберите другую.');
        continue;
      }
      return pos;
    }
  }

  // Выстрел бота (только по новым клеткам и не рядом с уничтоженными кораблями)
  Position? _makeBotMove(List<Position> forbiddenShots) {
    Random random = Random();
    // Теоретически максимум size*size попыток достаточно
    for (int attempts = 0; attempts < board.size * board.size; attempts++) {
      int x = random.nextInt(board.size);
      int y = random.nextInt(board.size);
      final pos = Position(x, y);
      final alreadyShot = forbiddenShots.any((p) => p == pos);
      if (alreadyShot) continue;
      
      return pos;
    }
    return null; // На всякий случай, если всё поле уже обстреляно
  }

  // Ввод позиции
  Position? _getPositionInput(String prompt) {
    while (true) {
      print(prompt);
      try {
        String? input = stdin.readLineSync()?.toLowerCase().trim();
        if (input == null || input.isEmpty) continue;
        
        if (input.length >= 2) {
          String letter = input[0];
          String number = input.substring(1);
          
          if (letter.codeUnitAt(0) >= 97 && letter.codeUnitAt(0) <= 122) {
            int x = letter.codeUnitAt(0) - 97;
            int? y = int.tryParse(number);
            if (y != null && y >= 1 && y <= board.size) {
              return Position(y - 1, x);
            }
          }
        }
        print('Неверный формат координат!');
      } catch (e) {
        print('Ошибка ввода. Попробуйте еще раз.');
        return null;
      }
    }
  }

  // Ввод направления
  String _getDirectionInput() {
    while (true) {
      print('Выберите направление (Н - горизонтально, V - вертикально):');
      try {
        String? input = stdin.readLineSync()?.toLowerCase().trim();
        if (input == null || input.isEmpty) continue;
        
        if (input == 'h' || input == 'н') return 'h';
        if (input == 'v' || input == 'в') return 'v';
        
        print('Введите H или V!');
      } catch (e) {
        print('Ошибка ввода. Используется горизонтальное направление.');
        return 'h';
      }
    }
  }

  // Расчет позиций корабля
  List<Position> _calculateShipPositions(Position start, int size, bool isHorizontal) {
    List<Position> positions = [];
    for (int i = 0; i < size; i++) {
      if (isHorizontal) {
        positions.add(Position(start.x, start.y + i));
      } else {
        positions.add(Position(start.x + i, start.y));
      }
    }
    return positions;
  }
}

// Игра
class Game {
  late Player player1;
  late Player player2;
  late int boardSize;
  bool isPlayer1Turn = true;

  void start() {
    print('=== МОРСКОЙ БОЙ ===');
    _selectGameMode();
    _selectBoardSize();
    _createPlayers();
    _placeShips();
    _playGame();
  }

  void _selectGameMode() {
    while (true) {
      print('\nВыберите режим игры:');
      print('1. Игрок против игрока');
      print('2. Игрок против бота');
      try {
        String? choice = stdin.readLineSync();
        
        if (choice == '1') {
          _gameMode = 'pvp';
          break;
        } else if (choice == '2') {
          _gameMode = 'pve';
          break;
        }
        print('Выберите 1 или 2!');
      } catch (e) {
        print('Ошибка ввода. Попробуйте еще раз.');
        _gameMode = 'pvp'; // По умолчанию
        break;
      }
    }
  }

  void _selectBoardSize() {
    while (true) {
      print('\nВыберите размер поля:');
      print('1. 8x8 (стандартное)');
      print('2. 10x10 (большое)');
      print('3. 14x14 (очень большое)');
      try {
        String? choice = stdin.readLineSync();
        
        if (choice == '1') {
          boardSize = 8;
          break;
        } else if (choice == '2') {
          boardSize = 10;
          break;
        } else if (choice == '3') {
          boardSize = 14;
          break;
        }
        print('Выберите 1, 2 или 3!');
      } catch (e) {
        print('Ошибка ввода. Используется стандартный размер 8x8.');
        boardSize = 8;
        break;
      }
    }
  }

  void _createPlayers() {
    if (_gameMode == 'pvp') {
      print('\nВведите имя первого игрока:');
      String name1;
      try {
        name1 = stdin.readLineSync() ?? 'Игрок 1';
      } catch (e) {
        name1 = 'Игрок 1';
      }
      
      print('Введите имя второго игрока:');
      String name2;
      try {
        name2 = stdin.readLineSync() ?? 'Игрок 2';
      } catch (e) {
        name2 = 'Игрок 2';
      }
      
      player1 = Player(name: name1, board: GameBoard(boardSize));
      player2 = Player(name: name2, board: GameBoard(boardSize));
    } else {
      print('\nВведите ваше имя:');
      String playerName;
      try {
        playerName = stdin.readLineSync() ?? 'Игрок';
      } catch (e) {
        playerName = 'Игрок';
      }
      
      player1 = Player(name: playerName, board: GameBoard(boardSize));
      player2 = Player(name: 'Бот', board: GameBoard(boardSize), isBot: true);
    }
  }

  void _placeShips() {
    player1.placeShips();
    _clearConsole();
    player2.placeShips();
    _clearConsole();
  }

  void _playGame() {
    while (!player1.board.allShipsDestroyed() && !player2.board.allShipsDestroyed()) {
      Player currentPlayer = isPlayer1Turn ? player1 : player2;
      Player opponent = isPlayer1Turn ? player2 : player1;
      
      if (!currentPlayer.isBot) {
        _clearConsole();
        print('\n=== ХОД ИГРОКА ${currentPlayer.name} ===');
        print('Ваше поле:');
        currentPlayer.board.displayBoard();
        print('\nПоле противника:');
        opponent.board.displayOpponentBoard();
      }
      
      // Для бота передаем дополнительную информацию об уничтоженных кораблях
      List<Position> forbiddenShots = List.from(opponent.board.shots);
      if (currentPlayer.isBot) {
        // Добавляем клетки рядом с уничтоженными кораблями противника
        for (var ship in opponent.board.ships) {
          if (ship.isDestroyed) {
            for (var shipPos in ship.positions) {
              // Добавляем все клетки в радиусе 1 от уничтоженного корабля
              for (int dx = -1; dx <= 1; dx++) {
                for (int dy = -1; dy <= 1; dy++) {
                  int newX = shipPos.x + dx;
                  int newY = shipPos.y + dy;
                  if (newX >= 0 && newX < opponent.board.size && 
                      newY >= 0 && newY < opponent.board.size) {
                    forbiddenShots.add(Position(newX, newY));
                  }
                }
              }
            }
          }
        }
      }
      
      Position? shot = currentPlayer.makeMove(forbiddenShots);
      if (shot == null) continue;
      
      String result = opponent.board.shoot(shot);
      
      if (!currentPlayer.isBot) {
        print('\nРезультат выстрела:');
        switch (result) {
          case 'hit':
            print('Попадание!');
            break;
          case 'destroyed':
            print('Корабль уничтожен!');
            break;
          case 'miss':
            print('Промах!');
            break;
          case 'already_shot':
            print('Вы уже стреляли в эту клетку!');
            break;
          case 'out_of_bounds':
            print('Выстрел за пределы поля!');
            break;
        }
        
        print('\nНажмите Enter для продолжения...');
        try {
          stdin.readLineSync();
        } catch (e) {
          // Игнорируем ошибки ввода
        }
      }
      
      if (result == 'miss' || result == 'already_shot' || result == 'out_of_bounds') {
        isPlayer1Turn = !isPlayer1Turn;
      }
    }
    
    _endGame();
  }

  void _endGame() {
    _clearConsole();
    Player winner = player1.board.allShipsDestroyed() ? player2 : player1;
    print('\n=== ИГРА ОКОНЧЕНА ===');
    print('Победитель: ${winner.name}!');
    print('\nФинальное состояние полей:');
    print('\nПоле ${player1.name}:');
    player1.board.displayBoard();
    print('\nПоле ${player2.name}:');
    player2.board.displayBoard();
  }

  void _clearConsole() {
    print('\x1B[2J\x1B[0;0H');
  }

  String _gameMode = '';
}

void main() {
  Game game = Game();
  game.start();
}
