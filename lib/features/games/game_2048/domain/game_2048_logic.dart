import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

enum GameStatus { playing, won, lost }
enum SwipeDirection { up, down, left, right }

class Tile {
  final String id;
  final int value;
  final int x; // Column (0-3)
  final int y; // Row (0-3)
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
}

class Game2048State {
  final List<Tile> tiles;
  final int score;
  final int bestScore;
  final GameStatus status;
  final List<Game2048State> history; // For undo functionality

  const Game2048State({
    required this.tiles,
    required this.score,
    required this.bestScore,
    required this.status,
    this.history = const [],
  });

  factory Game2048State.initial() {
    return const Game2048State(
      tiles: [],
      score: 0,
      bestScore: 0,
      status: GameStatus.playing,
      history: [],
    );
  }

  Game2048State copyWith({
    List<Tile>? tiles,
    int? score,
    int? bestScore,
    GameStatus? status,
    List<Game2048State>? history,
  }) {
    return Game2048State(
      tiles: tiles ?? this.tiles,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      status: status ?? this.status,
      history: history ?? this.history,
    );
  }
}

class Game2048Notifier extends Notifier<Game2048State> {
  final _uuid = const Uuid();
  static const int maxUndoCount = 3;

  @override
  Game2048State build() {
    return Game2048State.initial();
  }

  void startNewGame() {
    state = Game2048State.initial().copyWith(bestScore: state.bestScore);
    _addRandomTile();
    _addRandomTile();
  }

  void undo() {
    if (state.history.isNotEmpty) {
      final previousState = state.history.last;
      // Restore state but keep the current best score if it was higher? 
      // Usually undo reverts score too.
      // We also need to keep the history list (minus the one we just popped)
      final newHistory = List<Game2048State>.from(state.history)..removeLast();
      
      state = previousState.copyWith(
        history: newHistory,
        bestScore: max(state.bestScore, previousState.bestScore), // Keep best score
      );
    }
  }

  void move(SwipeDirection direction) {
    if (state.status != GameStatus.playing) return;

    // Save current state to history before modifying
    // We only store up to maxUndoCount states
    List<Game2048State> newHistory = List.from(state.history);
    if (newHistory.length >= maxUndoCount) {
      newHistory.removeAt(0); // Remove oldest
    }
    // We need to store a snapshot of the current state (without the history itself to avoid recursion/bloat, 
    // though here it's immutable so it's fine, but we should clear history in the saved state to save memory?)
    // Actually, just saving 'state' is fine, but we should probably set its history to empty to avoid chain.
    newHistory.add(state.copyWith(history: []));

    // 1. Reset merge/new flags for current tiles
    var tiles = state.tiles.map((t) => t.copyWith(isNew: false, isMerged: false)).toList();
    
    bool moved = false;
    int scoreToAdd = 0;

    // 2. Sort tiles based on direction to process them in correct order
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

    // 3. Process each tile
    List<Tile> newTiles = [];
    final Map<String, Tile> occupied = {};

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

      // Find farthest position
      while (nextX >= 0 && nextX < 4 && nextY >= 0 && nextY < 4) {
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
        
        // Update the target tile in the map and list
        final mergedTile = mergeTarget.copyWith(
          value: newValue,
          isMerged: true,
        );
        
        occupied['${mergeTarget.x},${mergeTarget.y}'] = mergedTile;
        
        // Replace in newTiles list
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
        history: newHistory, // Update history
      );
      _addRandomTile();
      _checkGameStatus();
    }
  }

  void _addRandomTile() {
    List<Point<int>> emptyCells = [];
    final grid = List.generate(4, (_) => List.filled(4, false));
    for (var t in state.tiles) {
      grid[t.y][t.x] = true;
    }

    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
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
    if (state.tiles.length < 16) return true;

    final grid = List.generate(4, (_) => List.filled(4, 0));
    for (var t in state.tiles) {
      grid[t.y][t.x] = t.value;
    }

    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        final val = grid[r][c];
        if (c < 3 && val == grid[r][c + 1]) return true;
        if (r < 3 && val == grid[r + 1][c]) return true;
      }
    }
    return false;
  }
}

final game2048Provider = NotifierProvider<Game2048Notifier, Game2048State>(Game2048Notifier.new);

