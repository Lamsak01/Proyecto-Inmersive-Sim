# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Migración «el mundo sale solo del editor»** (`docs/PLAN_MUNDO_DESDE_EDITOR.md`, aprobado). **Una sola sesión de Claude
toca el código del mundo** (la que hizo este avance; el usuario lo confirmó el 2026-11-11) y el usuario no edita el mapa
mientras dure. Paso 0 hecho (inventario). **Paso 1 en curso.**

## b) Último avance completado
- 2026-11-11: paso 1, primera tanda. Los 29 edificios fijos son escenas (`mapa/edificios/<id>.tscn`: Muros, Interior,
  PisoAlto, Tejado, Muebles, Marcas) y el juego las carga donde esté su pieza de Mundo3D. Borrado su código de dibujo
  (`WorldStageBuildings3D.gd` 2.720 → 540 líneas), sus fotos viejas y `tools/hornear_edificios.gd`. Partes móviles por
  etiqueta (`scripts/visuals/PartesEdificio3D.gd`). Herramienta: `tools/convertir_edificios.gd`.
- Medido: inventario «dobles» 885 → 0, «quieto» 697 → 609; puertas 29/29; sondeo 29/29; 51 fotos antes/después iguales
  salvo la textura de los muros corrida unos centímetros.
- Detalle para quien siga: `docs/specs/REGISTRO_EDITOR_3D.md`, sección «Edificios como escenas».

## c) Siguiente paso técnico inmediato
Seguir el paso 1, en este orden:
1. **Marcas para la lógica** (grupo «Marcas» de cada escena, `Marker3D` con `id_marca`): camas, mesas y puestos de
   trabajo de cada casa y tienda (`VillageWorldBuilder`), luego posada, casa de comidas, hospital, comisaría… El código
   lee la marca en vez de su número y el número se borra en el mismo cambio. Empezar por casas y tiendas (lo más simple).
2. **Capilla**: 14 muebles salen fuera del edificio (fallo visible); están así también en su escena: recolocarlos.
3. **Casas de recién llegados**: una escena base y fuera el dibujo por código que queda.
4. **Planta y puerta desde la escena** (tamaño y lado de la puerta como propiedades de la pieza, no números del código).
Volver a medir con el inventario al cerrar cada grupo (`docs/specs/PRUEBAS.md`).

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
- No se ha pasado `verify_all.gd` tras este avance (solo puertas, sondeo, inventario y fotos): pasarla al cerrar el paso 1.
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración; el inventario aún da 609 cosas en
  el sitio viejo (plantas hechas por código, farolas, solares, suelo) y 137 en otro sitio (pasos 2 y 3).
