import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/features/games/game_2048/domain/game_2048_logic.dart';
import 'package:iskra/features/games/game_2048/presentation/widgets/game_board.dart';
import 'package:iskra/features/games/game_2048/presentation/widgets/rank_painter.dart';

class Game2048Page extends ConsumerStatefulWidget {
  const Game2048Page({super.key});

  @override
  ConsumerState<Game2048Page> createState() => _Game2048PageState();
}

class _Game2048PageState extends ConsumerState<Game2048Page> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(game2048Provider.notifier).loadGame(4);
      _triggerOverlay();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _triggerOverlay() async {
    if (!mounted) return;
    setState(() => _showOverlay = true);
    _controller.reset();
    await _controller.forward();
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;
    setState(() => _showOverlay = false);
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
              _triggerOverlay();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
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
                    // Modern Header Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Title Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '2048',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    'PSP EDITION',
                                    style: TextStyle(
                                      color: const Color(0xFFFFD700).withOpacity(0.9),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ],
                              ),
                              // Rank Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'STOPIEŃ',
                                      style: TextStyle(
                                        color: const Color(0xFFFFD700).withOpacity(0.8),
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    Text(
                                      currentRankName.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Stats Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildModernScoreBox('WYNIK', gameState.score),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildModernScoreBox('REKORD', gameState.bestScore),
                              ),
                            ],
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
                                        _triggerOverlay();
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
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          if (_showOverlay)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _opacity.value,
                        child: Transform.scale(
                          scale: _scale.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFFFD700), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.touch_app, color: Color(0xFFFFD700), size: 48),
                                const SizedBox(height: 16),
                                const Text(
                                  'ŁĄCZ STOPNIE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ABY AWANSOWAĆ',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    for (int i = 1; i <= 19; i++)
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A237E),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.white24, width: 0.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: CustomPaint(
                                            painter: RankPainter(1 << i),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
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

  Widget _buildModernScoreBox(String label, int score) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
