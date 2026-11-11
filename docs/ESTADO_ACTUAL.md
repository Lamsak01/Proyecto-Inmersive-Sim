# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-12, Claude Code, portátil. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**El usuario va a trabajar con el editor del mapa** (quiere mover edificios y distancias a mano): guía al día en
`docs/EDITOR_MAPA_GUIA.md`; editor ajustado al mapa ×5 (maqueta, referencia, río); sondeo de edificios movidos 29/29.
Fallos de su partida ×5 (`docs/FALLOS_VISIBLES.md`): arreglados el lago, el puente y los vecinos en la orilla, la mancha y la
losa, los dibujos 2D y 3D en sitios viejos y Sora. Quedan: caminos (franja gigante / calle estrecha: decidir anchos con el
usuario), sombra larga de los edificios, y la vista desde arriba enseña poco (zoom). Aviso menor: al mover la biblioteca en
el editor, sus sillas y la mesa se solapan (aviso amarillo, no rompe nada).

## b) Último avance completado
- 2026-11-11 (sobremesa): editor del mapa 3D más claro (sol y cielo en la maqueta, sin aros de luces, nombres sobre los edificios). 9 fallos nuevos de la partida en 1.ª persona apuntados en `FALLOS_VISIBLES.md` («Segunda partida»), sin arreglar: el usuario los deja para después.
- 2026-11-11/12: mapa ×5 con el mecanismo de estiramiento por anclas y repaso de ~45 sitios fijos que seguían en el mapa antiguo (pozos, camas, celda, carro, corral, tienda del jugador…); antes, los 6 puntos del plan del día (posada, bandidos, Caso I día 2, césped, animales, reñidero) y la reorganización del repositorio.
- 2026-11-12 (noche anterior): conversión a 3D terminada y en `main` (etiqueta `fin-paso-a-3d`): cuerpos 3D de
  protagonista y vecinos, pisos y sótanos reales, nadar y bucear (30 s de aire), vista/oído con alturas, manos en 1.ª
  persona, agua con movimiento, modo 2D borrado, rendimiento (plaza ~25 fps en el portátil).

## c) Siguiente paso técnico inmediato
Que el usuario juegue el mapa ×5 (partida nueva: las guardadas no valen) y diga si el tamaño le convence (bajar a ×4 o ×3 es cambiar `Mapa3D.E`, reconvertir las escenas desde las copias `*.antes-x5.tscn` y repoblar). Luego, plan de edificios. Regla nueva para pruebas: dos vecinos «juntos» se colocan como distancia, nunca como dos puntos fijos (`PLAN_MAPA_X3.md` §8).

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
