# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-12, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Migración «el mundo sale solo del editor»** (`docs/PLAN_MUNDO_DESDE_EDITOR.md`, aprobado). **Una sola sesión de Claude
toca el código del mundo** y el usuario no edita el mapa mientras dure. Pasos 0 a 3 hechos; **paso 4 en curso** por trozos.

## b) Último avance completado
- Paso 1 (edificios): 32 escenas en `mapa/edificios/` con Muros, Interior, PisoAlto, Tejado, Muebles, **Marcas** (282;
  `mapa/marca.gd`, `Marca.sitio(id, marca)` en el mapa ORIGINAL) y **Tabiques** (39). Planta, puerta y ventana:
  `mapa/planta.gd`. Casas de recién llegados: tres casas modelo (`mapa/casa_modelo.gd`). Nada se dibuja por código.
- Paso 2 (exteriores), cerrado el 2026-11-11:
  - **Solares** (41, `mapa/solar.gd`, con el Puesto del Paso): ancla por solar con prioridad baja; cubre 16 px más al
    norte y al sur para su letrero. Las casas de solar no tienen pieza y heredan sitio y giro de su solar.
  - **Mostradores**: `_register_shop_business_stall` recibe la marca en el mapa original.
  - **Zonas** (3, `mapa/zona.gd`: plaza, lago, ciénaga): trozos de campo abierto que se estiran ×5 pero van con su
    pieza (`Anclas.estirar`, `estirar_puntos`, `desestirar`); las usan terreno, relieve, `Agua`, `RioLago` y mapa del valle.
- Paso 3 (2026-11-12): **Sitios** (86, `mapa/sitio.gd`): cruces al aire libre ya en el mundo (`Sitio.mundo(id)`,
  `Sitio.serie(nombre)`; `Sitio.original(id)` solo para funciones que aún traducen). Caso I: 3 marcas de edificio.
- Método de cada tanda: pasar a piezas → cambiar código y borrar números → volcado antes/después → `verify_all` → fotos.

## c) Siguiente paso técnico inmediato
Paso 4 por tandas, comparando con `tools/tests/volcado_mundo.gd` (choques, zonas, marcas, plantas y
vecinos antes/después). Hechos: terreno, constructor, taberna, restaurante, solares, bosque, choques de 69 muebles
(`mueble.gd` `choque`) y 41 piezas de «Decorado» (metadatos `choque…`), árboles de adorno, postes (`poste_N`), pozos,
tablón y farolas (`ObjetoEditor.mundo/giro`), zonas de fuera. «Objetos» = 10 piezas con uso; ya sin anclas sueltas.
API en el mundo: `add_choque_mundo`, `add_zona_uso_mundo`, `add_marca_3d_mundo`, `no_pisar_mundo`, `Sitio.giro`,
`EdificioEditor.a_mundo/a_plano`. **Posada hecha** (`VillageTavern.al_mundo/al_plano/dentro/mundo`): solo `sitio()` y
`guest_beds()` siguen en el plano para crear vecinos. **Siguiente:** los demás edificios igual (constructor 54,
VillageManagerBase 43, Culture 33, Restaurant 29…); luego `Marca.sitio` → mundo y quitar la traducción de vecinos
(`setup_npc`, `sitios_traducir_npc`, `_sitios_cfg`); luego Grupos de `anclas.gd`, Zonas, ×5 y borrar `anclas.gd`.
**Adiós al 2D (decisión del usuario, 2026-11-12): capas 1 y 2**, no el «cerebro» (vecinos y choques siguen en el mapa
plano). Capa 1 hecha (lista visible 0). Capa 2 casi hecha (tandas 1–7 → marcas invisibles con `tipo_3d`; 2.818 → 44;
sangre, huellas y vagabundos en 3D con `Rastros3D`). Quedan cuerpos de animales, objetos rompibles y espada de `World.tscn`.
**Pesca, huerto, gallinero, campamento, animales de corral del jugador y huerto de casa borrados (usuario, 2026-11-12)**:
se rehacen en 3D tras el Caso I (`docs/VISION_Y_FUTURO.md`, «Jugador»). Río y lago: `scripts/fisica/RioLago.gd`.
Red eléctrica: generador del Arreglador; farolas solo de noche. Corte final pedido por el usuario el 2026-11-12.
Pendiente: tamaños (`VillageRestaurant.RECT`, `HOUSE_PLOTS.size`), `OPENINGS` (mal comparados con el mundo); matas que no esquivan una plaza movida; `RIVER_*`; mapa del valle.

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla). Igual «No two conscious villagers may overlap» (dos vecinos en la terraza del restaurante; 2 de cada 4 veces, 2026-11-12: arreglar).
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración. Inventario 2026-11-12
  (`docs/INVENTARIO_MUNDO.md`): sigue 5.297, quieto 75 (río, luces, sitios del código que quedan), doble 0, otro
  sitio 123 (ruido entre partidas y sitios al aire libre).
