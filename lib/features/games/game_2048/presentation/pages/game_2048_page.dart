import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/features/games/game_2048/domain/game_2048_logic.dart';
import 'package:iskra/features/games/game_2048/presentation/widgets/game_board.dart';

class Game2048Page extends ConsumerStatefulWidget {
  const Game2048Page({super.key});

  @override
  ConsumerState<Game2048Page> createState() => _Game2048PageState();
}

class _Game2048PageState extends ConsumerState<Game2048Page> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(game2048Provider.notifier).loadGame(4);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(game2048Provider);
    
    int maxTile = 0;
    if (gameState.tiles.isNotEmpty) {
      maxTile = gameState.tiles.map((t) => t.value).reduce((a, b) => a > b ? a : b);
    }
    final currentRankName = _getRankName(maxTile);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Grid Size Switcher
          Container(
            margin: const EdgeInsets.only(right: 8),
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                _buildGridOption(context, 4, gameState.gridSize == 4),
                Container(width: 1, color: Colors.white.withOpacity(0.1)),
                _buildGridOption(context, 5, gameState.gridSize == 5),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.undo,
              color: gameState.history.isNotEmpty ? Colors.white : Colors.white38,
            ),
            onPressed: gameState.history.isNotEmpty
                ? () => ref.read(game2048Provider.notifier).undo()
                : null,
            tooltip: 'Cofnij',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(game2048Provider.notifier).startNewGame();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1), // Blue 900
              Color(0xFF000000), // Black
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      '2048',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'PSP EDITION',
                      style: TextStyle(
                        color: Color(0xFFFFD700), // Gold
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                // Score Board
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildScoreBox('WYNIK', gameState.score),
                    const SizedBox(width: 12),
                    _buildScoreBox('REKORD', gameState.bestScore),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Current Rank Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'AKTUALNY STOPIEŃ',
                        style: TextStyle(
                          color: const Color(0xFFFFD700).withOpacity(0.8),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentRankName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Game Board
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      const GameBoard(),
                      if (gameState.status == GameStatus.lost)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'KONIEC GRY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(game2048Provider.notifier).startNewGame();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFD700),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'SPRÓBUJ PONOWNIE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Legend
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Łącz identyczne stopnie aby awansować',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBox(String label, int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridOption(BuildContext context, int size, bool isSelected) {
    return InkWell(
      onTap: () {
        if (!isSelected) {
          ref.read(game2048Provider.notifier).switchGridSize(size);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          '${size}x$size',
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _getRankName(int value) {
    switch (value) {
      case 2: return 'Strażak';
      case 4: return 'Starszy Strażak';
      case 8: return 'Sekcyjny';
      case 16: return 'Starszy Sekcyjny';
      case 32: return 'Młodszy Ogniomistrz';
      case 64: return 'Ogniomistrz';
      case 128: return 'Starszy Ogniomistrz';
      case 256: return 'Młodszy Aspirant';
      case 512: return 'Aspirant';
      case 1024: return 'Starszy Aspirant';
      case 2048: return 'Aspirant Sztabowy';
      case 4096: return 'Młodszy Kapitan';
      case 8192: return 'Kapitan';
      case 16384: return 'Starszy Kapitan';
      case 32768: return 'Młodszy Brygadier';
      case 65536: return 'Brygadier';
      case 131072: return 'Starszy Brygadier';
      case 262144: return 'Nadbrygadier';
      case 524288: return 'Generał Brygadier';
      default: return 'Strażak';
    }
  }
}
