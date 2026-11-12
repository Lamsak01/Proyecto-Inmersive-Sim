# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Migración «el mundo sale solo del editor»** (`docs/PLAN_MUNDO_DESDE_EDITOR.md`, aprobado). **Una sola sesión de Claude
toca el código del mundo** (la que hizo este avance; el usuario lo confirmó el 2026-11-11) y el usuario no edita el mapa
mientras dure. Paso 0 hecho (inventario). **Paso 1 en curso.**

## b) Último avance completado
- 2026-11-11: paso 1, tercera tanda. **Casa de comidas**: 20 marcas en su escena (fogones, encimera, colgadero,
  `puesto`, piano, `mesa_reservado`, botellero, `cama_1`, `cama_2`, `cofre`, `mesa_1..5`, `mesa_terraza_1..5`).
  `VillageRestaurant.sitio(M_…)`, `dining_tables()` y `terrace_tables()` las leen; números borrados.
- Segunda tanda: las 5 familias fundadoras (9 edificios, 39 marcas) leídas por `VillageWorldBuilder`.
- Cómo funciona: `mapa/marca.gd` (`Marker3D` con `id_marca`, grupo «Marcas»). `Marca.sitio(id_edificio, marca)` da el
  sitio en el mapa ORIGINAL (centro original + posición local): lo que esperan `_add_*` y `setup_npc`, que lo
  traducen con las anclas. Cambiará al quitar las anclas (paso 4). Crear marcas: `guardar()` de
  `tools/marcar_edificios.gd` (no pisa las que existan; siempre con ventana).
- Medido: sitios, asientos y 2.702 cosas del mapa idénticos antes y después; sondeo 29/29, viejos 0.

## c) Siguiente paso técnico inmediato
Seguir el paso 1, en este orden:
1. **Más marcas en edificios únicos**: taberna (`VillageTavern`, el mayor: ~120 números), hospital y morgue,
   comisaría, iglesia, ayuntamiento, albergue, escuela, biblioteca. Mismo método: marcar desde los números, leer la
   marca, borrar el número. Quedan como números: salas, pasos, tabiques, sillas (±14,5 de su mesa) y decorado suelto.
2. **Capilla**: 14 muebles salen fuera del edificio (fallo visible); están así también en su escena: recolocarlos.
3. **Casas y tiendas de solar con escena base**: incluye los oficios en solares y la posada (`VillageTrades`,
   `VillageCivic`, `VillageLots.shop_house_layout`), que comparten molde con lo que se construye durante la partida.
4. **Planta y puerta desde la escena** (tamaño y lado de la puerta como propiedades de la pieza, no números del código).
Volver a medir con el inventario al cerrar cada grupo (`docs/specs/PRUEBAS.md`).

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
- No se ha pasado `verify_all.gd` tras este avance (solo puertas, sondeo, inventario y fotos): pasarla al cerrar el paso 1.
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración; el inventario aún da 609 cosas en
  el sitio viejo (plantas hechas por código, farolas, solares, suelo) y 137 en otro sitio (pasos 2 y 3).
