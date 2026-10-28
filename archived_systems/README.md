# Sistemas Archivados Temporalmente

Esta carpeta contiene sistemas y recursos retirados temporalmente del juego para simplificar el proyecto y centrarse en **Movimiento, Combate (con Stun y Sangrado), Sigilo, Diálogo, Misiones y Objetos Destructibles**.

> **Nota importante:** Esta carpeta contiene un archivo `.gdignore` para que Godot no escanee ni compile estos scripts/escenas mientras están archivados (mejorando el tiempo de carga y evitando errores de dependencias cruzadas).

## Estructura de lo archivado

1. **`combat_armor/`**:
   - `ArmorComponent.gd` y `EquipmentComponent.gd` (mitigación de daño por ranuras de armadura y materiales).
2. **`power_system/`**:
   - `addons/powergrid/` (gestor de red eléctrica, puertos, generadores, transformadores, cargas).
   - `scripts/power/` y `scenes/power/` (`InteractiveGenerator`, `PoweredDoor`, `VisualCable`).
   - `ConductiveArea.gd` (áreas mojadas que electrifican).
3. **`grid_inventory/`**:
   - `GridInventory.gd`, `InventoryUI.gd`, `InventoryItemUI.gd`, `InventoryItem.gd`, `ItemDatabase.gd`, `InventoryTestHelper.gd`, `InventoryUI.tscn` y `resources/items/`.
4. **`interiors_and_teleporters/`**:
   - `SceneTeleporter.gd`, `scenes/Buildings/` (`house_1.tscn`, `House1Interior.tscn`), `House_Test.tscn`, `scenes/world/`, `OverheadFader.gd`, `key.gd`, `door_interact_collision.gd`.
5. **`unused_assets_and_tools/`**:
   - Archivos `.rar`/`.zip` y carpetas duplicadas de `assests/`, junto con herramientas de edición (`TileSetMaker`, `ResizeTexture`).
