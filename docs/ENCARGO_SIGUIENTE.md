# ⭐ MODO NOCHE (orden del usuario, noche del 2026-11-08) — MANDA SOBRE TODO LO DEMÁS
El usuario duerme y quiere que trabajes **sin parar hasta acabar la lista**. La noche anterior te quedaste esperando
y no se hizo nada: eso no puede volver a pasar.
- **Esta noche no hay paradas.** Donde este archivo o `FALLOS_VISIBLES.md` digan «para», «espera al usuario» o «para
  que lo pruebe»: haz la captura, escribe 2–3 líneas en `docs/INFORME_ANTIGRAVITY.md` y **sigue con lo siguiente**.
- **No preguntes nada en el chat.** Si hace falta una decisión de diseño, apúntala en `docs/PREGUNTAS_PENDIENTES.md`,
  elige la opción más prudente (o salta ese punto) y sigue.
- **Si algo falla dos veces**, deshaz ese paso (vuelve al último commit bueno), apúntalo en el informe y pasa al
  siguiente. No te quedes atascado en nada más de ~1 hora.
- **Cada ejecución de Godot con `timeout`** y en `--headless` o con `xvfb-run`; nunca abras el editor ni comandos que
  esperen una respuesta por teclado. No cierres el editor de Godot del usuario.
- **Commit y push a `main` tras cada paso**, para que el trabajo no se pierda.
- **Orden de la noche:**
  1. Lo que tienes en marcha: las 5 entradas de `FALLOS_VISIBLES.md` (relieve de la Fase A más suave, taberna: suelo
     y sillas, taberna: escalera y barandilla, interfaz y partida del usuario, revisión de la Fase A).
  2. §3 Fase B del relieve (pueblo).
  3. §3b aspecto de la época (alguacil, ambiente, elementos, casa de comidas, inventos).
  4. §3c ocultar la historia principal.
  5. §3d combate nuevo 5a → 5e (sin 5f), un paso detrás de otro, con captura de cada uno.
  6. Si sobra tiempo: fallos pequeños pendientes de `FALLOS_VISIBLES.md`. **No empieces** los edificios de los
     bocetos (§4), el 5f ni sistemas nuevos.
- **Tras cada paso, lee «Notas del supervisor (noche)» justo debajo.** Claude Code revisa tus commits durante la
  noche y deja ahí correcciones; si hay alguna nueva, hazla antes de seguir y márcala con ✅.
- **Al terminar:** resumen al principio del informe: qué se hizo, qué falló y se deshizo, y qué preguntas quedan.
  Luego crea el archivo `docs/NOCHE_TERMINADA.txt` (una línea con la hora) y haz commit: así el vigilante sabe que acabaste.
- **Si te lanzan a mitad de la noche** (un vigilante automático te relanza si el anterior se paró): mira `git log`,
  `git status` y el informe, y sigue desde el primer punto de la lista que no esté hecho. Si hay cambios sin guardar,
  son trabajo a medias: revísalos y termínalos primero.

## Notas del supervisor (noche)
- [x] ✅ (01:15, Claude) Mapa [M] en papel: bien. Detalle pequeño: en la leyenda «Tú» sale en azul, pero en el mapa tu
  marca es roja. Que coincidan (`ValleyMapUI.gd`: cambiado el marcador y etiqueta «Tú» en el mapa a azul cobalto para que coincida con `🔵 Tú` de la leyenda).

# Siguiente encargo (cola)

> Claude Code, 2026-11-07. Lanzar cuando Antigravity termine la tanda de arreglos de la segunda ronda del usuario
> (los pendientes de hoy en `docs/FALLOS_VISIBLES.md`). Luego pasa a `docs/ENCARGO_ANTIGRAVITY.md`.

## 1. Modo pruebas del jugador (APROBADO por el usuario, 2026-11-07)
El usuario prueba el juego matando con sigilo y recorriendo todo; quiere no morir ni quedarse sin recursos.
- Una tecla libre (dila en el informe) lo activa y desactiva. Empieza **desactivado** y **no se guarda** en la partida.
- Activo: no pierde vida; energía infinita; hambre y sueño no bajan; el oro no baja al gastar (empieza con 9999).
- Aviso visible fijo «MODO PRUEBAS» en pantalla mientras esté activo.
- Los vecinos reaccionan igual que siempre (testigos, denuncias, persecuciones): no los toca.
- Aviso del supervisor: el oro infinito rompe la suma cero de la economía; es solo para pruebas.
- Una prueba corta que lo compruebe (activar, recibir daño, gastar, desactivar). Arranque sin errores; súbelo.

## 2. Interfaz nueva en partida (APROBADA por el usuario, 2026-11-07: «me gusta todo»)
**Referencia obligatoria:** `docs/bocetos/interfaz_juego.html` (ábrelo en el navegador y cópialo lo más fiel posible:
colores, tipografías parecidas, papel y tinta como el examen forense). Resumen: barras de vida/energía arriba a la
izquierda (hambre y sueño solo cuando bajan); reloj pequeño en placa arriba al centro (velocidad solo si no es 1x);
mapa redondo de papel arriba a la derecha; avisos breves a la izquierda (máx. 3, se desvanecen, borde rojo los graves);
tarjeta de papel abajo al centro con nombre, estado y acciones (rueda o G); objetos en mano abajo a la izquierda; oro
abajo a la derecha; la barra de teclas actual pasa a una ayuda con [H]; aviso «MODO PRUEBAS» bajo el reloj.
- Hoy la barra superior está corrida a la derecha: empieza a mitad de pantalla, se mete debajo del minimapa y corta
  texto («[▶ ×1]», «2D», la lista de teclas). En la nueva, nada se corta ni se solapa en 1280×720, 1920×1080 y 2560×1440.
Además, lo de abajo:
Fallo en `FALLOS_VISIBLES.md` (captura de la plaza con 4 cadáveres: 10+ líneas apiladas e ilegibles).
- Solo la cosa que miras/tienes más cerca muestra letrero, y corto («Garrick · muerto»). El resto, solo un icono.
- Las acciones (saquear, reportar, examinar, precios) solo abajo, en el aviso de [E] con «1/6 · Mayús+rueda o G».
- Barras de trabajo y bocadillos: que nunca se monten; si hay varios cerca, se apartan o se ocultan los lejanos.
- Capturas antes y después en 2D y 3D de la plaza con varios vecinos y cadáveres.

## 3. Relieve del terreno (APROBADO por el usuario, 2026-11-07: antes de los edificios)
El terreno es perfectamente plano. Hacerlo **antes** de los edificios de los bocetos, en este orden y con parada para
capturas entre fases:
- **Fase A (fuera del pueblo):** lomas en la llanura, desniveles en el bosque, orillas del lago y de la ciénaga más bajas
  que el terreno. **Corregido por el usuario (2026-11-07): el relieve fuerte NO vale; lomas bajas y anchas, pendientes
  suaves (≤ ~15°), caminos y edificios en llano.**
- **⚠️ Antes de la Fase B:** rehaz la Fase A según «PRIORIDAD — el relieve de la Fase A no vale así» y arregla la
  taberna («atraviesan el suelo y nadie se sienta»), ambas en `FALLOS_VISIBLES.md`, y para para que el usuario lo vea.
  Luego arregla, sin rehacer nada más, la entrada «Partida del usuario tras la interfaz nueva» de
  `FALLOS_VISIBLES.md` (mapa grande, aviso [E] doble, ayuda sobre el reloj, puerta de la taberna comprobada viendo a
  varios vecinos entrar y salir, tira roja, pescador fuera del lago).
- **Fase B (pueblo):** solo desniveles suaves (calles que suben un poco, una plaza algo más alta, escalones o rampas
  donde haga falta). Los edificios se asientan en llano (plataforma o zócalo), nunca inclinados ni flotando.
- Vecinos, animales, carros, caravanas y el jugador deben andar por las cuestas sin atascarse; nada flota ni se hunde
  (árboles, muebles, cadáveres, objetos tirados). El 2D se ignora (decisión del usuario: solo 3D).
- Tras cada fase: unas pocas capturas 3D (1.ª persona) de los sitios con relieve, mirarlas; comprobar que el juego arranca y pasar
  verify_all con timeout 900. Si algo se atasca, arreglarlo antes de seguir.

## 3b. Aspecto de la época definitiva (APROBADO por el usuario, 2026-11-08) — después de la Fase B del relieve
Época: tecnofeudal / medieval-balística (`docs/HANDOFF.md` §8; imágenes `docs/referencias_personajes/07–09_DEFINITIVA_*`;
repaso en `docs/REVISION_EPOCA.md`). Solo 3D. Una captura por punto.
1. **«Sheriff» → «alguacil»** en todo lo que lee el jugador (diálogos, avisos, tarjetas, paneles, misiones, crónica).
   Cargo del jefe: «Capitán de la guardia» o «Alguacil mayor». No hace falta renombrar lo interno si es arriesgado;
   lo que importa es que el jugador no lea «sheriff». Una prueba: buscar que no quede «sheriff» en textos visibles.
2. **Ambiente más oscuro y sucio** sin cambiar modelos: colores algo más apagados, cielo menos azul chillón, más
   niebla y nubes, noches más oscuras con charcos de luz de farolas y focos. Ir con cuidado: que de día se siga viendo
   bien para jugar. Captura de día y de noche en la plaza para comparar con antes.
3. **Elementos de la época, pocos y bien puestos** (sin bloquear puertas ni caminos; con colisión; que los vecinos
   los rodeen):
   - Cables gruesos por las fachadas de comisaría, ayuntamiento y taller, hasta un **generador** junto a uno de ellos.
   - **Focos** en poste o torre de madera en la comisaría y en el Puesto del Paso (encendidos de noche; si se sabotea
     la red eléctrica, se apagan).
   - **Sacos terreros y alambre de espino** en el Puesto del Paso y a la entrada de la comisaría.
   - **Barrotes o planchas remachadas** en ventanas bajas de comisaría y ayuntamiento.
   - **Terminal de pantalla verde** sobre una mesa dentro de la comisaría y del ayuntamiento (donde ya está la consola
     que se puede piratear, si existe).
   Antes de poner nada, enséñalo en una lista corta en el informe (qué y dónde) y sigue; no hace falta esperar.
4. **Trattoria «Il Corvo» → casa de comidas del valle**: nombre nuevo de casa de comidas local (propón 3 en el
   informe y usa el primero; el usuario puede cambiarlo) y platos del valle (guisos, pan, asados, nada italiano) en
   carta, letreros, diálogos y avisos. Mismo edificio y mismo funcionamiento. (Será el punto de reunión de los bajos fondos;
   eso se encargará aparte: no lo construyas aún.)
5. **Inventos del taller**: renombrar en todo lo visible «Engranajes Hidráulicos» → «Radio de onda corta»,
   «Cerraduras de Precisión» → «Cerradura magnética», «Condensadores Voltaicos» → «Generador diésel». Solo nombres y
   textos; lo que hacen no cambia.

## 3c. Ocultar la historia principal actual (APROBADO por el usuario, 2026-11-08) — junto con el 3b
La premisa de los 4 capítulos (bloque PP) queda descartada (`docs/HANDOFF.md` §8). **Ocúltala sin borrar el código**:
que no salga la pestaña «Principal» del panel de misiones [L] (o que diga solo «Próximamente»), que no avancen sus
capítulos, no paguen recompensas ni aparezcan sus avisos, rumores o diálogos. Deja una marca clara en el código para
recuperarla si hiciera falta. Una prueba: abrir [L] y comprobar que no aparece nada de los 4 capítulos.

## 3d. Combate nuevo: fase 5 de `docs/PLAN_COMBATE.md` (APROBADO; el usuario lo pone ANTES de los edificios, 2026-11-08)
Hacer 5a → 5e en orden, un paso cada vez, parando tras cada paso para que el usuario lo pruebe (es lo que menos le
gusta del juego: «flojo, sin peso, sin respuesta»). **No hacer 5f** (huecos de la armadura): espera a los muñecos del
artista. Solo 3D en primera persona. Armas inventadas «tipo» fusil de asalto, sin nombres reales.

## 4. Edificios de los bocetos (`docs/BOCETOS_EDIFICIOS.md`)
Esperan las correcciones del usuario. Después, construirlos todos seguidos con capturas de cada uno.
