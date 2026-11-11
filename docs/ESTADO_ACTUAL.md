# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code, portátil. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
Fallos visibles pendientes de la partida del usuario (`docs/FALLOS_VISIBLES.md`), en el orden aprobado:
1. ✅ Bosque del Caso I: árboles separados (hecho).
2. ✅ Posada: puertas en los 3 cuartos y camas de adulto (hecho).
3. ✅ Los sapos de la Llanura Salvaje son ahora bandidos (hecho).
4. ✅ Caso I con un día de margen (hecho).
5. **Siguiente:** césped sin dibujo repetido · 6. Animales con vida propia · 7. Sala de peleas en las alcantarillas.

## b) Último avance completado
- 2026-11-11: reorganización del repositorio (nuevo `CLAUDE.md`, `docs/specs/`, `docs/archivo/`, filtros de IA).
- 2026-11-12 (noche anterior): conversión a 3D terminada y en `main` (etiqueta `fin-paso-a-3d`): cuerpos 3D de
  protagonista y vecinos, pisos y sótanos reales, nadar y bucear (30 s de aire), vista/oído con alturas, manos en 1.ª
  persona, agua con movimiento, modo 2D borrado, rendimiento (plaza ~25 fps en el portátil).

## c) Siguiente paso técnico inmediato
Césped sin patrón: hierba con manchas irregulares y variación de tono (material del suelo en `WorldStageTerrain3D`).

## d) Bloqueos activos
- Pistas en el fondo del agua: mecanismo listo; el usuario decide cuáles.
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
