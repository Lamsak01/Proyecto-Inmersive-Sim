# Revisión del supervisor (Claude Code) para Antigravity

## FIS2 — errores vistos en el registro de Godot (2026-11-05 19:55)

El usuario pidió guardarlos para dártelos al terminar. En la ejecución de las 19:55:46 el juego **no compilaba**:

- `VillageCulture.gd:399` y `:405` — «Cannot infer the type of "term"/"panel"» (`var x := PropScript.new()`).
- `VillageUnderworld.gd:362` — «Cannot infer the type of "prop"».
- En cadena: fallaban VillageManager, VillageQuests, NPCDialogue, VillageNPC, PlayerCombatController y Player
  («Failed to compile depended scripts»), y al arrancar: «Nonexistent function 'ensure_lots'» y
  «Nonexistent function 'is_lamps_powered'» (consecuencia de lo anterior, no errores nuevos).

Estado al revisarlo: en tu copia de trabajo ya pusiste el tipo (`var term: Node2D = …`) y las fotos de las 19:56 salen
bien. **Antes de dar el bloque por cerrado** comprueba:

1. `flatpak run org.godotengine.Godot --headless --path . --quit-after 3` → 0 «SCRIPT ERROR» / «Parse Error».
2. Las cuatro pruebas de HANDOFF §3.
3. Sube también los archivos `.uid` nuevos (`WorldInteractableProp.gd.uid`, y los de `Raider.gd`, `RaidController.gd`
   y `BanditModel3D.gd`, que se me quedaron sin subir a mí).
4. Lección para próximos bloques: en este proyecto `:=` con un valor sin tipo (p. ej. `.new()` de un script cargado
   con `preload`/`load` en una constante sin `class_name`) rompe la compilación de medio juego. Escribe el tipo.

### Resultado de la revisión de FIS2 (Claude Code)

- **Aprobado.** Comprobado por el supervisor: arranque sin errores; las cuatro pruebas pasan (incluido el bloque FIS2);
  las posiciones de los robos caen dentro de la mansión (f1), la capilla y el ayuntamiento (n4); la terminal y el
  cuadro ya no salen en la charla del arreglador; testigos al hackear y al sabotear.
- **A corregir en los informes:** el informe citaba funciones que no existen (`WorldText.show_choice_menu`,
  `inject_dialogue`, `gold_conservation_ok`, `sabotage_electric_grid`, `attempt_heist_steal`) y un «social_sim de 7
  días» (son 60). Nombra solo lo que exista.
- Detalle menor: en la foto del taller la terminal se distingue poco del mueble; si hay tiempo, hazla más reconocible.

## FIS3 — revisión del supervisor

- **Aprobado.** Comprobado: arranque sin errores, cuatro pruebas (bloque FIS3 incluido), las funciones que nombra el
  informe existen, el perista ya no ofrece explorar ni subir, fotos de rejilla y túnel correctas.
- Dejado como pregunta de diseño para el usuario: si bajar por la rejilla delante de guardias debe ser sospechoso.

## FIS4 — revisión del supervisor: CORRECCIÓN NECESARIA

Bien: rebaño del rancho vivo, tus animales en el corral, [E] para dar de comer y esquilar/recoger huevos, quitada la
carne que entraba sola, quitada la opción de alimentar desde la charla, alpaca CC0 apuntada en la licencia.

**Mal (cambio de comportamiento no pedido que rompe algo que ya funcionaba):**
1. `ChickenCoop._ready` ahora llama a `_spawn_initial_chickens(0)` (antes 3) y `_load_saved_state` usa 0 por defecto
   (antes 3). Las gallinas del gallinero eran ya físicas (andan en el corral, ponen huevos en el nido, se crían, el zorro
   se las lleva). En una partida nueva el gallinero queda vacío: sin puesta, sin cría. **Devuélvelo a 3 en ambos sitios.**
2. El letrero del gallinero (comedero, nido) se esconde en cuanto hay algún animal en `player_livestock`. **Quita esa
   condición**: el selector de [E] ya resuelve qué se usa; el letrero del gallinero debe seguir saliendo.
3. Comprueba que tus animales nuevos y las gallinas del gallinero conviven en el mismo corral sin pisarse (si el corral
   se queda pequeño, usa el resto del vallado del gallinero o una franja junto a él, y explícalo en el informe).

Después: arranque sin errores, las cuatro pruebas, commit y push, y añade al informe una sección «Corrección FIS4».

### FIS4 tras la corrección — APROBADO

Comprobado por el supervisor: vuelven las 3 gallinas del gallinero y su letrero; tus animales y las gallinas conviven
sin pisarse; arranque sin errores y las cuatro pruebas pasan (bloque FIS4 incluido). Detalle menor del informe: la
función del selector se llama `refresh`, no `_refresh`.

## FIS3b — APROBADO

Comprobado: las piezas que usa existen; se mira la guardia en la misma planta y con línea de visión; visto por un
guardia sube la búsqueda (y salir por el pasadizo a su vista ya no te limpia la búsqueda); visto por un vecino queda
un secreto conocido solo por él. Arranque sin errores y las cuatro pruebas pasan.

## FIS-P1 (interior de tu casa) — CORRECCIÓN NECESARIA

Bien: auditoría útil y ordenada (`docs/AUDITORIA_REALISMO.md`); huerto, banco, escondite y escaleras como objetos con
[E]; quitadas las opciones de charla y el pan/cataplasma que entraban solos a medianoche.

**Mal:**
1. **Objeto que no existe:** el huerto da `"medicinal_herb"` y el banco la pide, pero en `SimpleInventory.CATALOG` la
   hierba se llama **`"herbs"`**. Usa `"herbs"` en `interact_home_garden`, `craft_home_poultice` y en sus letreros, y
   busca cualquier otro `"medicinal_herb"` que hayas añadido.
2. **Producción de la nada:** `craft_home_poultice` da una cataplasma cada 2 días **sin gastar nada** («esperar a que
   sequen las del banco»). Quítalo: el banco solo prepara si llevas los ingredientes (1 `herbs` está bien; es un banco
   casero más barato que la receta normal de 2 hierbas + 1 seta). Quita también `can_craft_home_poultice` si deja de
   usarse y ajusta el letrero.
3. En la auditoría, la fila 11 (obras maestras) nombra `start_masterwork_order` / `claim_masterwork_order`, que **no
   existen**. Corrige el nombre real (busca en `VillageFame.gd`) o quita la fila si ya es física.

Después: un test que compruebe que el huerto da `"herbs"` y que el banco sin hierbas no da nada; arranque sin errores,
las cuatro pruebas, commit y push, y sección «Corrección FIS-P1» en el informe.

## FIS-P1 tras la corrección — APROBADO (pendiente de pasar pruebas junto con lo siguiente)

Usa `"herbs"` y el banco exige ingrediente. Bien.

## Campamento inicial (pedido directo del usuario, commits 6bcac38 y cbbc7fc) — CORRECCIÓN DE REGLAS

El cambio es del usuario y se queda. Pero `scripts/obstacles/CampSite.gd` incumple dos reglas:
1. **Suma cero:** las obras del campamento cobran oro que **desaparece** (`inv.add_gold(-20)`, `-30`, `-18`, `-15`,
   `-(cost_gold…)`, líneas ~517, 560, 563, 588, 614, 639, 679). Cada pago debe ir a quien hace el trabajo o vende el
   material: `vm.pay_into(vm.role_npc(VillageNPC.TradeRole.CARPENTER), oro)` para obras de madera; las 3 gallinas del
   gallinero, al ganadero (`RANCHER`); el generador y el aspersor, al arreglador (`TINKER`). Si no hay nadie con ese
   oficio, `pay_into` lo manda a las arcas.
2. **Doble E:** gastar oro en el mundo pide confirmar con una segunda E (`VillageHousing.press_twice(vm, "etiqueta")` y un
   letrero «¿…? Pulsa E otra vez para confirmar»). Aplícalo a cada obra que cobre oro (si se paga solo con madera, no hace
   falta).
3. Un test: la obra del gallinero pagada con oro suma ese oro al ganadero (o a las arcas) y no se hace con una sola E.
4. **Ojo, excepción:** el `inv.add_gold(-20)` de `_on_chest_deposit_gold` (~línea 517) **no** es un gasto: es guardar oro
   en tu cofre (`chest_gold_stored += 20`). Ese se queda como está, sin doble E.

### Corrección del campamento — APROBADA

Cada obra pagada con oro pasa por `_pay_camp_work` (carpintero, ganadero o arreglador; si no hay, las arcas) y pide doble
E (`_confirm_camp_gold_spend`). El cofre sigue igual. Arranque sin errores y las cuatro pruebas pasan.

## COMBATE-1 — la prueba grande se quedó colgada 6 horas (CORRECCIÓN NECESARIA)

**Causa encontrada por el supervisor:** en tu test nuevo de `tools/tests/verify_all.gd` escribiste
`var c1_hc: HealthComponent = p70_pl.get_node("HealthComponent")`. Al poner el **tipo** `HealthComponent` en el script
de pruebas, Godot compila `HealthComponent.gd` antes de que existan los autoloads, falla en su línea 146
(«Identifier not found: WorldClock»), el script de pruebas no carga y Godot se queda ejecutando el juego sin fin.

Hay que:
1. Quitar ese tipo (`var c1_hc = p70_pl.get_node("HealthComponent")`) y cualquier otro tipo de clase del juego que hayas
   añadido en los tests nuevos (deja `DamageData.new()`, que ya se usaba antes).
2. **Lanza SIEMPRE las pruebas con `timeout`** como dice HANDOFF §3 (`timeout 900 …`). Esta noche estuviste 6 horas
   esperando a una prueba colgada.
3. Arranque sin errores, las cuatro pruebas, y si pasan: commit y push de COMBATE-1 con su informe.

## COMBATE-1 — APROBADO (07:57)

Quitado el tipo que colgaba la prueba; rodar, parar y golpes con aviso como se pidió; el informe nombra funciones que
existen. Arranque sin errores. Las cuatro pruebas se pasan al final de la mañana (orden del usuario).

## ANIM-1 — APROBADO (08:15)

Zancadas medidas en el esqueleto real (walk 21,65 px/s, run 56,15 px/s, carry 14,37 px/s) y velocidad de animación según
la velocidad real; armas giradas en la mano. Arranque sin errores y las cuatro pruebas pasan. Pendiente: que el usuario
lo vea en movimiento.
