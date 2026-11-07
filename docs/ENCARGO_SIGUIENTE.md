# Siguiente encargo (en cola: lanzar cuando Antigravity termine las herramientas del detective)

> Claude Code, 2026-11-07. Decidido por el usuario. Cuando el encargo actual esté cerrado, este pasa a ser
> `docs/ENCARGO_ANTIGRAVITY.md`. Reglas de siempre (ver `docs/ESTADO_DEL_JUEGO.md` §5 y la forma de comprobar §3:
> solo verify_all al final con timeout + recorrido de capturas mirado).

## ORDEN ACORDADO CON EL USUARIO (2026-11-07) — manda sobre el orden de abajo

1. **Arreglos rápidos:** ropa/peinados variados, libro gigante, ropa que atraviesa, conos de depuración de los sapos,
   letreros encimados, no andar sobre el agua, cama de la trattoria → despacho.
2. **Agrandar y separar el entorno** (sección «Agrandar lo de alrededor»): campamento, bosque, llanura/ciénaga,
   animales repartidos, lago (un muelle, sin lavadero), parque, huerto fuera del camino, trattoria lejos del cementerio.
3. **Taberna de 2 pisos** (requisitos abajo).
4. **Ambiente:** cielo con nubes y hora, suelo con textura, árboles nuevos, niebla.
5. **Edificios uno a uno:** comisaría, morgue, capilla, biblioteca («Leer» real), alcantarillas con peleas, rancho
   poblado, tablón legible, puertas distintas.
6. **Sapos en 3D** basados en su sprite.

### Feedback del usuario en los interiores (orden del usuario, 2026-11-07)
- **Taberna:** el usuario ya dio sus requisitos; constrúyela directamente y enséñale capturas al terminar.
- **Paso 5 (resto de edificios):** ANTES de construir ninguno, escribe `docs/BOCETOS_EDIFICIOS.md` con un boceto
  corto de **todos** (por edificio: salas, muebles principales, quién está dentro y qué hace ahí, qué puede hacer el
  jugador). Para ahí y avisa al usuario. Cuando lo corrija, construye todos seguidos sin pararte y deja capturas de
  cada uno al acabarlo. No le preguntes mueble a mueble.

### Cuándo probar (orden del usuario: solo cuando haga falta, no tras cada paso)
- **Tras el paso 1:** una vez `verify_all` (toca vecinos) + capturas.
- **Tras el paso 2:** `verify_all` + **recorrido de capturas largo mirado** (es el cambio más arriesgado: caminos,
  vecinos que se atascan, cosas fuera de sitio). Si algo se rompe aquí, arreglarlo antes de seguir.
- **Tras el paso 3:** `verify_all` + capturas de los dos pisos y de vecinos subiendo/bajando y comiendo.
- **Paso 4:** solo capturas (es visual, no toca reglas).
- **Paso 5:** capturas de cada edificio al terminarlo; `verify_all` **una vez al acabar todos**.
- **Paso 6 y final:** ronda grande con las cuatro pruebas.
Siempre con `timeout`. Entre medias, nada de pruebas.

## Edificios con el detalle de la trattoria, uno a uno
El usuario quiere que **todos** los edificios tengan el nivel de la trattoria «Il Corvo» (`scripts/systems/VillageRestaurant.gd`
+ `WorldStage3D._build_restaurant_3d`): varias salas con sentido, tabiques con pasos, rutas internas, muebles 3D bien
colocados (no arrinconados), luces, suelos propios, fachada y puerta acordes. Ahora son cuartos diminutos con sprites
sin sentido. **Orden (los que pisa el detective primero):**
0. **La taberna (paso 3 del orden acordado) «El Jabalí Dorado»** (orden del usuario, 2026-11-07: «da pena, es el primer edificio que
   quiero que se remodele»). Requisitos del usuario:
   - **Mucho más grande** y **el primer edificio con 2 pisos**: abajo el salón; **arriba los cuartos de huéspedes**
     (escalera de verdad; usa las capas verticales que ya existen, planta 0 y +1).
   - **Mesas con gente sentada** que viene a pasar el rato y a comer (como las cenas de la trattoria: los vecinos
     eligen ir, se sientan en sillas libres y pagan).
   - **Gente jugando al póker** en una mesa (el casino/póker ya existe: que se vea a los vecinos sentados jugando).
   - **El tabernero detrás del mostrador** atendiendo.
   - **Al menos un camarero** trabajando: recoge los pedidos en las mesas y lleva los platos de la cocina a la mesa
     (oficio nuevo al final de `TradeRole`, se ocupa como cualquier vacante; recorridos físicos, nada de teletransporte).
   - **Sótano con el club de peleas clandestinas** (hoy el usuario no lo encuentra nunca: ver `FALLOS_VISIBLES.md`):
     comprobar en partida que abre y tiene gente, y que se pueda descubrir por rumores.
   - Arreglar lo que se ve mal: la «mesa de billar» es un tablero con un rectángulo verde encima y patas de cama.
   **Después de la taberna, antes de la comisaría — cosas que el usuario vio (2026-11-07):**
   - **Ropa y caras variadas para los vecinos:** usar todos los modelos y texturas de `assests/curated_3d/characters/`
     (campesino/explorador, hombre/mujer, 2 texturas de cada, 5 peinados, barba, piel clara/oscura), repartidos de
     forma fija por persona (que el mismo vecino se vea igual siempre) y con algo de lógica por oficio.
   - **Alcantarillas de verdad:** más grandes, con túneles, y el **sitio de las peleas clandestinas** visible (foso o
     círculo, bancos, apuestas) con gente cuando haya pelea.
   - **Tablón de encargos nuevo:** más bonito, y cada papel muestra en pequeño el encargo real (se lee al acercarse);
     aceptar sigue siendo con el menú.
   - **Rancho poblado:** rebaño creíble (vacas, caballos, burros, alpacas, gallinas) con los modelos que ya hay,
     ligado a la economía (crían, se venden), no de adorno.
1. **Comisaría y cárcel** (recepción, despacho del comisario, sala de interrogatorios, calabozos con rejas de verdad,
   armero). Quitar las rejas verdes gigantes, el cajón suelto y el cepo sin sentido.
2. **Morgue / hospital** (sala de autopsias con mesa, estantes de frascos y reactivos, cámara de cuerpos, consulta).
3. **Capilla del Alba** (nave con bancos, altar, confesionario, sacristía) — sin tocar nada de la secta.
4. **Biblioteca** (salas de lectura, estanterías, archivo) y que **«Leer un rato» haga algo real** (p. ej. consultar
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
