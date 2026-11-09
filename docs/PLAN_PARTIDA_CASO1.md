# Plan de partida completa del Caso I

1. Crear la prueba automática `tools/tests/partida_caso1.gd` que camine a pie en 1.ª persona (`move_and_slide`) entre puntos de paso sin teletransportar ni atravesar paredes.
2. Bloque A — Inicio y Claro del arroyo: comprobar carta inicial en las afueras (`(-1180, 50)`), caminar al claro (`(138, -860)`) y examinar con `[E]` el cuerpo y las pistas del claro verificando su anotación en el cuaderno del caso.
3. Bloque B — Molino Viejo y Puente Viejo: caminar al molino (`(188, -1060)`), examinar barro rojo exterior, sótano/reja y las 4 pistas interiores (pajar, hogar, cordel, papel de mesa); bajar al Puente Viejo (`(118, 50)`) y examinar el zapato.
4. Bloque C — Comisaría y Biblioteca: caminar a la comisaría (denuncia archivada) y a la biblioteca (libro-palanca, entrada a la sala oculta, cuaderno de firmas y libro con página arrancada).
5. Bloque D — Resto de pistas del Caso I y Acusación final: recorrer a pie las demás pistas registradas en el Caso I, ejecutar la acusación con el sistema existente, guardar capturas en `docs/capturas_arreglos/caso1/partida/` y documentar el resultado.

## Estado de pistas comprobadas
- ✅ **Inicio en las afueras y Carta de contratación (`Vector2(-1180, 50)`):** el jugador aparece en el camino de las afueras con `HiringLetterPanel` abierto en pantalla y puede cerrarlo con `[E]` / `[Enter]`.
- ✅ **Orilla del arroyo en el claro (`case1_clearing`, `Vector2(138, -860)`):** se alcanza a pie por el sendero del norte, `[E]` funciona (`Examinar orilla del arroyo`) y se anota en el cuaderno del caso (`clue_case1_clearing`). (Arreglo pequeño: `add_to_group("game_ui")` en `scenes/ui_root.gd`).
- ✅ **Cuerpo de la víctima y 6 pistas de la escena del claro (`case_01_forest_woman`, `Vector2(138, -870)`):** tras añadir `_spawn_case1_clearing_corpse()` en `VillageManagerSocial.gd`, el cuerpo se alcanza a pie, `[E]` abre `DetectiveUI` (`Examinar el cuerpo de Clara`) y se anotan en el cuaderno las 7 zonas del cuerpo y las 6 pistas del claro (15 notas en total).
- ✅ **Barro rojo exterior del molino (`mill_red_clay`, `Vector2(120, -1036)`):** añadido `MillRedClayArea`, se alcanza a pie, `[E]` funciona (`Examinar orilla de arcilla`) y se anota en el cuaderno (`clue_mill_red_clay`).
- ✅ **Sótano y reja de hierro del molino (`mill_cellar_grate`, `Vector2(138, -1061)`):** se alcanza a pie entrando al molino, `[E]` funciona (`Examinar reja de hierro`) y se anota en el cuaderno (`clue_mill_cellar_grate`).
- ✅ **Pistas interiores del molino (`mill_hayloft`, `mill_hearth`, `mill_hemp_cord`, `mill_table_paper`):** el pajar, el hogar con ceniza de carbón, el rollo de cordel de cáñamo encerado y el papel sobre la mesa se alcanzan a pie, `[E]` funciona y se anotan en el cuaderno del caso.
- ✅ **Zapato izquierdo en el Puente Viejo (`old_bridge_left_shoe`, `Vector2(95, 38)`):** se alcanza a pie bajando al puente del centro del pueblo, `[E]` funciona (`Examinar zapato`) y se anota en el cuaderno (`clue_old_bridge_left_shoe`).
