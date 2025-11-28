import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/features/games/game_2048/domain/game_2048_logic.dart';
import 'package:iskra/features/games/game_2048/presentation/widgets/game_tile.dart';

class GameBoard extends ConsumerWidget {
  const GameBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(game2048Provider);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridSize = constraints.maxWidth;
        final tileSize = (gridSize - (5 * 8)) / 4; // 5 gaps of 8px

        return GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              ref.read(game2048Provider.notifier).move(SwipeDirection.up);
            } else if (details.primaryVelocity! > 0) {
              ref.read(game2048Provider.notifier).move(SwipeDirection.down);
            }
          },
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              ref.read(game2048Provider.notifier).move(SwipeDirection.left);
            } else if (details.primaryVelocity! > 0) {
              ref.read(game2048Provider.notifier).move(SwipeDirection.right);
            }
          },
          child: Container(
            width: gridSize,
            height: gridSize,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.3), // Darker background for better contrast
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 2), // Gold border
            ),
            child: Stack(
              children: [
                // Background grid cells
                for (int i = 0; i < 16; i++)
                  Positioned(
                    left: (i % 4) * (tileSize + 8.0),
                    top: (i ~/ 4) * (tileSize + 8.0),
                    child: Container(
                      width: tileSize,
                      height: tileSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1), // More visible grid cells
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                  ),
                
                // Active tiles
                for (final tile in gameState.tiles)
                  AnimatedPositioned(
                    key: ValueKey(tile.id),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    left: tile.x * (tileSize + 8.0),
                    top: tile.y * (tileSize + 8.0),
                    child: GameTile(
                      value: tile.value,
                      size: tileSize,
                      isNew: tile.isNew,
                      isMerged: tile.isMerged,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
