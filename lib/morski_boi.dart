import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:isolate';
import 'dart:convert';

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

// Событие игры для логирования
class GameEvent {
  final String playerName;
  final String type; // move, place, error
  final String message;
  final DateTime timestamp;
  GameEvent({
    required this.playerName,
    required this.type,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// Логгер игры (Stream -> файл)
class GameLogger {
  final String logPath;
  IOSink? _sink;
  StreamSubscription<GameEvent>? _subscription;
  GameLogger({required this.logPath});

  Future<void> start(Stream<GameEvent> events) async {
    final file = await _ensureFile(logPath);
    _sink = file.openWrite(mode: FileMode.append);
    _subscription = events.listen((e) {
      _sink?.writeln('[${e.timestamp.toIso8601String()}] [${e.type}] ${e.playerName}: ${e.message}');
    });
  }

  Future<void> logError(String who, String message) async {
    final file = await _ensureFile(logPath);
    final sink = file.openWrite(mode: FileMode.append);
    sink.writeln('[${DateTime.now().toIso8601String()}] [error] $who: $message');
    await sink.flush();
    await sink.close();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    await _sink?.flush();
    await _sink?.close();
  }

  Future<File> _ensureFile(String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return file;
  }
}

// Статистика игрока (файл per player)
class PlayerStatsManager {
  final String dirPath;
  PlayerStatsManager({required this.dirPath});

  Future<Map<String, dynamic>> load(String playerName) async {
    final file = await _ensureFile('$dirPath/${_safe(playerName)}.json');
    if (await file.length() == 0) {
      final data = {'name': playerName, 'gamesPlayed': 0, 'wins': 0, 'losses': 0};
      await file.writeAsString(jsonEncode(data));
      return data;
    }
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<void> update(String playerName, {int? gamesPlayed, int? wins, int? losses}) async {
    final file = await _ensureFile('$dirPath/${_safe(playerName)}.json');
    Map<String, dynamic> data = {};
    if (await file.length() > 0) {
      data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } else {
      data = {'name': playerName, 'gamesPlayed': 0, 'wins': 0, 'losses': 0};
    }
    if (gamesPlayed != null) data['gamesPlayed'] = gamesPlayed;
    if (wins != null) data['wins'] = wins;
    if (losses != null) data['losses'] = losses;
    await file.writeAsString(jsonEncode(data));
  }

  String _safe(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  Future<File> _ensureFile(String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return file;
  }
}

// Текущая игра: попадания/промахи/состояние кораблей, файл очищается/удаляется после игры
class CurrentGameTracker {
  final String filePath;
  Map<String, dynamic> state = {};
  CurrentGameTracker({required this.filePath});

  Future<void> init(List<String> playerNames) async {
    await _ensureFile(filePath);
    state = {
      'players': {
        for (final name in playerNames)
          name: {
            'hits': 0,
            'misses': 0,
            'ships': {'alive': 0, 'damaged': 0, 'destroyed': 0}
          }
      }
    };
    await _persist();
  }

  Future<void> updateShot(String playerName, String result) async {
    final p = (state['players'] as Map<String, dynamic>)[playerName] as Map<String, dynamic>;
    if (result == 'hit' || result == 'destroyed') {
      p['hits'] = (p['hits'] as int) + 1;
    } else if (result == 'miss' || result == 'already_shot' || result == 'out_of_bounds') {
      p['misses'] = (p['misses'] as int) + 1;
    }
    await _persist();
  }

  Future<void> updateShips(String ownerName, List<Ship> ships, List<Position> shots) async {
    final p = (state['players'] as Map<String, dynamic>)[ownerName] as Map<String, dynamic>;
    int destroyed = ships.where((s) => s.isDestroyed).length;
    int damaged = ships.where((s) => !s.isDestroyed && s.positions.any((pos) => shots.any((h) => h == pos))).length;
    int alive = ships.length - destroyed - damaged;
    p['ships'] = {'alive': alive, 'damaged': damaged, 'destroyed': destroyed};
    await _persist();
  }

  Future<void> clearOrDelete({bool delete = true}) async {
    final file = File(filePath);
    if (!await file.exists()) return;
    if (delete) {
      await file.delete();
    } else {
      await file.writeAsString('');
    }
  }

  Future<void> _persist() async {
    final file = await _ensureFile(filePath);
    await file.writeAsString(jsonEncode(state));
  }

  Future<File> _ensureFile(String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return file;
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
  Future<Position?> makeMove(List<Position> forbiddenShots) async {
    if (isBot) {
      return await _makeBotMove(forbiddenShots);
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
      return Future.value(pos);
    }
  }

  // Выстрел бота с использованием изолята
  Future<Position?> _makeBotMove(List<Position> forbiddenShots) async {
    final receivePort = ReceivePort();
    await Isolate.spawn<_BotMovePayload>(
      _botMoveIsolate,
      _BotMovePayload(
        sendPort: receivePort.sendPort,
        size: board.size,
        forbidden: forbiddenShots.map((p) => [p.x, p.y]).toList(),
      ),
    );
    final result = await receivePort.first as List<int>?;
    if (result == null) return null;
    return Position(result[0], result[1]);
  }

  static void _botMoveIsolate(_BotMovePayload payload) {
    final random = Random();
    final size = payload.size;
    final forbidden = payload.forbidden.map((e) => '${e[0]}:${e[1]}').toSet();
    for (int attempts = 0; attempts < size * size; attempts++) {
      final x = random.nextInt(size);
      final y = random.nextInt(size);
      final key = '$x:$y';
      if (!forbidden.contains(key)) {
        payload.sendPort.send([x, y]);
        return;
      }
    }
    payload.sendPort.send(null);
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

class _BotMovePayload {
  final SendPort sendPort;
  final int size;
  final List<List<int>> forbidden;
  _BotMovePayload({required this.sendPort, required this.size, required this.forbidden});
}

// Игра
class Game {
  late Player player1;
  late Player player2;
  late int boardSize;
  bool isPlayer1Turn = true;
  final _events = StreamController<GameEvent>.broadcast();
  late final GameLogger _logger;
  late final PlayerStatsManager _stats;
  late final CurrentGameTracker _currentGame;

  Future<void> start() async {
    print('=== МОРСКОЙ БОЙ ===');
    _logger = GameLogger(logPath: 'logs/game.log');
    _stats = PlayerStatsManager(dirPath: 'data/players');
    _currentGame = CurrentGameTracker(filePath: 'data/current_game.json');
    await _logger.start(_events.stream);
    _selectGameMode();
    _selectBoardSize();
    _createPlayers();
    await _currentGame.init([player1.name, player2.name]);
    await _placeShips();
    await _playGame();
    await _logger.stop();
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

  Future<void> _placeShips() async {
    player1.placeShips();
    _clearConsole();
    player2.placeShips();
    _clearConsole();
    await _currentGame.updateShips(player1.name, player1.board.ships, player2.board.shots);
    await _currentGame.updateShips(player2.name, player2.board.ships, player1.board.shots);
  }

  Future<void> _playGame() async {
    // увеличить счётчик сыгранных игр
    try {
      final s1 = await _stats.load(player1.name);
      await _stats.update(player1.name, gamesPlayed: (s1['gamesPlayed'] as int) + 1, wins: s1['wins'] as int, losses: s1['losses'] as int);
      final s2 = await _stats.load(player2.name);
      await _stats.update(player2.name, gamesPlayed: (s2['gamesPlayed'] as int) + 1, wins: s2['wins'] as int, losses: s2['losses'] as int);
    } catch (e) {
      await _logger.logError('system', 'Ошибка обновления статистики игроков: $e');
    }
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
      
      Position? shot = await currentPlayer.makeMove(forbiddenShots);
      if (shot == null) continue;
      
      String result = opponent.board.shoot(shot);
      // лог/стрим событие
      final col = String.fromCharCode(65 + shot.y);
      final row = shot.x + 1;
      _events.add(GameEvent(playerName: currentPlayer.name, type: 'move', message: 'Ход на $row$col → $result'));
      await _currentGame.updateShot(currentPlayer.name, result);
      await _currentGame.updateShips(opponent.name, opponent.board.ships, opponent.board.shots);
      
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
            await _logger.logError(currentPlayer.name, 'Ошибка, вы уже ходили на $row$col');
            break;
          case 'out_of_bounds':
            print('Выстрел за пределы поля!');
            await _logger.logError(currentPlayer.name, 'Ошибка, ход за пределы поля $row$col');
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
    () async {
      try {
        final s1 = await _stats.load(player1.name);
        final s2 = await _stats.load(player2.name);
        if (winner.name == player1.name) {
          await _stats.update(player1.name, gamesPlayed: s1['gamesPlayed'] as int, wins: (s1['wins'] as int) + 1, losses: s1['losses'] as int);
          await _stats.update(player2.name, gamesPlayed: s2['gamesPlayed'] as int, wins: s2['wins'] as int, losses: (s2['losses'] as int) + 1);
        } else {
          await _stats.update(player2.name, gamesPlayed: s2['gamesPlayed'] as int, wins: (s2['wins'] as int) + 1, losses: s2['losses'] as int);
          await _stats.update(player1.name, gamesPlayed: s1['gamesPlayed'] as int, wins: s1['wins'] as int, losses: (s1['losses'] as int) + 1);
        }
      } catch (e) {
        await _logger.logError('system', 'Ошибка обновления побед/поражений: $e');
      }
      try {
        await _currentGame.clearOrDelete(delete: true);
      } catch (e) {
        await _logger.logError('system', 'Ошибка очистки current_game.json: $e');
      }
    }();
  }

  void _clearConsole() {
    print('\x1B[2J\x1B[0;0H');
  }

  String _gameMode = '';
}

Future<void> main() async {
  Game game = Game();
  await game.start();
}
