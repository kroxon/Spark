import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum GameStatus { playing, won, lost }
enum SwipeDirection { up, down, left, right }

class Tile {
  final String id;
  final int value;
  final int x; // Column (0-gridSize-1)
  final int y; // Row (0-gridSize-1)
  final bool isNew; // For pop animation
  final bool isMerged; // For pop animation

  const Tile({
    required this.id,
    required this.value,
    required this.x,
    required this.y,
    this.isNew = false,
    this.isMerged = false,
  });

  Tile copyWith({
    String? id,
    int? value,
    int? x,
    int? y,
    bool? isNew,
    bool? isMerged,
  }) {
    return Tile(
      id: id ?? this.id,
      value: value ?? this.value,
      x: x ?? this.x,
      y: y ?? this.y,
      isNew: isNew ?? this.isNew,
      isMerged: isMerged ?? this.isMerged,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'x': x,
      'y': y,
      'isNew': isNew,
      'isMerged': isMerged,
    };
  }

  factory Tile.fromJson(Map<String, dynamic> json) {
    return Tile(
      id: json['id'] as String,
      value: json['value'] as int,
      x: json['x'] as int,
      y: json['y'] as int,
      isNew: json['isNew'] as bool? ?? false,
      isMerged: json['isMerged'] as bool? ?? false,
    );
  }
}

class Game2048State {
  final List<Tile> tiles;
  final int score;
  final int bestScore;
  final GameStatus status;
  final List<Game2048State> history; // For undo functionality
  final int gridSize;

  const Game2048State({
    required this.tiles,
    required this.score,
    required this.bestScore,
    required this.status,
    this.history = const [],
    this.gridSize = 4,
  });

  factory Game2048State.initial({int gridSize = 4}) {
    return Game2048State(
      tiles: [],
      score: 0,
      bestScore: 0,
      status: GameStatus.playing,
      history: [],
      gridSize: gridSize,
    );
  }

  Game2048State copyWith({
    List<Tile>? tiles,
    int? score,
    int? bestScore,
    GameStatus? status,
    List<Game2048State>? history,
    int? gridSize,
  }) {
    return Game2048State(
      tiles: tiles ?? this.tiles,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      status: status ?? this.status,
      history: history ?? this.history,
      gridSize: gridSize ?? this.gridSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tiles': tiles.map((t) => t.toJson()).toList(),
      'score': score,
      'bestScore': bestScore,
      'status': status.index,
      'gridSize': gridSize,
      // We don't save history to keep storage small, or we could if needed.
      // For now let's skip history persistence to avoid complexity/size issues.
    };
  }

  factory Game2048State.fromJson(Map<String, dynamic> json) {
    return Game2048State(
      tiles: (json['tiles'] as List).map((e) => Tile.fromJson(e)).toList(),
      score: json['score'] as int,
      bestScore: json['bestScore'] as int,
      status: GameStatus.values[json['status'] as int],
      gridSize: json['gridSize'] as int? ?? 4,
      history: [], // History is lost on reload
    );
  }
}

class Game2048Notifier extends Notifier<Game2048State> {
  final _uuid = const Uuid();
  static const int maxUndoCount = 3;
  static const String _storageKeyPrefix = 'game_2048_state_';

  @override
  Game2048State build() {
    // Initial load will happen in init
    return Game2048State.initial();
  }

  Future<void> loadGame(int gridSize) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_storageKeyPrefix$gridSize';
      final jsonString = prefs.getString(key);

      if (jsonString != null) {
        try {
          final jsonMap = jsonDecode(jsonString);
          state = Game2048State.fromJson(jsonMap);
        } catch (e) {
          debugPrint('Error parsing game state: $e');
          // If error, start new game
          state = Game2048State.initial(gridSize: gridSize);
          startNewGame();
        }
      } else {
        state = Game2048State.initial(gridSize: gridSize);
        startNewGame();
      }
    } catch (e) {
      debugPrint('Error loading game (likely plugin not ready): $e');
      // Fallback to memory-only game
      state = Game2048State.initial(gridSize: gridSize);
      startNewGame();
    }
  }

  Future<void> _saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_storageKeyPrefix${state.gridSize}';
      final jsonString = jsonEncode(state.toJson());
      await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('Error saving game: $e');
    }
  }

  Future<void> switchGridSize(int newSize) async {
    if (state.gridSize == newSize) return;
    await _saveGame(); // Save current game before switching
    await loadGame(newSize); // Load game for new size
  }

  void startNewGame() {
    // Keep best score if we are resetting the same grid size
    // But if we are just starting fresh, we might want to load best score from storage?
    // Actually, bestScore is part of the state.
    // If we want to keep best score across resets of the SAME grid size:
    state = Game2048State.initial(gridSize: state.gridSize).copyWith(bestScore: state.bestScore);
    _addRandomTile();
    _addRandomTile();
    _saveGame();
  }

  void undo() {
    if (state.history.isNotEmpty) {
      final previousState = state.history.last;
      final newHistory = List<Game2048State>.from(state.history)..removeLast();
      
      state = previousState.copyWith(
        history: newHistory,
        bestScore: max(state.bestScore, previousState.bestScore),
      );
      _saveGame();
    }
  }

  void move(SwipeDirection direction) {
    if (state.status != GameStatus.playing) return;

    List<Game2048State> newHistory = List.from(state.history);
    if (newHistory.length >= maxUndoCount) {
      newHistory.removeAt(0);
    }
    newHistory.add(state.copyWith(history: []));

    var tiles = state.tiles.map((t) => t.copyWith(isNew: false, isMerged: false)).toList();
    
    bool moved = false;
    int scoreToAdd = 0;

    switch (direction) {
      case SwipeDirection.up:
        tiles.sort((a, b) => a.y.compareTo(b.y));
        break;
      case SwipeDirection.down:
        tiles.sort((a, b) => b.y.compareTo(a.y));
        break;
      case SwipeDirection.left:
        tiles.sort((a, b) => a.x.compareTo(b.x));
        break;
      case SwipeDirection.right:
        tiles.sort((a, b) => b.x.compareTo(a.x));
        break;
    }

    List<Tile> newTiles = [];
    final Map<String, Tile> occupied = {};
    final gridSize = state.gridSize;

    for (var tile in tiles) {
      int targetX = tile.x;
      int targetY = tile.y;

      int dx = 0;
      int dy = 0;
      switch (direction) {
        case SwipeDirection.up: dy = -1; break;
        case SwipeDirection.down: dy = 1; break;
        case SwipeDirection.left: dx = -1; break;
        case SwipeDirection.right: dx = 1; break;
      }

      int nextX = tile.x + dx;
      int nextY = tile.y + dy;
      
      Tile? mergeTarget;

      while (nextX >= 0 && nextX < gridSize && nextY >= 0 && nextY < gridSize) {
        final key = '$nextX,$nextY';
        final existing = occupied[key];
        
        if (existing != null) {
          if (existing.value == tile.value && !existing.isMerged) {
            mergeTarget = existing;
          }
          break;
        }
        
        targetX = nextX;
        targetY = nextY;
        
        nextX += dx;
        nextY += dy;
      }

      if (mergeTarget != null) {
        final newValue = tile.value * 2;
        scoreToAdd += newValue;
        
        final mergedTile = mergeTarget.copyWith(
          value: newValue,
          isMerged: true,
        );
        
        occupied['${mergeTarget.x},${mergeTarget.y}'] = mergedTile;
        
        final index = newTiles.indexWhere((t) => t.id == mergeTarget!.id);
        if (index != -1) {
          newTiles[index] = mergedTile;
        }
        
        moved = true;
      } else {
        if (tile.x != targetX || tile.y != targetY) {
          moved = true;
        }
        
        final newTile = tile.copyWith(x: targetX, y: targetY);
        occupied['$targetX,$targetY'] = newTile;
        newTiles.add(newTile);
      }
    }

    if (moved) {
      state = state.copyWith(
        tiles: newTiles,
        score: state.score + scoreToAdd,
        bestScore: max(state.bestScore, state.score + scoreToAdd),
        history: newHistory,
      );
      _addRandomTile();
      _checkGameStatus();
      _saveGame();
    }
  }

  void _addRandomTile() {
    List<Point<int>> emptyCells = [];
    final gridSize = state.gridSize;
    final grid = List.generate(gridSize, (_) => List.filled(gridSize, false));
    for (var t in state.tiles) {
      grid[t.y][t.x] = true;
    }

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (!grid[r][c]) {
          emptyCells.add(Point(c, r));
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      final random = Random();
      final point = emptyCells[random.nextInt(emptyCells.length)];
      final value = random.nextDouble() < 0.9 ? 2 : 4;
      
      final newTile = Tile(
        id: _uuid.v4(),
        value: value,
        x: point.x,
        y: point.y,
        isNew: true,
      );
      
      state = state.copyWith(tiles: [...state.tiles, newTile]);
    }
  }

  void _checkGameStatus() {
    if (!_canMove()) {
      state = state.copyWith(status: GameStatus.lost);
    }
  }

  bool _canMove() {
    final gridSize = state.gridSize;
    if (state.tiles.length < gridSize * gridSize) return true;

    final grid = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    for (var t in state.tiles) {
      grid[t.y][t.x] = t.value;
    }

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final val = grid[r][c];
        if (c < gridSize - 1 && val == grid[r][c + 1]) return true;
        if (r < gridSize - 1 && val == grid[r + 1][c]) return true;
      }
    }
    return false;
  }
}

final game2048Provider = NotifierProvider<Game2048Notifier, Game2048State>(Game2048Notifier.new);

