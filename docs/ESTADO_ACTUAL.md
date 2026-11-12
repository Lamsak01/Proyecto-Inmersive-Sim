# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Migración «el mundo sale solo del editor»** (`docs/PLAN_MUNDO_DESDE_EDITOR.md`, aprobado). **Una sola sesión de Claude
toca el código del mundo** (la que hizo este avance; el usuario lo confirmó el 2026-11-11) y el usuario no edita el mapa
mientras dure. Paso 0 hecho (inventario). **Paso 1 en curso.**

## b) Último avance completado
- 2026-11-11: paso 1, tandas 2 a 8. **138 marcas en 22 edificios** (todos los edificios únicos): las 5 familias fundadoras (tiendas, casas y
  botica), casa de comidas, taberna, hospital y morgue, comisaría, capilla, ayuntamiento, albergue, escuela, biblioteca,
  molino
  abandonado, mansión, casa grande, terminales (comisaría, ayuntamiento, taller) y expositor de la herrería. El código las lee y sus números están borrados.
- Cómo funciona: `mapa/marca.gd` (`Marker3D` con `id_marca`, grupo «Marcas» de `mapa/edificios/<id>.tscn`).
  `Marca.sitio(id_edificio, marca)` da el sitio en el mapa ORIGINAL (centro original de la escena + posición local): lo
  que esperan `_add_*` y `setup_npc`, que lo traducen con las anclas. Cambiará al quitar las anclas (paso 4).
- Método de cada tanda: script temporal en `tools/tests/_tmp_*.gd` (no se guarda) que calcula los sitios con el código
  viejo y llama a `guardar()` de `tools/marcar_edificios.gd` (con ventana) → leer la marca → borrar el número →
  comparar un volcado de sitios y de todo `entities_root` antes y después. Ojo: el centro de la escena no siempre es
  el centro del solar (ayuntamiento, biblioteca): restar siempre el `centro_original` de la escena.
- Arreglado de paso (sin probar jugando): jugador rescatado → camilla real; inspector al amanecer → escritorio real;
  aviso del expositor de armas. Medido: sondeo 29/29, viejos 0; `partida_caso1.gd` completa; `fisica_3d.gd` PASSED.

## c) Siguiente paso técnico inmediato
Seguir el paso 1, en este orden:
1. **Marcas de edificios únicos: hechas**, `verify_all.gd` en verde (118 bloques) e inventario medido (609 / 138). Quedan como números a propósito: rejas y puerta de la celda, bancos de
   la capilla, salas, pasos, tabiques, sillas (pegadas a su mesa), paredes invisibles de muebles y decorado suelto.
2. **Capilla: hecha** (6 muebles estaban a 170 m; recolocados en su escena y vistos en foto).
3. **Casas y tiendas de solar con escena base**: incluye los oficios en solares y la posada (`VillageTrades`,
   `VillageCivic.inn_guest_beds`, `VillageLots.shop_house_layout`): comparten molde con lo que se construye en partida.
4. **Planta y puerta desde la escena** (tamaño y lado de la puerta como propiedades de la pieza, no números del código).
Volver a medir con el inventario al cerrar cada grupo (`docs/specs/PRUEBAS.md`).

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración; el inventario aún da 609 cosas en
  el sitio viejo (plantas hechas por código, farolas, solares, suelo) y 137 en otro sitio (pasos 2 y 3).
