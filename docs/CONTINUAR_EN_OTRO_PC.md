# Cómo seguir el proyecto en otro ordenador (2026-11-05)

## 1. Bajar el proyecto
1. Abre una terminal en la carpeta del juego del otro ordenador y ejecuta `git pull` (rama `main`).
   Si aún no lo tienes: `git clone <url del repositorio>`.
2. Abre el proyecto con **Godot 4.7.2** (renderizador Compatibility). La primera vez tarda un poco porque Godot
   importa de nuevo texturas y modelos. Es normal.
3. Pulsa **F9** en el juego para cambiar entre la vista 2D y la 3D.

## 2. Qué NO viaja con git (y no hace falta)
- `assests/Assets 3d/` (≈114 MB): solo son los paquetes descargados en bruto. El juego no los usa: los modelos
  buenos ya están copiados en `assests/curated_3d/` y las animaciones ya preparadas en
  `assests/curated_3d/animations/ual_male.res` y `ual_female.res` (sí están en git).
  Solo harían falta para **volver a preparar las animaciones** con `tools/bake_character_animations.gd`; en ese caso
  hay que bajar otra vez la *Universal Animation Library 1 y 2 (Standard)* de Quaternius (CC0) y los
  *Universal Base Characters*, y descomprimirlos en `assests/Assets 3d/descargas_claude/x/`.
- La carpeta `.godot/` (caché de Godot): se regenera sola.

## 3. Comprobar que todo funciona
Las cuatro pruebas de `docs/HANDOFF.md` §3 (de una en una). Deben salir NAMES CHECK PASSED, COVERAGE DONE con 0
SCRIPT ERROR, SOCIAL SIM CHECK PASSED y TESTS PASSED.
Para capturas del pueblo: `tools/screenshot_3d.gd` (instrucciones dentro del archivo; con Flatpak, guardar dentro
del proyecto, no en /tmp).

## 4. Lo siguiente que hay que hacer (en este orden)
1. **Pasar a 3D los objetos quietos que siguen planos** (coste bajo): pozos, farolas, tienda de campaña, cocina del
   campamento, tablón de misiones, huertos, compostador y detalles menores. Mismo método que los pinos y rocas:
   el escenario 3D busca el objeto 2D, pone un modelo 3D en su sitio y oculta el dibujo plano mientras el 3D está
   activo (ver `_scan_nature_sources` / `_sync_nature_3d` en `scripts/visuals/WorldStage3D.gd`).
2. **Ampliar la aldea**, pasos 1 y 3 de `docs/PLAN_AMPLIAR_ALDEA.md`: solares de tres tamaños y barrios nuevos
   separados (Lago, linde del Bosque, Molino del este). **Presentar el plan al usuario y esperar su visto bueno**
   antes de tocar casas y caminos.
3. **Animales en 3D** (coste medio): necesitan modelo y animaciones propias, como los personajes.
4. Más adelante: sauces del lago (textura rara), carteles flotantes, pinos 2D que quedan arriba a la izquierda,
   cuerpos de personajes con más estilo (enlaces en la bóveda, nota «Assets de pago»).

## 5. Dónde está todo lo escrito
- Registro de la estética 3D, paso a paso: `docs/REGISTRO_ESTETICA_3D.md`.
- Estado general y reglas: `docs/HANDOFF.md` (§7) y `CHANGELOG.md`.
- Bóveda de Obsidian: `GameVault/` → `02_Sistemas/Estética Retro 3D.md`, `05_Roadmap_y_Lore/Tablero.md`,
  `05_Roadmap_y_Lore/Assets de pago.md`, diario `06_Diario/`.
- Reglas para el agente: `CLAUDE.md` (español, breve, sin código en los mensajes, una pregunta al final).

## 6. Mensaje para pegar al agente en el otro ordenador
> Lee `CLAUDE.md`, `docs/HANDOFF.md` y `docs/CONTINUAR_EN_OTRO_PC.md`. Seguimos con el punto 4.1: pasar a 3D los
> objetos quietos que siguen planos (pozos, farolas, tienda, cocina del campamento, tablón de misiones, huertos,
> compostador). Antes de empezar, dime el plan en pocas líneas.
