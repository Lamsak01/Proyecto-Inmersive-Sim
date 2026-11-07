# Siguiente encargo (en cola: lanzar cuando Antigravity termine las herramientas del detective)

> Claude Code, 2026-11-07. Decidido por el usuario. Cuando el encargo actual esté cerrado, este pasa a ser
> `docs/ENCARGO_ANTIGRAVITY.md`. Reglas de siempre (ver `docs/ESTADO_DEL_JUEGO.md` §5 y la forma de comprobar §3:
> solo verify_all al final con timeout + recorrido de capturas mirado).

## Edificios con el detalle de la trattoria, uno a uno
El usuario quiere que **todos** los edificios tengan el nivel de la trattoria «Il Corvo» (`scripts/systems/VillageRestaurant.gd`
+ `WorldStage3D._build_restaurant_3d`): varias salas con sentido, tabiques con pasos, rutas internas, muebles 3D bien
colocados (no arrinconados), luces, suelos propios, fachada y puerta acordes. Ahora son cuartos diminutos con sprites
sin sentido. **Orden (los que pisa el detective primero):**
1. **Comisaría y cárcel** (recepción, despacho del comisario, sala de interrogatorios, calabozos con rejas de verdad,
   armero). Quitar las rejas verdes gigantes, el cajón suelto y el cepo sin sentido.
2. **Morgue / hospital** (sala de autopsias con mesa, estantes de frascos y reactivos, cámara de cuerpos, consulta).
3. **Capilla del Alba** (nave con bancos, altar, confesionario, sacristía) — sin tocar nada de la secta.
4. **Taberna «El Jabalí Dorado»** (barra, salón, cocina, habitaciones, sótano del club).
5. **Biblioteca** (salas de lectura, estanterías, archivo) y que **«Leer un rato» haga algo real** (p. ej. consultar
   libros que sirvan como pistas o conocimientos para los casos).
Un bloque por edificio, con capturas antes y después. Si un edificio crece, muévelo o recoloca lo de alrededor sin
romper caminos (usa `tools/tests/free_space_probe.gd`).

## Arreglos de la lista `docs/FALLOS_VISIBLES.md` que vayan saliendo al paso
Como mínimo: quitar la cama de la trattoria (despacho del dueño), mover la trattoria lejos del cementerio (calle
principal o plaza), quitar el huerto vecinal del camino, puertas distintas según la fachada.

## Agrandar lo de alrededor (decidido por el usuario, 2026-11-07; recomendación de Claude Code)
El usuario siente todo «muy comprimido» y pidió un mapa ~3 veces más grande. Decisión: **el pueblo se queda como
está** (estirarlo rompería posiciones escritas a mano por todo el código); se **agranda y separa el entorno**, en 2–3
bloques:
1. **Campamento inicial fuera del pueblo**, junto al lago del oeste (tienda, hoguera, gallinero, Toby), con un camino
   hasta el pueblo que se tarde en recorrer. Quitar el segundo muelle 2D, recolocar el lavadero (arroyo o fuente) y
   que el agua bloquee el paso.
2. **Bosque ~3 veces más grande y alejado**, espeso, con borde irregular y natural (nada de líneas rectas), claros,
   matorral, troncos caídos; árboles nuevos que no se vean «arrugados» ni se solapen con muros ni muebles.
3. **Llanura y ciénaga separadas y más amplias.** Animales que **deambulen y se repartan** (no pegados al nido ni
   siempre juntos). **Sapos con modelo 3D** basado en su sprite (sapo verde de pie con ropa roja). Quitar los conos de
   visión de depuración.
Comprueba que vecinos, recados nocturnos, expediciones y rutas siguen llegando a sus sitios. El rendimiento está
aparcado por el usuario, pero no dupliques vecinos ni animales sin motivo.
