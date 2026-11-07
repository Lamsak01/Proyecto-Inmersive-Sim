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
