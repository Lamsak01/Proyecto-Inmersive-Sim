# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-13, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Caso I jugable de verdad (usuario, 2026-11-13)**: hechos carta en la mochila, guardia que avisa y custodia
(`Case1Aviso.gd`), claro a ~150 m del molino con fosa, preguntas del diario (`Case1Objetivos.gd`,
`docs/specs/OBJETIVOS_CASO1.md`) y barro rojo visible. Falta: que el usuario lo juegue desde el día 2; molino con
aspecto de molino y junto al río (lo dejó para después).
**Diálogos provisionales (2026-11-13)**: ventana `scripts/ui/dialogo/` (caja, tienda, limpieza de texto), menú
`NPCMenuDialogo.gd`, charla `NPCCharla.gd` + `resources/dialogos/frases_vecinos.json`. El usuario la revisa; no es la final.
Hablar para el reloj (`WorldClock.set_dialogue_pause`, prueba `pausa_dialogo.gd`).
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

## c) Siguiente paso técnico inmediato (lista dada al usuario el 2026-11-13, en este orden)
1. **Que el usuario juegue el Caso I desde el día 2** (guardia que habla, dormir, tablón y trampillas arreglados el 14).
   Pendiente de su partida: el pozo con tejadillo no se reconoce (cambiarlo más adelante).
2. **Rendimiento**: sombras del sol (duplican el dibujo). Medio. 3. **Vecinos atascados**: a 0; falta que lo confirme él.
4. **Interiores que faltan** (taberna 0b, cantera, restaurante). 5. **Herrero arriba** (pregunta 1). 6. **Beta**.
**Contexto:** ×5 (`Mapa3D.E`) invisible; pesca, huerto, corral y campamento se rehacen en 3D tras el Caso I.

## d) Bloqueos activos
- `verify_all.gd` se para en «V4: …carpenter on site» (ya fallaba antes, 2026-11-13); lo de después no corre.
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla). «No two conscious villagers may overlap» (puerta del restaurante): mejorado el 2026-11-13 (cola en las puertas); con 6 vecinos a la vez aún se juntan algo.
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración. Inventario 2026-11-12
  (`docs/INVENTARIO_MUNDO.md`): sigue 5.297, quieto 75 (río, luces, sitios del código que quedan), doble 0, otro
  sitio 123 (ruido entre partidas y sitios al aire libre).
