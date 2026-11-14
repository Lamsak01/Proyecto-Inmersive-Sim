# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-14, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Caso I jugable (usuario lo juega desde el 14)**: aviso del guardia confirmado; cuerpo, custodia, autopsia solo en la
morgue y tablero arreglados el 14 (`Case1Aviso.gd`, `VillageCase1.gd`, `DetectiveUI.gd`; partida automática 25/25).
Pendiente: molino con aspecto de molino (para después); preguntar a cualquier vecino por «la mujer del arroyo» (propuesto).
**Diálogos provisionales**: `scripts/ui/dialogo/`, `NPCMenuDialogo.gd`, `NPCCharla.gd` + `resources/dialogos/frases_vecinos.json`.
**Fin de semana 14/15**: Antigravity en paralelo con `docs/TAREAS_ANTIGRAVITY.md` (regla temporal en `CLAUDE.md`).
**Casas de dos plantas** (2026-11-13): campos «…_ARRIBA» y `ESCALERA` en el plano (`planta_alta.gd`); en el juego
`scripts/fisica/PisosCasas.gd`; el trozo alto de los muros va en «PisoAlto» (se esconde desde arriba).

## b) Último avance completado
- Paso 1 (edificios): 32 escenas en `mapa/edificios/` con Muros, Interior, PisoAlto, Tejado, Muebles, **Marcas** (282;
  `mapa/marca.gd`, `Marca.sitio(id, marca)` en el mapa ORIGINAL) y **Tabiques** (39). Planta, puerta y ventana:
  `mapa/planta.gd`. Casas de recién llegados: tres casas modelo (`mapa/casa_modelo.gd`). Nada se dibuja por código.
- Paso 2 (exteriores), cerrado el 2026-11-11:
  - **Solares** (41, `mapa/solar.gd`, con el Puesto del Paso): ancla por solar con prioridad baja; cubre 16 px más al
    norte y al sur para su letrero. Las casas de solar no tienen pieza y heredan sitio y giro de su solar.
  - **Zonas** (3, `mapa/zona.gd`: plaza, lago, ciénaga): trozos de campo abierto que se estiran ×5 pero van con su
    pieza (`Zona.estirar`, `estirar_puntos`, `desestirar`, `rect_mundo`); las usan terreno, relieve, `Agua`, `RioLago`,
    la ciénaga que enferma y el mapa del valle (`scripts/ui/ValleMapaPiezas.gd`: edificios y solares desde sus piezas).
- Paso 3 (2026-11-12): **Sitios** (86, `mapa/sitio.gd`): cruces al aire libre ya en el mundo (`Sitio.mundo(id)`,
  `Sitio.serie(nombre)`). Caso I: 3 marcas de edificio.
- Paso 4 (2026-11-12): el juego ya no traduce. Cada pieza guarda su sitio del mundo y lo de dentro va con ella
  (`EdificioEditor.a_mundo`, `Solar.a_mundo`, `colocar_plano`); río y puentes en `Mundo3D.tscn` («Rio», «Cruces»).
  Borrados `mapa/anclas.gd`, la copia `Mundo3D.antes-x5.tscn` y las herramientas de estirar. Las pruebas que escriben
  sitios en el mapa original usan `tools/tests/mapa_viejo.gd`.

## c0) Mandato del usuario (2026-11-14): TODO en 3D, nada de 2D → `docs/specs/PLAN_TODO_3D.md`
El juego es un híbrido (3D lo que se ve; lógica en mapa 2D en píxeles). Contador `bash tools/contar_2d.sh`: **2.425**
(partió de 2.495; terminado = 0). Hechas: tanda 0, 3a (paredes 3D compartidas, `ChoquesMundo3D`) y 4a (todo personaje
lleva su `Cuerpo3D` siempre: `Poblacion3D`, `TallaCuerpo3D`, `AndarMapa`). Siguiente: 4b (el personaje ES su cuerpo) o 5.

## c) Siguiente paso técnico inmediato (lista dada al usuario el 2026-11-13, en este orden)
1. **Tandas de `PLAN_TODO_3D.md`** en orden; las piezas (sillas, camas…) son su tanda 6.
2. **Medir fps con ventana** tras la 4a (sin ventana la física no cambia: 3,8 → 4,1 ms). 3. **Vecinos atascados**: 0 en
8 h; falta que lo confirme él. Banco ante la puerta de la pescadería (`puertas_3d` 28/29, en `FALLOS_VISIBLES.md`).
4. **Interiores que faltan** (taberna 0b, cantera, restaurante). 5. **Herrero arriba** (pregunta 1). 6. **Beta**.

## d) Bloqueos activos
- `verify_all.gd` se para en «V4: …carpenter on site» (ya fallaba antes, 2026-11-13); lo de después no corre.
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla). «No two conscious villagers may overlap» (puerta del restaurante): mejorado el 2026-11-13 (cola en las puertas); con 6 vecinos a la vez aún se juntan algo.
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración (`docs/INVENTARIO_MUNDO.md`).
