# Chunk-Based WFC — Godot 4

A custom procedural level generation system developed for my game, *Backrooms Complex*. It is inspired by **Wave Function Collapse (WFC)** and adapted to generate large environments from smaller, independently generated chunks.

This repository is a simplified version of the game's generation system, separated from gameplay features so the algorithm can be explored and improved on its own.

## Features

- **Chunk-based generation:** The world is built from grids of modular room pieces.
- **Connection rules:** Pieces are selected based on how they connect to neighboring pieces.
- **Deterministic generation:** The same world seed produces the same chunk layouts.
- **Shared chunk boundaries:** Neighboring chunks calculate compatible edge connections independently, without needing to generate in a particular order.
- **Tile rotation, weighted selection, and backtracking:** These allow more variety while respecting the connection rules.
- **Dynamic chunk loading:** Chunks can be created and unloaded as the target moves through the world.

## How it works

Each chunk contains a grid of cells. The generator chooses from predefined modular pieces, checking their directional connections against neighboring cells. When a choice leads to an invalid layout, it backtracks and tries another option.

To connect separate chunks, both sides calculate the same boundary requirements from the world seed and shared chunk coordinates. This allows chunk generation to remain independent while keeping their edges compatible.

## Project status

**Work in progress.** This is my own WFC-inspired implementation, not a complete reproduction of the original algorithm. I'm continuing to experiment with generation quality, performance, and more reliable connections within and between chunks.

The repository is intended as a small demonstration and a place to develop the system further, rather than a finished Godot add-on.

## Reference

Inspired by [Maxim Gumin's WaveFunctionCollapse](https://github.com/mxgmn/WaveFunctionCollapse).
