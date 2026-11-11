# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Migración «el mundo sale solo del editor»** (`docs/PLAN_MUNDO_DESDE_EDITOR.md`, aprobado). **Una sola sesión de Claude
toca el código del mundo** (la que hizo este avance; el usuario lo confirmó el 2026-11-11) y el usuario no edita el mapa
mientras dure. Paso 0 hecho (inventario). **Paso 1 en curso.**

## b) Último avance completado
- 2026-11-11: paso 1, segunda tanda. Los sitios de las 5 familias fundadoras (9 edificios: 4 tiendas, 4 casas y la
  botica) son **marcas** en su escena (`mapa/marca.gd`, grupo «Marcas»: `trabajo`, `trabajo_familiar`, `cama_1`,
  `cama_2`, `mesa`, `puesto`, `cofre`). `VillageWorldBuilder` las lee con `Marca.sitio(id_edificio, marca)` y sus
  números están borrados. Herramienta que las creó: `tools/marcar_edificios.gd` (no pisa marcas que ya existan).
- `Marca.sitio` devuelve el sitio en el mapa ORIGINAL (centro original del edificio + posición local): es lo que
  esperan las funciones `_add_*` y `setup_npc`, que lo traducen con las anclas. Cambiará al quitar las anclas (paso 4).
- Medido: 173 sitios (vecinos, fichas de oficio, puestos, cofres) idénticos antes y después; sondeo 29/29, viejos 0.
- Antes (primera tanda): los 29 edificios fijos son escenas; detalle en `docs/specs/REGISTRO_EDITOR_3D.md`.

## c) Siguiente paso técnico inmediato
Seguir el paso 1, en este orden:
1. **Más marcas**: oficios en solares (`VillageTrades` + `VillageLots.shop_house_layout`, que comparte la posada de
   `VillageCivic`; ojo: cantero, granjero, ganadero y leñador trabajan fuera del edificio), luego posada, casa de
   comidas, hospital, comisaría, iglesia. Ampliar `tools/marcar_edificios.gd`, leer la marca y borrar el número en el
   mismo cambio. Después, las paredes invisibles de camas, mesas y mostradores (hoy números junto a cada edificio).
2. **Capilla**: 14 muebles salen fuera del edificio (fallo visible); están así también en su escena: recolocarlos.
3. **Casas de recién llegados**: una escena base y fuera el dibujo por código que queda.
4. **Planta y puerta desde la escena** (tamaño y lado de la puerta como propiedades de la pieza, no números del código).
Volver a medir con el inventario al cerrar cada grupo (`docs/specs/PRUEBAS.md`).

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
- No se ha pasado `verify_all.gd` tras este avance (solo puertas, sondeo, inventario y fotos): pasarla al cerrar el paso 1.
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración; el inventario aún da 609 cosas en
  el sitio viejo (plantas hechas por código, farolas, solares, suelo) y 137 en otro sitio (pasos 2 y 3).
