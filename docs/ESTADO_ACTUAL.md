# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Migración «el mundo sale solo del editor»** (`docs/PLAN_MUNDO_DESDE_EDITOR.md`, aprobado). **Una sola sesión de Claude
toca el código del mundo** (la que hizo este avance; el usuario lo confirmó el 2026-11-11) y el usuario no edita el mapa
mientras dure. Paso 0 hecho (inventario). **Paso 1 en curso.**

## b) Último avance completado
- 2026-11-11: paso 1, cuarta tanda. **Hospital, comisaría y capilla**: 17 marcas (camilla, mesas de la morgue,
  celda, archivo, escritorio, altar, camas, mesas y puestos de médico, comisario y sacerdote). Los `_hospital_bed_pos`,
  `_morgue_table_positions`, `_jail_cell_pos` y `_church_altar_pos` del pueblo se rellenan de las marcas.
- Antes: casa de comidas (20 marcas, `VillageRestaurant.sitio`) y las 5 familias fundadoras (39 marcas).
- Cómo funciona: `mapa/marca.gd` (`Marker3D` con `id_marca`, grupo «Marcas»). `Marca.sitio(id_edificio, marca)` da el
  sitio en el mapa ORIGINAL (centro original + posición local): lo que esperan `_add_*` y `setup_npc`, que lo
  traducen con las anclas. Cambiará al quitar las anclas (paso 4). Crear marcas: `guardar()` de
  `tools/marcar_edificios.gd` desde un script temporal con los números (no pisa las que existan; con ventana).
- Arreglado de paso (sin probar jugando): el jugador rescatado aparece en la camilla real; el inspector va al
  escritorio real de la comisaría al amanecer.
- Medido: sitios y 9.143 cosas del mapa idénticos antes y después; sondeo 29/29, viejos 0.

## c) Siguiente paso técnico inmediato
Seguir el paso 1, en este orden:
1. **Marcas de los edificios únicos que faltan**: ayuntamiento y albergue (`VillageCivic.hall_spots`,
   `shelter_beds`), escuela, biblioteca, molino y, al final, la taberna (`VillageTavern`, ~120 números). Quedan como
   números: rejas y puerta de la celda, bancos de la capilla, salas, tabiques, sillas y decorado suelto.
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
