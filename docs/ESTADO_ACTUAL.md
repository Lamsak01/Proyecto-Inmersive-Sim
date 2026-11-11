# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code, sobremesa. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Migración «el mundo sale solo del editor»** (`docs/PLAN_MUNDO_DESDE_EDITOR.md`, APROBADO 2026-11-11, con reglas del
profesional). **Solo la sesión del sobremesa toca el código del mundo**; el usuario no edita el mapa mientras dure.
Paso 0 hecho: `docs/INVENTARIO_MUNDO.md` (885 piezas traducidas dos veces, 697 en el sitio viejo, 103 en otro sitio,
14 muebles de la capilla fuera). Fallos de las partidas ×5 en `FALLOS_VISIBLES.md`: se resuelven con la migración.

## b) Último avance completado
- 2026-11-11 (sobremesa): editor del mapa 3D más claro (sol y cielo en la maqueta, sin aros de luces, nombres sobre los edificios). 9 fallos nuevos de la partida en 1.ª persona apuntados en `FALLOS_VISIBLES.md` («Segunda partida»), sin arreglar: el usuario los deja para después.
- 2026-11-11/12: mapa ×5 con el mecanismo de estiramiento por anclas y repaso de ~45 sitios fijos que seguían en el mapa antiguo (pozos, camas, celda, carro, corral, tienda del jugador…); antes, los 6 puntos del plan del día (posada, bandidos, Caso I día 2, césped, animales, reñidero) y la reorganización del repositorio.
- 2026-11-12 (noche anterior): conversión a 3D terminada y en `main` (etiqueta `fin-paso-a-3d`): cuerpos 3D de
  protagonista y vecinos, pisos y sótanos reales, nadar y bucear (30 s de aire), vista/oído con alturas, manos en 1.ª
  persona, agua con movimiento, modo 2D borrado, rendimiento (plaza ~25 fps en el portátil).

## c) Siguiente paso técnico inmediato
Paso 1 del plan: edificios completos en el editor, por grupos. Empezar por el problema más grande del inventario: los 8
edificios cuyo interior se traduce dos veces (taberna, comedor, molino, hospital, comisaría, taller, ayuntamiento) y la
capilla (muebles fuera). Volver a medir con el inventario al cerrar cada grupo: las cifras tienen que bajar.

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
