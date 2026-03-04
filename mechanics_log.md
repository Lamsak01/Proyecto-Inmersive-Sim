# Proyecto Immersive Sim - Mechanics & Progress Log

This document serves as a comprehensive log of the game mechanics currently implemented in the project and the recent development progress made. It is intended to provide a clear overview for feedback and further iteration.

## 1. Core Player Mechanics
- **Movement & Stamina**: The player can move in 8 directions (top-down perspective). Sprinting consumes stamina, and movement is blocked or slowed when stamina is depleted.
- **Stealth Stance**: The player can toggle a crouch/stealth stance (via the `C` key). While stealthing, the player's movement speed is reduced, sprinting is disabled, and footstep noise is completely silenced, preventing auditory detection by enemies.
- **Combat (Hurtboxes & Hitboxes)**: The game features a modular combat system where entities have defined `Hurtbox` areas to receive damage, and combat controllers handle weapon swings and collisions.

## 2. Stealth & Takedown Mechanics
- **Positional Takedowns**: The player can perform instant stealth takedowns or knockouts on enemies.
- **Takedown Conditions**: A takedown can only be executed if the player approaches an unaware enemy (in Idle or Search state) from behind. The system checks the dot product between the enemy's internal facing direction and the vector from the enemy to the player, requiring the player to be within a specific expanded radius (80x80 pixels).

## 3. Advanced Enemy AI (State Machine)
Enemies are controlled by a robust `EnemyAI.gd` state machine that transitions between **Idle**, **Alert**, **Chase**, **Search**, and **Return**.

- **Sensory Systems (Vision & Hearing)**:
  - **Vision Cone**: Enemies have a 120-degree visual field of view (FOV). They detect the player via Line of Sight (LOS) raycasts if the player enters their view cone and is within maximum detection range.
  - **Auditory Detection**: Enemies can hear the player within a 60px radius, even through walls. If a noise is heard, the enemy will smoothly rotate to face the source of the noise. (This is bypassed if the player is in stealth stance).
  
- **Awareness Meter**: When an enemy spots the player, an awareness meter fills over time (Alert state). If the player breaks line of sight or exits the FOV, the meter drains. Once full, the enemy enters the Chase state.

- **"Ghost" Search Investigation**: 
  - If an enemy is chasing the player and loses sight of them, they do not simply return to idle.
  - A visual "Ghost" (a silhouette of the player with a blue-outline shader) is spawned at the exact last known position of the player.
  - The enemy transitions to the **Search** state for 5 seconds, actively navigating to the Ghost's location and roaming nearby to investigate before giving up.

- **Context Steering & Navigation**: Enemies use Godot's `NavigationAgent2D` for pathfinding, combined with Context Steering (8-directional raycast checks) to actively avoid dynamic obstacles and walls while pursuing the player.

- **Performance Optimizations**: Heavy AI calculations, such as Line of Sight raycasting and obstacle avoidance steering, are throttled to run every 0.1 seconds (10 ticks per second) rather than every physics frame, vastly improving CPU performance.

## 4. Grid-Based Inventory System
- **Tetris-style Grid**: The game features a spatial grid inventory (`GridInventory.gd`) where items (`InventoryItem` resources) take up specific cell dimensions (e.g., a shield taking 2x2 slots).
- **Drag & Drop**: Players can intuitively drag, drop, and rotate items within the grid UI.
- **Hotkeys**: Items can be assigned to hotkeys (1-9) for quick access/equipping. Hotkey assignments persist seamlessly when transitioning between different game scenes.

## 5. Puzzle & Power Grid System
- **Interactive Power Grid**: The world features interconnected interactive elements including Generators, visual Data/Power Cables, and Powered Doors.
- **Visual Feedback**: The system provides active visual polish showing the current state of the components (e.g., Generator turned on/off, Cables glowing when powered, Doors opening smoothly when power flows).

## 6. Objectives System
- **Quest Tracking**: An objective tracking system (`Objective.gd`) manages active player goals (e.g., "Find the Sword") using custom Godot resources to handle objective states and completion triggers.

## 7. Scene & State Management
- **Persistent Player State**: When the player travels between different levels/scenes, the `GameState` singleton automatically saves and restores the player's exact inventory grid, health, and current loadout.
- **Smooth Scene Transitions**: Scene loading is optimized to prevent lag spikes, and player spawn points support orientation data (e.g., spawning the player explicitly facing 'Up' for a more natural entry into a new environment).

---

### Recent Development Highlights
- **AI Refinements**: Completely overhauled enemy sensory processing to decouple vision from hearing, introduced the visually clear 'Ghost' mechanic for lost-sight investigation, and aggressively optimized raycast calculations.
- **UX Polish**: Fixed visual alignments for AI cones, increased the generosity of stealth takedown hitboxes to make them less frustrating, and ensured scene transitions reliably maintain player hotkeys and orientations.
