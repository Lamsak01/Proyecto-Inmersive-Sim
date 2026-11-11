# Registro de cambios

Cambios del juego, del más nuevo al más antiguo. Añade una entrada al cerrar cada bloque, en lenguaje sencillo.
El historial completo está en `git log`. Lo anterior al 2026-11-09 está en `docs/archivo/CHANGELOG_hasta_2026-11-08.md`.


## 2026-11-11 — Césped sin dibujo repetido (Claude Code, portátil; `main`)
- La hierba tiene manchas irregulares (seca y espesa) y briznas de cerca; de lejos se funde. Sin cuadrícula ni rombos.

## 2026-11-11 — Caso I con un día de margen (Claude Code, portátil; `main`)
- El día 1 llegas, lees la carta (texto provisional) y conoces el pueblo; el caso estalla el día 2 al amanecer con un aviso en pantalla. Los forasteros del molino cuentan sus días desde entonces.

## 2026-11-11 — Llanura Salvaje: los sapos son ahora bandidos (Claude Code, portátil; `main`)
- Los 4 enemigos de la llanura y la ciénaga son bandidos (muñeco 3D de asaltante, botín de chatarra y oro); el letrero de la ciénaga avisa de ellos. Arreglado además que los bandidos quedaban enterrados en terreno alto.

## 2026-11-11 — Posada: puertas en los cuartos y camas de adulto (Claude Code, portátil; `main`)
- Los 3 cuartos de la planta alta tienen puerta de madera que se abre al acercarte y se cierra al irte; las 6 camas miden lo que una cama de verdad.

## 2026-11-11 — Reorganización del repositorio y nuevo reparto de trabajo (Claude Code, portátil; `main`)
- Claude Code pasa a programar; Gemini/Antigravity queda como especialista y auditor bajo demanda. Nuevo `CLAUDE.md` maestro
  (también `GEMINI.md` y `AGENTS.md`), `docs/ESTADO_ACTUAL.md` (45 líneas máx.) sustituye a los traspasos largos,
  `docs/INDICE_SISTEMAS.md` y `docs/specs/` (una especificación por sistema). Historial en `docs/archivo/` (bloqueado a los
  agentes), bóveda de Obsidian bloqueada salvo petición. Filtros de IA (`.claude/settings.json`, `.geminiignore`,
  `.antigravityignore`). Rama de respaldo `backup-antes-reorg`.

## 2026-11-12 — Bosque del Caso I: árboles separados (Claude Code, portátil; rama `mundo-3d`)
- En el bosque del claro ya no hay árboles metidos unos dentro de otros: se quitaron 19 que tenían el tronco pegado a otro. El molino sigue escondido entre los árboles.

## 2026-11-12 — Limpieza: fuera el modo 2D antiguo (Claude Code, portátil; rama `mundo-3d`)
- Ya no existe el tablero plano de baldosas y sprites ([F9] sin Mayús); la vista desde arriba en 3D y la 1.ª persona siguen igual.

## 2026-11-12 — Paso a 3D: sitios en el fondo del agua (Claude Code, portátil; rama `mundo-3d`)
- Preparado para pistas en el fondo del río o del lago: solo se alcanzan buceando. Falta decidir cuáles.

## 2026-11-12 — Paso a 3D, opción B (2): animales grandes, mascotas, bandidos y enemigos con cuerpo completo (Claude Code, portátil; rama `mundo-3d`)
- Cerca de ti, ciervos, jabalíes, perros, bandidos y sapos chocan con paredes y muebles en 3D y contigo; los pequeños siguen igual.

## 2026-11-11 (noche) — Más fluido (Claude Code, portátil; rama `mundo-3d`)
- Plaza 20 → 25 fps, río 18 → 21: el relieve del terreno se recuerda en vez de recalcularse, y los vecinos y animales lejanos se ponen al día menos a menudo.

## 2026-11-11 (noche) — Paso a 3D: bucear (Claude Code, portátil; rama `mundo-3d`)
- Nadando, agacharse te hunde: buceas por el fondo con 30 s de aire (barra 🫧); sin aire pierdes vida hasta morir. Vista verde-azul bajo el agua.

## 2026-11-11 (noche) — Paso a 3D: piso alto y sótano de tu casa de verdad (Claude Code, portátil; rama `mundo-3d`)
- El piso alto de tu casa está de verdad arriba y el sótano bajo tierra; con [E] cambias sin caerte.

## 2026-11-11 (noche) — Paso a 3D, opción B: los vecinos cercanos con cuerpo 3D completo (Claude Code, portátil; rama `mundo-3d`)
- Los vecinos que tienes cerca chocan con paredes, muebles y puertas, suben escaleras y cambian de piso solos; chocan contigo (puedes apartarlos). Los lejanos siguen como antes.

## 2026-11-11 — Arreglos de la partida del usuario, 7b: manos de verdad en 1.ª persona (Claude Code, portátil; rama `mundo-3d`)
- Las manos en 1.ª persona son ahora los brazos del muñeco de los aldeanos (piel y manga), en vez de bolas de color carne.

## 2026-11-11 — Arreglos de la partida del usuario, 7a: el agua se mueve (Claude Code, portátil; rama `mundo-3d`)
- El río y el lago tienen corriente y brillos que ondulan (efecto propio, sin descargar nada).

## 2026-11-11 — Arreglos de la partida del usuario, 6: los cuartos de la posada (Claude Code, portátil; rama `mundo-3d`)
- La planta alta de la posada pasa de 5 cuartos minúsculos a 3 amplios: el de los dueños, el de huéspedes (3 camas) y el tuyo.
- De paso: un bandido muerto o huido cerca de ti dejaba un error repetido cada fotograma (su cuerpo de contacto no se soltaba).

## 2026-11-11 — Arreglos de la partida del usuario, 5: vecinos corriendo en el sitio (Claude Code, portátil; rama `mundo-3d`)
- Un vecino empujado atrás y adelante (por otro vecino parado o por ti en una puerta) ya se da cuenta al segundo y rodea por un lado.
- La simulación de atascos puede empezar a la hora que quieras, contratar un cocinero y dejarte parado en una puerta.

## 2026-11-11 — Arreglos de la partida del usuario, 4: bandidos (Claude Code, portátil; rama `mundo-3d`)
- Los bandidos y jabalíes de las incursiones chocan con paredes y muebles; si huyendo se quedan contra un muro, se dan por huidos.

## 2026-11-10 — Arreglos de la partida del usuario, 3: el cocinero (Claude Code, portátil; rama `mundo-3d`)
- El cocinero salía vestido de vigía con espada y daba hachazos sobre la olla (un número de oficio equivocado). Ahora lleva delantal y remueve la olla.

## 2026-11-10 — Arreglos de la partida del usuario, 2: agacharse en el agua (Claude Code, portátil; rama `mundo-3d`)
- En el agua ya no te agachas (la cámara se hundía bajo la superficie). Hasta que haya buceo.

## 2026-11-10 — Arreglos de la partida del usuario, 1: la pizarra de la escuela (Claude Code, portátil; rama `mundo-3d`)
- La pizarra estaba pegada a la puerta; ahora está en la pared de enfrente, con los pupitres en medio.

## 2026-11-10 — Paso a 3D de verdad: paso 5d, con [E] llegas a lo que está a tu altura (Claude Code, portátil; rama `mundo-3d`)
- En la escalera hablas con quien va unos peldaños más arriba; desde el salón no llegas a la galería ni a las camas de arriba.

## 2026-11-10 — Paso a 3D de verdad: paso 5c, golpes, flechas y balas con altura (Claude Code, portátil; rama `mundo-3d`)
- Los golpes alcanzan a quien está a tu altura (en la escalera sí; en la galería desde abajo no).
- Flechas y balas vuelan con altura: en 1.ª persona van hacia donde miras, solo hieren a quien está a esa altura y se clavan al bajar al suelo.

## 2026-11-10 — Paso a 3D de verdad: paso 5b, el oído con alturas (Claude Code, portátil; rama `mundo-3d`)
- Un ruido llega a los vecinos de otro piso más flojo (a través del suelo, un tercio; bajo tierra, casi nada). Antes no llegaba.
- De paso: si andas contra un vecino, lo apartas poco a poco (antes te cerraba el paso); los sentados no estorban.

## 2026-11-10 — Paso a 3D de verdad: paso 5a, la vista con alturas (Claude Code, portátil; rama `mundo-3d`)
- Testigos, policías y guardias te ven según paredes, puertas y suelos de verdad: desde el salón de la posada se ve a quien se asoma a la galería, no a quien está encima de ti.

## 2026-11-10 — Paso a 3D de verdad: paso 4c, animales grandes y bandidos (Claude Code, portátil; rama `mundo-3d`)
- Ya no atraviesas a bandidos, jabalíes, ciervos ni al ganado grande; conejos, zorros, mascotas, gallinas y crías sí.

## 2026-11-10 — Paso a 3D de verdad: paso 4b, ya no atraviesas a los vecinos (Claude Code, portátil; rama `mundo-3d`)
- Los vecinos cercanos tienen un cuerpo de contacto: chocas con ellos. Dormidos o caídos no estorban.
- Decisión del usuario: esto ahora; más adelante cuerpos completos que choquen con paredes y busquen caminos en 3D.

## 2026-11-10 — Paso a 3D de verdad: paso 4a, vecinos por la escalera (Claude Code, portátil; rama `mundo-3d`)
- Comprobado que los vecinos suben y bajan la escalera de la posada andando; quitado un escalón de golpe al llegar arriba.

## 2026-11-10 — Paso a 3D de verdad: paso 3a, nadar (Claude Code, portátil; rama `mundo-3d`)
- El río y el lago ya no son una pared: vadeas en la orilla y nadas donde no haces pie (lento, sin correr ni saltar, gasta aguante).
- Flotas con la cabeza fuera y sales por la otra orilla; caer al agua honda no duele. Los vecinos aún no entran al agua.

## 2026-11-10 — Paso a 3D de verdad: paso 2c, daño por caída (Claude Code, portátil; rama `mundo-3d`)
- Decisión del usuario: realista. Desde 3 m duele, a 8 m mata, y la caída hiere una parte del cuerpo (sobre todo piernas).
- Preparado para mejoras futuras que reduzcan el daño por caída. Barandillas de la posada a la cintura.

## 2026-11-10 — Paso a 3D de verdad: paso 2b, club y alcantarillas bajo tierra (Claude Code, portátil; rama `mundo-3d`)
- El club de peleas y las alcantarillas están de verdad unos 3 m bajo la calle; en 1.ª persona hay techo de roca.

## 2026-11-10 — Paso a 3D de verdad: paso 2a, la posada con dos plantas de verdad (Claude Code, portátil; rama `mundo-3d`)
- Al subir la escalera de la posada andando estás de verdad más alto; tu piso sale de tu altura.
- Abajo no estorban las barandillas de arriba, ni arriba los muebles de abajo. La cámara va sobre tu cuerpo.

## 2026-11-10 — Paso a 3D de verdad: paso 1b, recorrido por todas las puertas (Claude Code, portátil; rama `mundo-3d`)
- Prueba nueva: el protagonista entra y sale andando por las 29 puertas del pueblo; todas bien. Vecinos atascados: 0.
- Fluidez igual que antes del cuerpo 3D. Paso 1 terminado; falta que el usuario lo juegue un rato.

## 2026-11-10 — Paso a 3D de verdad: paso 1a, el protagonista tiene cuerpo 3D (Claude Code, portátil; rama `mundo-3d`)
- El protagonista anda, choca, cae y salta con un cuerpo 3D de verdad; el resto del juego sigue viéndolo en el mapa como siempre.
- Las paredes del pueblo no se rehacen: se copian en 3D las que hay cerca. El salto usa gravedad 3D (~1,1 m).

## 2026-11-10 — Paso a 3D de verdad: paso 0b, mundo en metros (Claude Code, portátil; rama `mundo-3d`)
- Decisión del usuario: escala uniforme. El mundo 3D mide en metros (una persona, 1,74 m) y tiene las mismas proporciones
  en todas direcciones; en 3D el pueblo es un 15 % más corto de norte a sur. En el mapa del pueblo no se mueve nada.
- Mapa editado por el usuario convertido (copia en `mapa/Mundo3D.antes-3d.tscn`); fotos de edificios rehechas.
- La vista desde arriba sigue cuadrando con el mapa (cámara a 62°, imagen estirada).
- Arreglado: dos vecinos podían quedarse encimados en una puerta (ahora guardan un mínimo de distancia).

## 2026-11-10 — Paso a 3D de verdad: paso 0, preparación (Claude Code, portátil; rama `mundo-3d`)
- Nada cambia al jugar. Copia de seguridad del juego (etiqueta `antes-de-mundo-3d`) y trabajo en una rama aparte.
- La fórmula que pasa del mapa al 3D estaba copiada en unos 20 sitios; ahora hay una sola (`scripts/fisica/Mapa3D.gd`). Fotos antes y después: iguales.
- Nuevas: prueba del paso a 3D, fotos fijas para comparar, mapa del código (`docs/MAPA_DEL_CODIGO.md`) y manuscrito de cambios (`docs/MANUSCRITO_MUNDO_3D.md`).
- Arreglado de paso: una herramienta del editor que no arrancaba y dos pruebas del editor que se quedaron anticuadas cuando el usuario editó el río.

## 2026-11-10 — Más fluido en 1.ª persona (Claude Code, portátil; pedido por el usuario)
- El pueblo dibujado en plano se seguía pintando detrás de la vista en primera persona, a la resolución de la pantalla, aunque no se viera. Ya no.
- Los vecinos a media distancia (unos 14–36 m) piensan y se mueven la mitad de veces, recorriendo lo mismo; los cercanos siguen al detalle.
- En primera persona, los objetos pequeños dejan de dibujarse a más de 25 m y los muebles a más de 50 m (a esa distancia son unos pocos puntos).
- Medido en el portátil (imágenes por segundo): afueras 27→33, plaza 22→29, río 18→23, bosque 27→38, molino 32→40, mansión 35→43.
- Si aún va justo: Ajustes → Gráficos → Sombras «Sin sombras» quita unos 4 ms más por imagen.

## 2026-11-10 — Menú principal, pausa, ajustes y créditos (Claude Code, portátil; pedido por el usuario)
- El juego arranca en un menú principal: Nueva partida, Continuar (la última guardada), Cargar, Ajustes, Créditos y Salir.
- Esc en la partida (sin nada abierto) abre la pausa: seguir, guardar, cargar, ajustes y salir al menú. El pueblo se para mientras está abierta.
- Tres huecos de partida, más el guardado rápido (F5) y un autoguardado al empezar cada día de juego. Cada hueco enseña el día, la hora del juego y la fecha real en que se guardó.
- Ajustes que se recuerdan entre sesiones: pantalla completa o ventana, sincronización vertical, límite de fotogramas, sombras (no / bajas / altas), nitidez de la imagen 3D, suavizado de bordes, sensibilidad del ratón, campo de visión, invertir el ratón y volumen general, de música y de efectos.
- Todas las teclas de juego se pueden cambiar; si eliges una que ya se usaba, las dos se intercambian.
- Créditos provisionales con los autores de los recursos (Quaternius, Kenney, packs comprados, sonidos y Godot). Los autores que no se saben van marcados «por confirmar».
- Salir al menú reinicia el juego para que el pueblo siguiente empiece limpio.

## 2026-11-10 — Controles sin choques (Claude Code, portátil; aprobado por el usuario)
- Los trucos de prueba piden Ctrl para no saltar en una partida normal: Ctrl+T adelanta 2 horas, Ctrl+F1–F4 cambian la velocidad del reloj, Ctrl+F7 el tiempo atmosférico y Ctrl+º el modo pruebas. Ya no salen en la ayuda (H).
- + y − solo hacen zoom (antes también cambiaban la velocidad del reloj).
- Fuera las teclas repetidas: F6 (era igual que P), F8 (igual que º) y F10 (igual que F9). Lista completa en `docs/CONTROLES.md`.
- Dos comprobaciones de la prueba general que fallaban a veces, según cómo fuera la partida de prueba, ahora ponen al vecino en un estado neutro antes de comprobar.

## 2026-11-10 — Menos vecinos atascados y arranque más limpio (Claude Code, portátil)
- Los vecinos ya no se meten en el hueco estrecho entre la herboristería y la pescadería (ni en el del albergue con el hojalatero): rodean la manzana.
- Antes de la pasarela del norte del río siguen la orilla en vez de meterse en el agua donde el río hace curva.
- Prueba de 6 horas de juego: de 1–5 vecinos atascados a 0, sin errores. La prueba ahora da siempre el mismo resultado (antes dependía de la velocidad del ordenador).
- Quitados tres avisos que salían al arrancar el juego, y arreglada la herramienta que pasa el decorado al editor del mapa (no arrancaba).
- Ronda completa de pruebas, todas bien: general (118 bloques), nombres, vida social (60 días), diálogos (568 acciones sin errores) y guardar/cargar 7 días. Tres comprobaciones de la prueba general estaban desfasadas por los cambios del mapa (un punto «seco» junto al río nuevo, un testigo pegado a la casa movida, Toby ausente desde el nuevo inicio en las afueras): ahora buscan su sitio solas. No eran fallos del juego.

## 2026-11-10 — Los trabajos al aire libre siguen a lo movido (Claude Code, portátil)
- Si mueves en el editor del mapa 3D el lavadero, los campos, el rancho, la cantera, el mercado, el mirador, el campamento del contrabandista u otras piezas del exterior, los vecinos van a trabajar, lavar, pasear o comerciar al sitio nuevo. También la cama de urgencias y la morgue del hospital.

## 2026-11-10 — Taberna, restaurante, iglesia y comisaría siguen a su edificio movido (Claude Code, portátil)
- Si mueves la taberna, el restaurante, la iglesia, el hospital o la comisaría en el editor del mapa 3D, los vecinos se sientan en las sillas nuevas, el camarero hace su ronda donde están las mesas, el cura da misa en el altar nuevo y la celda, la morgue y las escaleras funcionan en el sitio nuevo. También el parque, la biblioteca y los otros sitios de ocio, si se mueven.
- Arreglado: los que llegan a mitad de partida (contratados, hijos, oficios vacantes) podían acabar con la casa desplazada el doble.
- Aviso: hay un atasco que ya existía en un paso estrecho de la plaza; queda apuntado.

## 2026-11-10 — Los vecinos siguen a sus casas movidas (Claude Code, portátil)
- Si mueves o giras una casa, una tienda o sus muebles en el editor del mapa 3D, sus vecinos duermen, comen y trabajan en el sitio nuevo (antes iban al hueco viejo). Prueba: 54 de 60 sitios siguen al edificio; los 6 restantes están al aire libre y van en el siguiente paso. Plan y registro: `docs/PLAN_SITIOS.md`.
- Aviso: la partida de prueba del Caso I falla desde antes de este cambio (el jugador no llega al claro); queda apuntado.

## 2026-11-10 — Pincel del mapa (Claude Code, portátil)
- Nuevo panel **Pincel** en el editor del mapa 3D: pinta bosques, rocas, hierba, matorrales o troncos arrastrando el ratón, o copias de tus propios modelos. Goma para borrar, tamaño y «apretado». No siembra en el río, el lago, los edificios ni los caminos. Cada cosa pintada se puede mover luego una a una. Guía: `docs/PINCEL_MAPA_GUIA.md`.

## 2026-11-09 (noche) — Editor del mapa, paso 1: el río y sus puentes (Claude Code)
- Nueva escena **mapa/EditorMapa** para Godot: el valle visto desde arriba con edificios, caminos y árboles de guía. El río se mueve arrastrando sus puntos (y se ensancha en el Inspector); los puentes y vados también. Avisa en rojo si el agua pisa un edificio o un puente no llega de orilla a orilla. El juego usa lo que haya ahí (agua, orillas, choque, vecinos y río 3D). Con los puntos originales el río es idéntico al de antes. Guía: `docs/EDITOR_MAPA_GUIA.md`; plan: `docs/PLAN_EDITOR_MAPA.md`.

## 2026-11-09 (tarde) — Rendimiento, vecinos atascados e informe del Caso I (Claude Code)
- **Rendimiento:** el juego iba lento por el procesador, no por la gráfica. Los vecinos hacían comprobaciones caras (puertas, muros, edificios) contra todos los demás en cada instante, y el motor encadenaba hasta 8 pasos por fotograma para ponerse al día. Ahora lo barato va primero, las huellas de edificios están en caché y hay un tope de 3 pasos a velocidad normal. Portátil: de 3–4 a 12–17 fps. Luego: rejilla de vecinos por paso (cada uno mira solo su zona) y terreno quieto juntado por zonas → 14–21 fps; afueras de 8.400 a 5.300 llamadas de dibujo. Por último, vecinos lejanos simplificados (activado por el usuario) con el muñeco 3D suavizado: 22–45 fps según la zona.
- **Vecinos atascados:** se deslizan por el borde de edificios y orillas en vez de congelarse; 9 → 2 atascos en 4 h de juego.
- **Día de 18 minutos** (antes 6).
- **Informe del Caso I** en la comisaría (bandeja junto a la entrada): pruebas del cuaderno + a quién culpas; queda guardado para el final. Las pistas del caso a las que apuntas ganan a una puerta cercana.
- Partida de prueba del Caso I: 25 ✅ / 0 ❌.

## 2026-11-09 — Caso I: piezas que faltaban para cerrarlo (Claude Code, sin la acusación)
- **El boticario, la criada y el familiar hablan del caso:** cuando ya has hecho la autopsia, vaciado el bolsillo del cuerpo o encontrado la hoja arrancada, aparece una opción nueva al hablarles; lo que cuentan se apunta en el cuaderno.
- **Gabinete forzado en el estudio de la mansión** (cerradura doblada, virutas y el hueco del frasco en el terciopelo) y **hoja arrancada con dosis corregidas** a los pies de la cama del familiar.
- **Reparto del caso entre vecinos reales** al empezar (boticario, criada de la casa del señor, familiar y el vecino de la lana azul, con manga rota y arañazos). Se guarda en la partida.
- **Dos secuestradores forasteros escondidos en el molino:** atacan si te acercas sin sigilo, huyen malheridos y se marchan si tardas más de tres días.
- El vigilante de Antigravity se para solo si a Antigravity se le acaba el cupo.

