# Registro de cambios

Cambios del juego, del más nuevo al más antiguo. Añade una entrada al cerrar cada bloque, en lenguaje sencillo.
El detalle técnico está en `docs/HANDOFF.md` (sección 7) y el historial completo en `git log`. Lo anterior a B0.1 está en `AUDIT_LOG.md` y `SESSION_CONTEXT_LOG.md`.

## 2026-11-07 — Corrección de puestos de trabajo, sabotaje nocturno y alcantarillas bajo el pueblo tras agrandar el mapa
- **Vecinos trabajando y saliendo de expedición a los sitios reales:** los 4 ayudantes familiares (Kael, Lina, Mila y Nora) acuden ahora a su taller en vez de quedarse en su casa; Corin va a pescar a la nueva orilla del Lago del Oeste; Bram, Thoran, Elena, Garrick y el leñador acuden al nuevo Bosque Profundo del sur; y todos los puntos de la posada «El Jabalí Dorado», la Biblioteca, el Ayuntamiento, la Mansión y la Trattoria «Il Corvo» apuntan a su posición actual.
- **Saboteador nocturno a la 1:00 de la madrugada:** corregido el encargo nocturno de sabotaje para que el vecino contratado siempre tenga la ruta real al mostrador del taller objetivo.
- **Alcantarillas y sótano de peleas bajo el pueblo (en 2D y 3D):** las alcantarillas dejan de aparecer en mitad del bosque ni bloquear el paso con muros invisibles en 3D; ahora están bajo el centro del pueblo con sus 3 rejillas de entrada, sin colisión mientras caminas por la calle y visibles tanto en 2D como en 3D al bajar.

## 2026-11-07 — Bocetos de todos los edificios y espacios pendientes antes de construirlos (Paso 5 ⛔)
- **Documento de bocetos (`docs/BOCETOS_EDIFICIOS.md`) listo para revisión:** incluye la distribución de salas, muebles principales, quién trabaja o vive dentro, qué puede hacer el jugador y el estilo de fachada y puerta exterior para la **Comisaría y Cárcel**, el **Hospital y Morgue Forense**, la **Capilla del Alba**, la **Biblioteca Municipal** (con lectura útil de 4 materias reales al pulsar `[E]`), las **Alcantarillas ampliadas y el Club de la Lucha**, el **Rancho del Sur con su gran corral de ganado**, el **Tablón de Encargos legible de la Plaza** y el **resto de edificios del pueblo** (Ayuntamiento, Escuela, Salón «El Candil», Mansiones, Casas y Talleres/Tiendas).

## 2026-11-07 — Ambiente del valle: cielo con nubes y hora del día, suelo con textura y hierba 3D, árboles variados y niebla (Paso 4)
- **Cielo vivo con nubes, sol, luna y estrellas en primera persona:** el cielo plano se sustituye por una bóveda celeste con dos capas de nubes que se mueven despacio, sol diurno, atardeceres dorados y noche estrellada según la hora del reloj.
- **Suelo con textura de hierba y tierra más matas de hierba y flores 3D:** el césped ya no se ve como una lámina lisa; combina textura de briznas, trébol y calvas de tierra a varias escalas junto con cientos de matas de hierba, helechos y flores silvestres 3D repartidas por praderas, cunetas y linderos.
- **Robles, abedules y pinos repartidos por el valle:** los árboles del pueblo, el campamento y el bosque mezclan ahora robles frondosos, abedules de corteza blanca y pinos altos de distintos tamaños.
- **Niebla atmosférica según la hora y el clima:** bruma suave de madrugada y al atardecer, niebla espesa en días lluviosos o de niebla y horizonte difuminado en el exterior (aclarándose al entrar dentro de cualquier edificio).

## 2026-11-07 — La nueva taberna «El Jabalí Dorado» de 2 pisos: comedor lleno, póker, camarero, mesa de billar 3D y club de lucha en el sótano (Paso 3)
- **Primer edificio de 2 pisos reales con escalera física:** la posada es ahora mucho más grande; en la planta baja tiene el gran salón con chimenea y 6 mesas de comedor, la barra con cocina, la sala de casino/billar y la bodega trasera, y subiendo por la escalera de madera llegas al primer piso con galería asomada al salón y 5 cuartos de huéspedes para las 6 camas.
- **Marta tras la barra, un camarero sirviendo mesas y clientes sentados:** la tabernera atiende detrás del mostrador de caoba, un nuevo camarero va tomando nota en las mesas ocupadas y trayendo jarras y platos desde el pasa-platos de la barra, y los vecinos se sientan de verdad a comer, beber y jugar al póker comentando las manos en vivo.
- **Mesa de billar auténtica en 3D:** sustituida la antigua mesa con patas de cama por una mesa de billar de caoba con 4 patas torneadas con latón, paño verde esmeralda con línea de saque, 6 troneras con cantoneras doradas, bolas de colores en triángulo más bola blanca y dos tacos apoyados.
- **El club de peleas clandestinas en el sótano de la taberna:** la trampilla está ahora dentro de la bodega trasera de la taberna, abre todas las noches de `21:00` a `03:00` (también desde la primera noche) y puedes enterarte de cómo bajar por los rumores del salón o preguntando a Marta o al camarero por los ruidos bajo el suelo.

## 2026-11-07 — Agrandar y separar el entorno: campamento y lago alejados, bosque ~3,5× mayor con borde orgánico, árboles 3D corregidos y trattoria en la Calle Mayor (Paso 2)
- **Campamento inicial y Lago del Oeste fuera del pueblo:** tu campamento (tienda, hoguera, huerto de 3×3 parcelas, gallinero y el perro Toby) queda ahora apartado junto al Lago del Oeste, con un único muelle de pesca y un camino largo hasta la entrada del pueblo.
- **Lavadero en el pueblo, Parque del Roble ampliado y camino del este despejado:** el lavadero pasa de la orilla del lago al pueblo (al norte del parque); el Parque del Roble tiene casi el doble de tamaño, sin murete bajo y con los bancos despejados de árboles; y se ha quitado el «Huerto vecinal» que cortaba el camino del este.
- **Trattoria «Il Corvo» en la Calle Mayor:** el restaurante italiano deja de estar pegado al cementerio y abre sus puertas y su terraza en pleno camino principal de entrada a la Plaza Central.
- **Llanura Salvaje y Ciénaga de las Ranas separadas y más amplias:** al noroeste se extiende la Llanura Salvaje con las ruinas de bandidos y al suroeste, separada al otro lado del camino, se abre una Ciénaga de las Ranas mucho mayor.
- **Bosque profundo ~3,5 veces más grande, árboles 3D arreglados y animales que deambulan:** corregidos los modelos 3D de árboles (que se veían huecos por dentro y con ramas rosadas) y evitado que se pisen con muros o entre sí; el bosque del sur tiene ahora un borde irregular y natural con claros, matorrales y troncos caídos, y los conejos, venados, jabalíes y zorros se reparten y caminan por todo el bosque en vez de quedarse pegados a su madriguera.

## 2026-11-07 — Arreglos rápidos: examen real de vecinos muertos, mejoras de la mesa forense y fallos visibles (Paso 1: 1a, 1b, 1c)
- **Examen real para cualquier vecino muerto (1a):** cuando muere un vecino que no forma parte de un caso guionizado (por ejemplo, asesinado con sigilo por la espalda o en pelea), el examen del cuerpo, la autopsia, la escena del crimen y el tablero describen exactamente sus heridas reales, el arma empleada, sus bolsillos y el lugar donde cayó; las zonas sanas indican «nada fuera de lo normal» y nunca aparecen pistas del Caso I («La mujer del bosque»).
- **Fondo limpio en boceto, barra de deterioro e hilos del tablero (1b):** el fondo del examen del cuerpo y de la escena del crimen muestra ahora un esquema limpio de pocas líneas del lugar real (bosque/arroyo, morgue, lago, calle o rancho) en vez de bordes ruidosos; se ha añadido la barra de 4 fases de deterioro del cadáver (`Reciente`, `Enfriándose`, `Rígido`, `Deteriorado`); y en el tablero de corcho los hilos rojos van de chincheta a chincheta pasando por detrás de las fichas para no tapar nunca lo escrito.
- **Fallos visibles corregidos (1c):** ropa, peinados, barba y tonos de piel variados para los vecinos; corregido el hombro que atravesaba la ropa en los guardias y el tamaño del libro de Anselmo y la maestra; quitados los conos de visión de los sapos; el agua del lago ya no se puede pisar salvo entrando por el único muelle de madera; el cuarto del dueño de «Il Corvo» es ahora un despacho con escritorio en lugar de tener camas; los letreros del Rancho del Sur y del Parque del Roble ya no se pisan; y las lápidas del cementerio tienen tamaño normal.

## 2026-11-07 — Estructura para los 10 casos del detective y fachada de estuco claro en «Il Corvo» (paso 5)
- **Preparado para los 10 casos:** separada toda la información de cada misterio (zonas del cuerpo, pasos de autopsia, pistas del suelo, testigos, sospechosos y papeles asignados a vecinos reales) en un archivo de datos independiente con hueco para los 10 casos y el esqueleto del Caso I («La mujer del bosque»), dejando marcados como pendientes los detalles de trama aún no decididos.
- **Fachada de la trattoria «Il Corvo» en 3D corregida:** cambiado el acabado exterior del restaurante en 3D para que luzca como estuco y ladrillo claro cálido en lugar de tablas oscuras (`docs/FALLOS_VISIBLES.md`).

## 2026-11-07 — Cuaderno y tablero de corcho con hilos rojos (herramientas del detective, paso 4)
- **Abrir el tablero en cualquier momento con la tecla `[N]`:** además de la pestaña «4 · Tablero del caso» dentro de la mesa de investigación, puedes pulsar `[N]` en cualquier momento para abrir tu tablero de corcho con lo que llevas anotado.
- **Fichas que se arrastran e hilos rojos:** en el corcho aparecen las fichas de los sospechosos del caso y todas las pistas que hayas decidido anotar desde el cuerpo, la autopsia o la escena del crimen. Puedes colocarlas donde quieras arrastrándolas con el ratón, unir dos fichas con hilo rojo pulsando una y luego otra, y quitar cualquier hilo haciendo clic encima.
- **Se guarda con tu partida:** todas tus notas del cuaderno, la posición de cada ficha en el corcho y los hilos rojos que hayas tendido se guardan y recuperan al cargar la partida.

## 2026-11-07 — Escena del crimen bajo el farol (herramientas del detective, paso 3)
- **Buscar a oscuras con tu farol:** en la pestaña «Escena del crimen» el lugar del hallazgo queda a oscuras y solo ves lo que alumbra el círculo de tu farol al mover el ratón, junto a la silueta de donde yacía el cuerpo.
- **Pistas reales en el suelo:** bajo la luz del farol aparecen las señales reales de lo ocurrido (surcos si arrastraron el cadáver desde otro sitio, charcos de sangre o piedra fregada con lejía, huellas de huida, barro removido u objetos plantados para incriminar a otro vecino).
- **Testigos cercanos (preguntar o presionar):** en la libreta derecha puedes interrogar a quienes andaban cerca; si los presionas para que suelten más, pueden confiar en ti y contarte lo que callaban o cerrarse en banda y enfadarse según su carácter y cómo te lleves con ellos.

## 2026-11-07 — Autopsia en la morgue (herramientas del detective, paso 2)
- **Mesa de autopsias con el Dr. Valen:** cuando el cuerpo ya está en la morgue y el médico forense está disponible (o entrando desde la camilla del hospital), puedes hacer las 4 pruebas internas paso a paso: sangre, cuello, estómago y piel y rigidez.
- **Muestras que se pueden estropear o quedar dudosas:** la sangre solo da para 2 tubos de muestra (equivocarse de reactivo gasta un tubo y al segundo fallo se pierde; sacarla del brazo en vez del corazón deja un resultado dudoso), cortar el cuello deprisa rompe el hueso que buscabas y tirar el contenido del estómago impide que el alquimista lo analice.
- **Consejo del forense y causa real:** en los pasos delicados puedes pedir consejo al Dr. Valen a cambio de 5 minutos, la «Causa real» de la muerte se va completando a medida que aciertas las pruebas, y cualquier conclusión se puede clavar como ficha en el cuaderno del caso.

## 2026-11-07 — Examen del cuerpo en la escena (herramientas del detective, paso 1)
- **Examinar el cadáver en el sitio con `[E]`:** al acercarte a un cuerpo y pulsar `[E]` se abre la mesa de examen (pausando el mundo mientras miras, pero sumando al reloj los minutos que cuesta cada comprobación).
- **Siete zonas y silueta de hombre o mujer:** puedes mirar de cerca, palpar, oler, usar la lupa de latón (si la llevas encima) o vaciar los bolsillos sobre las 7 partes del cuerpo (`cabeza`, `cuello`, `torso`, `brazos`, `manos`, `piernas` y `bolsillos`). La silueta plana cambia entre mujer (con pelo largo tras la cabeza) y hombre según quién sea la víctima, y va dibujando encima las marcas que descubres.
- **Fondo cenital en boceto del lugar real:** el fondo bajo el cuerpo toma una vista cenital 3D del punto exacto donde yace (ocultando vecinos y jugador) pasada por un filtro de dibujo a tinta oscura, y lo que apuntas baja a la tira inferior de tu cuaderno del caso.

## 2026-11-07 — Prueba de primera persona (prototipo con F6 / F8)
- **Cambio al vuelo con F6 o F8:** pulsando `[F6]` o `[F8]` pasas en cualquier momento de la vista desde arriba a caminar por el pueblo en primera persona a la altura de los ojos, y vuelves a la vista normal cuando quieras sin que nada del juego se rompa.
- **Mirar alrededor y andar hacia donde miras:** el ratón (o las flechas) gira la cabeza a los lados y arriba/abajo, `W/A/S/D` camina respecto a hacia dónde miras, `[E]` usa lo que tienes delante en el centro de la pantalla y el clic ataca o dispara de frente.
- **Techos cerrados desde dentro:** al entrar en cualquier edificio en primera persona, los tejados y las cuatro paredes se mantienen cerrados con su techo de madera encima, y el cuerpo 3D de tu propio personaje se oculta para no estorbar la vista.

## 2026-11-07 — Los 21 vecinos fundadores con historia (rasgos, relaciones, secretos y variación por partida)
- **Seis rasgos coherentes por fundador:** cada uno de los 21 vecinos originales (más Valeria en la caravana real) tiene ahora 6 rasgos de carácter bien definidos y sin contradicciones, con pequeñas variaciones de una partida a otra que mantienen su esencia.
- **Amistades, rencores y de 2 a 3 secretos propios:** todos los fundadores empiezan con sus propias simpatías y enemistades en el pueblo (algunas fijas y otras variables según la partida) y guardan entre 2 y 3 secretos personales que pueden salir a la luz hablando con ellos o investigando rumores.
- **Las 21 fichas de vecinos al día:** completadas todas las notas de `GameVault/04_Censo_y_Misiones/Vecinos/` con sus rasgos, relaciones y secretos.

## 2026-11-07 — Lo que se ve en la calle (desprecio, merodeo nocturno, pregones y fila de la escuela)
- **Miradas de desprecio y feudos de sangre en la calle:** cuando dos vecinos que se odian o cuyas familias están enfrentadas se cruzan de cerca, sueltan un bocadillo corto de 1,5 segundos sin parar el juego y se apartan el uno del otro.
- **Merodeo antes de una venganza:** quien planea una venganza o un crimen sale las noches anteriores a rondar la casa de su víctima a escondidas, dando pistas visuales antes de actuar.
- **Obras maestras, decretos y fila del colegio:** los maestros artesanos pregonan sus obras nuevas, los vecinos comentan en voz alta los decretos y edificios recién inaugurados, y los niños hacen fila en la puerta de la escuela a las nueve antes de entrar a clase.

## 2026-11-07 — Coherencia del ambiente (niebla, humo en talleres saboteados y paseos nocturnos)
- **Niebla de madrugada y charcos de luz:** de madrugada y en días de niebla los vecinos y guardias ven bastante menos lejos en la penumbra, salvo si pasas cerca de una farola encendida o de alguien que lleva un farol (si vas en sigilo apagas tu farol para no delatarte).
- **Humo y chispas en los talleres saboteados, y lluvia contra el fuego:** un taller saboteado echa humo, chispas y llamas en 2D y 3D hasta que alguien lo repara; si se pone a llover, la lluvia apaga el fuego exterior y alivia los daños.
- **Noctámbulos, insomnes y sonámbulos por las calles:** quitada la marca de «dormida» de las tendencias ya activas en el catálogo de rasgos, y ahora quienes son noctámbulos o insomnes salen a pasear de noche por las calles, mientras que los sonámbulos caminan dormidos y a oscuras de madrugada.

## 2026-11-07 — Del campamento del lago a tu casa del pueblo
- **Mudanza de Toby y su comedero:** cuando ya tienes casa construida en un solar del pueblo, puedes llevarte a Toby y su cama con comedero junto a tu puerta (hablando con el carpintero, desde la mesa de tu casa o en la mesa de obras del campamento).
- **Mudanza de tu gallinero y tus animales de corral:** también puedes trasladar tu gallinero y tus ovejas y gallinas al patio de tu solar en el pueblo (o se trasladan al montar allí el huerto y gallinero con el carpintero), mientras el campamento del oeste junto al lago sigue sirviendo como puesto de pesca, caza y refugio.

## 2026-11-07 — Calabozo de verdad (vecinos entre rejas, fianza y fuga)
- **Los vecinos detenidos van de verdad al calabozo:** cuando un guardia pilla a alguien en un trabajo nocturno (sabotaje, robo o profanación), separa una pelea grave, ejecuta una sentencia o detiene al jefe de «La Familia» tras tu denuncia, el detenido camina hasta la celda de la comisaría y queda encerrado tras los barrotes (sin acudir a su puesto ni a reuniones) hasta cumplir su condena de 1 o 2 días.
- **Visitar al preso, pagar su fianza o abrirle la reja:** puedes hablar con él a través de los barrotes, pagar su fianza al comisario o a un guardia (el oro entra en las arcas municipales y el preso sale agradecido) o forzar la cerradura con ganzúas o llave para sacarlo a escondidas, arriesgándote a que la guardia te busque por complicidad si te ven.

## 2026-11-07 — Ruido y testigos en combate (cierra C7)
- **Los golpes fuertes, gritos de dolor y disparos se oyen alrededor:** el ruido viaja por la misma planta (amortiguado por los muros) y hace reaccionar a quienes están despiertos cerca.
- **Guardias que acuden y vecinos que huyen o se asoman:** los guardias y el comisario van a mirar qué pasa e intervienen si pillan la pelea; los vecinos pacíficos se alejan asustados o se asoman a una distancia prudente si son curiosos o valientes.
- **Testigos solo si te ven de verdad:** oír el ruido tras una pared o desde otro piso no basta para delatarte; un vecino solo cuenta como testigo si está en la misma planta y tiene línea de visión directa.

## 2026-11-06 — Don Vittorio Corvo y cómo intervenir ante «La Familia»
- **Don Vittorio Corvo, jefe desde el primer día:** la partida arranca ya con un padrino al frente de «La Familia», instalado en el cuarto del dueño y la mesa del reservado de «Il Corvo», con ahorros propios y el carácter exacto para dirigir el negocio (sediento de poder, manipulador, líder, codicioso, astuto y rencoroso). Si algún día cae, otro vecino ambicioso puede seguir su camino.
- **Descubrir el pastel sin menús mágicos:** ninguna opción nueva aparece gratis. Para enterarte de quién manda y a por qué comercio van, tienes que escuchar los rumores del pueblo o acercarte con sigilo al reservado de «Il Corvo» en mitad de una reunión nocturna.
- **Tres formas de meter mano:** una vez sabes lo que se cuece, puedes avisar al comerciante amenazado para que esté prevenido, delatar a «La Familia» ante el Comisario con pruebas (cobrando recompensa de las arcas y desmontando sus sobornos y cobros activos) o pedirle trabajo al jefe para ir en persona a cobrar la comisión y repartir el botín a medias.

## 2026-11-06 — Los negocios discretos de «La Familia»
- **Comisión de «tranquilidad» a los comercios que van bien:** tras sus reuniones nocturnas, un miembro va en persona durante el día a pedir una aportación a los comerciantes con dinero (si hay un guardia cerca, disimula y se marcha). Si el comerciante acepta, el oro sale de su bolsillo y se reparte entre el cobrador y el jefe; si se niega, no paga nada, se enfada y puede correr el rumor.
- **Préstamos del reservado:** el jefe presta de su propio bolsillo a vecinos sin blanca; si al vencer el plazo no pueden devolverlo con intereses, quedan atrapados debiéndole un favor personal.
- **Guardias untados:** si hay un guardia poco honrado y sin testigos cerca, «La Familia» puede comprarle el silencio unos días con dinero del jefe; mientras dura el soborno, ese guardia hace la vista gorda de noche y no les estropea las cenas en el reservado.

## 2026-11-06 — «La Familia» se reúne en el reservado
- **Nace sola cuando se dan las condiciones:** un vecino ambicioso, sin escrúpulos y con don de gentes que haya ahorrado o arrastre deudas, envidias o agravios decide fundar «La Familia» por su cuenta (no existe al empezar la partida).
- **Recluta de 2 a 4 vecinos de uno en uno** entre quienes le deben favores, le tienen afecto o miedo, o están desesperados sin blanca. Quien es honrado puede negarse: se queda con mal recuerdo y puede contarlo por el pueblo.
- **Reuniones nocturnas en el reservado de «Il Corvo»:** se citan de noche alrededor de la mesa redonda cuando el jefe lo decide; si ven un guardia o un extraño cerca, abortan y lo dejan para otra noche. Si le preguntas al cocinero, deja caer una indirecta.
- **Enciclopedia en una sola página:** añadida herramienta para juntar las notas del proyecto en un único archivo `.html` que se abre en cualquier navegador o móvil sin internet.

## 2026-11-06 — La trattoria cobra vida
- **Los vecinos con dinero salen a comer o a cenar** a «Il Corvo» (de 13 a 22 h; más por la noche): se sientan en el
  comedor o en la terraza, piden tallarines o estofado y se lo pagan al cocinero. Si no queda nada, se van a casa.
- **El cocinero abre de 12 a 23 h, también el fin de semana**, y antes de cada estofado baja a la cámara fría a
  descolgar una pieza de carne.
- En una prueba de 7 días sin jugador, el cocinero llegó al pueblo el día 4 y sirvió 6 comidas en 4 días.

## 2026-11-06 — Trattoria «Il Corvo»
- **Nuevo restaurante italiano al este del pueblo**, grande y con varias salas: comedor con mesas de mantel a cuadros,
  velas, barra y piano; cocina con fogón y campana; cámara fría con hielo y carne colgada; bodega de vinos; el cuarto
  del dueño; y un **reservado** al fondo con mesa redonda, chimenea y luz roja, donde «no se pregunta para quién es».
- **Terraza** con mesas, sombrillas, macetas y guirnalda de bombillas que se enciende al caer la tarde.
- Un vecino recién llegado se hace cargo como cocinero: vende tallarines y carne estofada al vino, y compra trigo y carne.
- Es la primera pieza del crimen dentro del pueblo: aquí se reunirá más adelante «la Familia».

## 2026-11-06 — Rodar ya no ataca
- **El Espacio solo sirve para rodar.** Antes, al rodar también soltabas un golpe, y si estabas detrás de alguien
  ¡podías rematarlo por sigilo sin querer! Se ataca con el clic izquierdo (o con Intro).

## 2026-11-06 — El combate pesa: las consecuencias
- **Dónde duele depende de desde dónde llega:** un jabalí o un perro muerden sobre todo las piernas; por la espalda se
  hiere la espalda y la nuca (los brazos no llegan a cubrir, y la herida lo dice); de lado, el brazo y la pierna de ese lado.
- **Las armas se mellan:** con el uso, tu espada, martillo, hacha, pico u hoz pierden filo y pegan menos (te avisa).
  Talar con la espada la mella mucho antes. El herrero las deja como nuevas por unas monedas.
- **Desarmar:** un golpe fuerte (el 3.º de la espada o uno cargado) que acaba en el brazo de un guardia le hace soltar
  la porra y la pistola un rato: pelea a puñetazos. A un bandido le quita el cuchillo.

## 2026-11-06 — El combate pesa: cubrirse y empujar
- **Cubrirte:** mantén Q después de parar y levantas la guardia: los golpes pasan muy flojos pero gastan energía;
  si te quedas sin ella, la guardia se rompe. Con la guardia alta andas despacio y no puedes golpear. No para flechas ni balas.
- **Empujar (X):** un empujón con el hombro que aparta y desequilibra al que tienes delante. Casi no hace daño, pero
  empujar a un vecino sigue siendo una agresión.
- La pantalla de controles y el «Léeme» ya lo cuentan.

## 2026-11-06 — El combate pesa: cadenas y golpes cargados
- **Espada:** si vuelves a pulsar justo al terminar un golpe, encadenas otro; el tercero es más lento y pega fuerte.
- **Martillo y hacha:** mantén el clic para cargar (el arma se echa atrás y brilla); al soltar, golpe que empuja y
  tumba más. Cuesta más energía y mientras cargas andas despacio. Un toque corto sigue siendo un golpe normal.

## 2026-11-06 — El combate pesa: los rivales juegan con las mismas reglas
- **Oyes venir sus golpes:** guardias, vecinos, bandidos y jabalíes hacen el zumbido del golpe al soltarlo.
- **Si fallan, puedes castigarles:** tras dar se quedan quietos un instante, y tras fallar, más rato.
- **Cada rival empuja distinto:** el jabalí te tira hacia atrás, la porra bastante, los puños poco.
- **El tamaño cuenta:** un jabalí apenas se mueve con tus golpes; un conejo o un perro salen despedidos.

## 2026-11-06 — El combate pesa: primera parte del combate nuevo
- **Cada arma se siente distinta:** el martillo se echa atrás, tarda y golpea fuerte; la hoz y los puños son rápidos;
  la espada, en medio. Al soltar el golpe das un paso adelante y, mientras golpeas, andas más despacio.
- **Se nota el impacto:** el que recibe sale empujado y se tambalea un instante (se le corta el ataque), salta una
  chispa y el golpe suena. Primeros sonidos del juego: el tajo al aire, el golpe, el quejido al recibir, esquivar y parar.
- **Cuando te dan a ti:** quejido, la cámara tiembla y te empuja un poco hacia atrás.

## 2026-11-06 — Los asaltos al pueblo, en pausa
- **Ya no llegan bandidos ni jabalíes** al pueblo: no convencían (poco realistas). Está todo guardado por si vuelven.
  El crimen irá por robos y mafias dentro del pueblo.

## 2026-11-06 — El juego ya se puede pasar a amigos con Windows
- **La ventana ya se llama «La Placa de Petri»** (antes salía el nombre interno del proyecto).
- **Un solo archivo:** «LaPlacaDePetri.exe», sin instalar nada, dentro de un zip con un «Léeme» que explica qué es el
  juego, los controles, qué esperar y qué hacer si algo falla.

## 2026-11-06 — Los vecinos lejanos viven siempre del todo
- **Sin «a ratos»:** los vecinos que están lejos de ti ya no piensan ni se mueven solo de vez en cuando para ahorrar;
  viven igual de completos en todo el valle. Cuesta muy poco (medido).
- **Rendimiento aparcado:** medido qué frena el juego en el portátil (sobre todo la tarjeta gráfica); en el PC de
  escritorio va bien, así que se deja para más adelante.

## 2026-11-06 — Guardar y cargar sin sustos
- **Lo que estaba a medias sigue:** un sabotaje nocturno en marcha, una cena o fiesta convocada y los invitados ya
  sentados siguen igual al cargar la partida.
- **Lo que no puede seguir se anula sin perder nada:** una pelea del club a medias se anula y te devuelven la entrada o
  la apuesta; los vecinos del sótano vuelven a su sitio y tú sigues abajo con la escalerilla funcionando.
- **Arreglado:** las cenas en casa se rompían al cargar, porque la posición de la mesa se guardaba mal.

## 2026-11-06 — Dos prótesis: sencilla (50 %) y buena (75 %)
- **Dos calidades en el hospital:** la sencilla de madera y correas (25 de oro) deja el brazo o la pierna al 50 %; la
  articulada de hierro y cuero (50 de oro) al 75 %. Con la sencilla puesta, el médico te ofrece mejorarla por 25.
- **Los vecinos también eligen:** compran la buena si les llega el dinero; si no, la sencilla, y la mejoran al ahorrar.
- **El miembro perdido no vuelve a crecer:** curarse, comer o dormir ya no devuelve la pierna cortada ni sube la
  prótesis por encima de su tope, tampoco al guardar y cargar.

## 2026-11-06 — Las Obras Maestras se compran en el taller del maestro
- **En el mostrador, no en la calle:** junto al puesto de cada maestro artesano aparece «Comprar Obra Maestra de estilo
  …». Tiene que estar él en su taller y despierto; si no, «El maestro no está; vuelve cuando abra». Como es un gasto,
  se pulsa E dos veces. Ya no sale en la charla.
## 2026-11-06 — Amputación para el jugador: el médico te avisa y tú decides
- **Aviso de gangrena:** si una herida tuya en un brazo o una pierna llega a infectarse gravemente, el médico ya no te amputa automáticamente ni te ignora: recibes un aviso para acudir al hospital antes de que sea tarde (si la herida se cura y baja la infección, el aviso desaparece).
- **Tú eliges en el hospital:** al hablar con el médico puedes pedirle que te ampute el miembro gangrenado gratis para salvarte la vida (quedando reflejado en tu cuerpo 3D, en la crónica y en tu velocidad de andar o de golpear hasta que te pongas una prótesis) o negarte y arriesgarte a que la infección siga avanzando.

## 2026-11-06 — Pantalla de ayuda de controles al empezar partida nueva
- **Resumen de controles al empezar:** al iniciar una partida nueva (no al cargar), se muestra en el centro de la pantalla un recuadro con los controles divididos en dos columnas («Lo básico» y «Más») mientras el reloj del mundo permanece en pausa hasta que pulsas Esc, Intro o haces clic para empezar.
- **Volver a consultarla:** como la tecla **H** ya abre el panel clínico, se ha añadido un botón «Controles» en la barra inferior de la mochila (junto a Guardar y Cargar) para consultarla en cualquier momento.

## 2026-11-06 — Sabotajes, robos y profanaciones de noche que hace alguien de verdad
- **Ya no pasan solos:** si contratas un saboteador o un ratero, o si una familia enfrentada sabotea o profana una
  tumba, a la 1:00 de la noche un vecino de verdad camina hasta el taller, la casa o la lápida y se queda un rato
  agachado. Solo si aguanta allí 20 minutos sin que lo pillen ocurre lo de siempre.
- **Se le puede pillar:** si un guardia lo ve, o si llegas tú y pulsas E («¡Te he visto! ¿Qué haces aquí?»), no hay
  sabotaje ni robo y sale en la crónica.
- **Puede delatarte:** si el trabajo lo pagaste tú y lo pillan, puede confesar quién le pagó (más fácil si no te aprecia);
  entonces sube tu búsqueda. El dinero no se devuelve.

## 2026-11-06 — Club de pelea en un sótano de verdad bajo la taberna
- **La trampilla:** en el patio trasero de la taberna hay una trampilla. Las noches pares, de 23:00 a 3:00, se abre y
  baja a un sótano de tierra con faroles y un corro de cuerda. El perista y unos cuantos vecinos pendencieros bajan
  andando a mirar y animan desde fuera del corro.
- **Pelear tú:** pagas 10 de entrada (pulsando E dos veces) y peleas a puño limpio con el más bravo; puedes rodar y
  parar como en cualquier pelea. Nadie muere: al quedarse al 20 % de vida, el que va perdiendo se rinde. Si sales del
  corro, pierdes. Si ganas, el perista te paga la bolsa de la noche (hasta 35).
- **Apostar:** si no peleas tú, a medianoche pelean dos vecinos; antes puedes apostar 15 por uno junto al corro y, si
  aciertas, cobras 30. Los que pelean acaban magullados de verdad.
- **La guardia:** si un guardia ve a alguien bajar o subir por la trampilla, la noche siguiente el club no abre; si eras
  tú, sube tu búsqueda. Apostar y pelear ya no se hacen en la charla con el perista.
## 2026-11-06 — Cenas con vecinos, fiestas en tu casa y cenas de paz entre familias hechas físicas
- **Mesa de comedor en tu casa:** en tu casa construida aparece una mesa de comedor (en 2D y 3D) con seis sitios alrededor.
  Pulsando **E** en la mesa puedes poner comida de tu mochila (hacen falta dos raciones por invitado) o convocar una fiesta
  para esa noche a las nueve.
- **Contratar cáterin en la posada:** si prefieres no cocinar, puedes hablar con la posadera (con doble **E**) y pagarle
  cuatro de oro por invitado. Una hora antes de la reunión la posadera va caminando hasta tu casa y deja las raciones
  servidas en tu mesa; si por estar herida, dormida o presa no llega a tiempo, la cena no empieza y recuperas tu oro.
- **Cenas y fiestas con invitados reales:** cuando invitas a un vecino a cenar (a las ocho) o invitas uno a uno hasta seis
  vecinos a tu fiesta (a las nueve), a la hora señalada caminan hasta tu mesa y se sientan durante dos horas charlando cada
  poco. Si al llegar ven la mesa sin comida o si tú te marchas antes de que termine la velada, se van enfadados; si te quedas
  con ellos hasta el final, sube vuestra amistad y los asistentes hacen buenas migas entre sí.
- **Cenas de paz en la posada:** para reconciliar a dos familias enfrentadas ya no basta con pagar en el diálogo; organizas
  la cena en la posada (con doble **E** si pagas) para el día siguiente a las ocho de la tarde. Acuden el cabeza de cada
  familia y hasta dos adultos más por bando; si falta toda una familia no hay acuerdo, y según el mal genio de los presentes
  y lo viejo que sea el rencor, la velada puede sellar la paz o acabar a gritos.

## 2026-11-06 — Rentas, «protección» y tributo se recogen en persona; desfalco en el cofre del ayuntamiento
- **El sábado ya no te llega oro solo:** la renta de tus locales, la «protección» y el tributo del hampa se apartan y
  tienes que ir a recogerlos. Rentas y tributo esperan hasta 3 semanas; si faltas dos sábados seguidos a cobrar la
  «protección», ese local deja de pagarte.
- **Cobrar en el local:** junto al puesto del artesano aparece «Cobrar la renta del local» o «Cobrar la "protección"».
  El dueño tiene que estar allí. Cobrar «protección» delante de un guardia sube tu búsqueda.
- **Tributo:** como Jefe del Hampa lo recoges hablando con el perista, solo de noche.
- **Ayuntamiento:** siendo alcalde, desvías oro en el propio cofre de las arcas (si alguien te ve, escándalo y chisme) y
  maquillas las cuentas en un libro sobre la mesa (con doble E si pagas). Ya no se hace en la charla.

## 2026-11-06 — El perista se deja ver de noche en el callejón de la taberna
- **Trasnocha en el callejón:** de 22:00 a 3:00 el perista no duerme: espera en el callejón de detrás de la taberna, con
  capa oscura y capucha. Si está herido, preso o la guardia lo vigila, esa noche no sale.
- **Figura encapuchada:** mientras no sepas quién es, su letrero de [E] dice «Hablar con la figura encapuchada».
- **Rumores sutiles en la taberna:** de 19:00 a 1:00, algún vecino de dudosa reputación puede dejar caer un comentario de
  pasada al final del saludo (muy raro: como mucho uno al día en todo el pueblo). Los vecinos honrados no saben nada.

## 2026-11-06 — Caravanas comerciales con mula en la plaza y campamento nocturno de contrabando en el claro noreste
- **Caravanas de las rutas comerciales:** cuando abres una ruta comercial, su caravana (el caravanero y su mula de carga)
  entra andando por el camino del este una vez por semana (a veces se retrasa un día por el barro), acampa en la plaza
  desde media mañana hasta media tarde y vuelve a salir por el camino. El intercambio de mercancías entre talleres ocurre
  cuando la caravana llega a la plaza, no a medianoche.
- **Cargar tu remesa en la mula:** para enviar tu propia remesa ya no hablas con cualquier artesano, sino que te acercas a
  la mula de la caravana en la plaza y pulsas **E** (si llevas tu carreta cerca, cobras los 4 de oro extra). Si alguien
  mata al caravanero, esa ruta queda suspendida toda una semana.
- **Campamento nocturno de contrabando:** las noches de caravana de contrabando (de diez de la noche a cuatro de la
  madrugada), el contrabandista acampa con su carro y un farol tenue en el claro al norte de la mansión. Para comprar lotes
  (con doble **E**) o vender polvo de ocaso tienes que ir hasta su carro en persona; si te ve un guardia despierto de cerca,
  te pilla in fraganti y la caravana huye, y si la delatas a la guardia, dos guardias van andando hasta el claro para
  desmantelar el campamento.

## 2026-11-06 — Carreta de carga física en el rancho: tirar a mano o engancharla al caballo, caja de 40 objetos y riesgo nocturno
- **La carreta existe en el mapa:** al comprar la carreta de carga al ganadero, aparece aparcada junto al corral del Rancho
  del Sur (con su modelo 3D y dibujo 2D en vista plana). Ya no es un bono invisible: para cobrar los 4 de oro extra al
  enviar una remesa comercial tienes que llevar la carreta contigo (a menos de unos pasos).
- **Llevarla a mano o enganchada a tu caballo:** junto a la carreta puedes pulsar **E** para agarrarla y tirar de ella a pie
  (caminas más despacio y no puedes correr, ir en sigilo ni rodar) o, si vas subido en tu caballo, engancharla detrás (frena
  un poco el trote). Te sigue por el camino por donde pasas sin atravesar esquinas y se queda esperando fuera si entras en un
  edificio, te acuestas o te lleva la guardia; si bajas del caballo, se queda enganchada a él donde esté.
- **Caja de carga de 40 cosas y riesgo de noche:** con la carreta parada puedes abrir su caja de carga para pasar hasta 40
  objetos entre tu mochila y la carreta (el oro no cabe). Si dejas la carreta con carga aparcada de noche lejos de tu casa o
  del corral del rancho, algún vecino necesitado puede llevarse parte de la mercancía (y si alguien lo ve, sale en la crónica).
- **Mostrador de tu tienda:** reponer mercancía en el mostrador de tu negocio ahora pasa hasta 6 artículos de golpe por cada
  pulsación.

## 2026-11-06 — Tu tienda («Bazar del Forastero») funciona de verdad en tu solar con mostrador, dependiente y clientes a pie
- **Mostrador y caja en tu solar:** cuando abres tu propio negocio, aparece un mostrador con caja de caudales en 2D y 3D
  dentro de tu solar. Te acercas y pulsas **E** allí mismo para **reponer mercancía** desde tu mochila y **recoger el oro
  de la caja** (ya no se hace charlando con cualquier vecino por la calle).
- **Dependiente detrás del mostrador:** en horario comercial, el vecino que contrates como dependiente va caminando hasta
  detrás de tu mostrador y se queda atendiendo la tienda; si no está en su puesto, no se vende nada. Su sueldo diario sigue
  saliendo de la caja.
- **Clientes que entran a comprar:** durante el día, los vecinos con dinero se acercan andando a tu mostrador y compran un
  artículo pagándolo de su bolsillo a la caja (en lugar de venderse solo a medianoche). Pregonar tu negocio o contratar a
  un vecino sigue haciéndose hablando con la gente, y la publicidad atrae más compradores durante 3 días.

## 2026-11-06 — Pasos en 3D acompasados al suelo y armas bien sujetas en la mano
- **Pasos sin patinar:** el ritmo al que mueven las piernas tu personaje, los vecinos y los asaltantes ahora coincide con
  lo que avanzan de verdad sobre el suelo, tanto al caminar despacio como al trotar o correr.
- **Armas y herramientas al derecho:** la espada, el hacha, el pico, el martillo, la hoz, el arco, el arcabuz, la caña o
  lanza, la regadera, el escudo y el farol ya no aparecen dados la vuelta 180° hacia atrás en la mano, sino bien sujetos
  apuntando hacia delante (tanto en tu personaje como en los vecinos y guardias).

## 2026-11-06 — Combate cuerpo a cuerpo más vivo: rodar con Espacio, parar con Q y golpes enemigos que avisan
- **Rodar con Espacio:** pulsas **Espacio** para rodar en la dirección en la que te mueves (o hacia donde miras si estás
  quieto). Durante el inicio de la voltereta no recibes daño, cuesta aguante, choca contra las paredes, rompe el sigilo
  y no se puede usar montado a caballo.
- **Parar con Q:** pulsas **Q** un instante antes de que te alcance un golpe cuerpo a cuerpo para **pararlo sin recibir
  daño** («🛡️ ¡PARADA!») y dejar al atacante desequilibrado casi un segundo sin poder pegar. Si fallas el momento, hay un
  breve enfriamiento antes de volver a intentarlo; las flechas y disparos no se pueden parar con **Q**, y si estás en
  sigilo detrás de alguien, **Q** sigue sirviendo para aturdirlo sin ruido.
- **Golpes enemigos con aviso:** los vecinos hostiles, guardias, asaltantes, perros enfadados y jabalíes **avisan un
  instante antes de soltar el golpe** (con señal visual y el arranque de la animación de ataque), dándote margen para
  apartarte, rodar con **Espacio** o parar con **Q**.

## 2026-11-05 — Tu campamento inicial está en las afueras del oeste, junto al lago y el camino de llegada
- Ya no empiezas acampado en mitad del pueblo ni con una granja ya montada: empiezas en un claro apartado al oeste, frente
  al lago de pesca, solo con lo básico de un forastero recién llegado (**tienda de campaña, hoguera con cacerola, tronco de
  descanso y tu mesa de obras del campamento**).
- Desde la mesa de obras del campamento puedes ir montando poco a poco el **huerto de 3×3 parcelas con compostador**, el
  **gallinero con 3 gallinas**, el **generador eléctrico** (que ya no aparece plantado junto a tu tienda desde el primer día)
  y el **aspersor automático**.
- El pozo de piedra queda en la entrada oeste del pueblo (en el campamento tienes el lago cruzando el camino), y ya no se
  convierte la tienda en cabaña o casa de piedra ahí mismo: las casas de verdad se encargan al carpintero en los solares del
  pueblo.

## 2026-11-05 — El huerto, el banco de trabajo, el escondite y las escaleras de tu casa se usan de verdad allí
- Cuando mejoras tu casa, ahora aparecen dentro y junto a ella sus objetos reales en 2D y 3D para usarlos con **E**:
  - **Huerto doméstico:** te acercas a los surcos junto a tu casa y pulsas **E** cada dos días para cosechar pan y hierba
    medicinal (ya no aparecen solos en tu mochila a medianoche).
  - **Banco de trabajo y alquimia:** sobre el banco dentro de tu casa pulsas **E** para preparar cataplasmas curativas o
    destilar «polvo de ocaso» (ya no se destila hablando con el perista ni caen cataplasmas solas a medianoche).
  - **Escondite bajo las tablas:** usas con **E** las tablas sueltas del suelo de tu casa para meter o sacar tus ahorros
    ocultos (ya no tienes que pedírselo al carpintero en la calle).
  - **Escalera y trampilla de casa:** usas con **E** la escalera o trampilla dentro de tu casa para subir al altillo (+1),
    bajar al sótano (-1) o esconderte de una búsqueda menor (ya no se cambia de piso charlando con los vecinos).

## 2026-11-05 — Colarse o salir de las alcantarillas delante de la gente levanta sospechas
- Si bajas por una rejilla de la calle o sales por una escalerilla **delante de un guardia o del comisario**, bajas o
  sales igual, pero te ven colarte y **sube en 1 tu nivel de búsqueda** con un aviso en pantalla («¡X te vio colarte en
  las alcantarillas!»).
- Si quien te ve bajar o salir es **un vecino cualquiera**, no te busca la guardia, pero se queda con la copla y corre el
  chisme por el pueblo de que te vieron meterte en las alcantarillas.

## 2026-11-05 — El ganado del rancho y tus animales de corral existen de verdad
- En el corral del **Rancho del Sur** ahora pasean de verdad las ovejas y gallinas del ganadero, cambiando de tamaño según
  su etapa (cría, joven o adulto) y actualizándose cuando nace una camada o se vende una res.
- Cuando compras crías al ganadero o al carpintero, **aparecen de verdad dentro de tu corral** junto a tu granja y caminan
  por el cercado. Si dejas morir de hambre a una, desaparece del corral.
- Te acercas a cada animal tuyo y pulsas **E** para **darle de comer en mano** (gasta trigo, pan o zanahoria de tu mochila
  y lo hace crecer) o, cuando ya es adulto, para **esquilar la oveja** (+1 lana) o **recoger huevos** (+1 huevo), una vez
  cada dos días por animal.
- Ya no se da de comer a los animales charlando con el ganadero ni entra carne cocinada sola en tu mochila cada dos días.

## 2026-11-05 — Las alcantarillas se recorren a pie de verdad
- En la calle hay **tres rejillas de hierro** (junto a la Plaza, detrás de la Taberna y al oeste de la Herrería). Si aún
  no tienes la llave, el letrero avisa: «Cerrada: el perista vende la llave».
- Al comprarle la llave al perista, pulsas **E** sobre cualquiera de las tres rejillas para bajar a una **red de túneles
  y cámaras subterráneas conectadas entre sí**, por las que caminas libremente a cubierto de los guardias y testigos de la
  superficie.
- Puedes entrar por una rejilla, cruzar las galerías bajo tierra y subir a la calle por la **escalerilla** de otra salida
  distinta; salir por el Pasadizo del Contrabandista despista a la guardia y rebaja tu nivel de búsqueda una vez por semana.
- En cada cámara subterránea hay un **cofre de contrabando** que puedes registrar una vez al día para hallar piezas y
  monedas perdidas del pozo (con riesgo de trampa o aguas sucias). Ya no se exploran las alcantarillas por texto hablando
  con el perista.

## 2026-11-05 — La terminal lógica, el cuadro eléctrico y los 3 objetos de los robos son objetos de verdad
- La **Terminal Lógica** ya no se usa charlando con el arreglador: ahora es una máquina real sobre una mesa dentro de su
  taller (`[E] Usar la Terminal Lógica`). Si el arreglador u otro vecino despierto te ve trastear con ella, dará la voz
  de alarma y subirá tu búsqueda.
- El **cuadro eléctrico** ya no se sabotea hablando con el arreglador: ahora cuelga de la pared exterior norte del taller
  (`[E] Manipular el cuadro eléctrico`) con sus tres palancas y su piloto luminoso.
- Los **tres objetos de los grandes robos** del perista ya se ven sobre sus muebles dentro de cada edificio mientras
  tienes el golpe activo (`[E] Robar …`): el Sello de Lacre Noble en el escritorio de la mansión, el Cáliz de Plata en el
  altar de la capilla y el Libro Mayor de los Gremios en la mesa del ayuntamiento. Al robarlos desaparecen del sitio.

## 2026-11-05 — Los asaltos ocurren de verdad
- Al atardecer entran por el camino del este 3–6 bandidos encapuchados con espada (o 3–5 jabalíes, que de momento se
  ven como lobos). Avanzan hacia la plaza peleando con guardias, vecinos valientes y contigo.
- Les puedes herir con cualquier arma; malheridos huyen. Se rechaza el asalto si todos caen o huyen; si uno llega a la
  plaza, saquea las arcas. A las 23:00 se retiran (si queda la mitad, se llevan botín).
- La recompensa es para ti solo si has peleado. Hablar con el guardia ya no gana el asalto: solo te apuntas.
- Las barricadas pagadas hacen que lleguen con menos vida.

## 2026-11-05 — Los letreros de los edificios ya no se pisan
- Solo se ven los letreros de los sitios cercanos a ti (unos 150 pasos) o el que tengas bajo el ratón.
- Si dos se pisan, se queda el más cercano (o el que apuntas con el ratón).

## 2026-11-05 — Menos letreros encima de los vecinos
- Al pasar el ratón solo enseña ficha el vecino más cercano al puntero, y corta: nombre, oficio y qué está haciendo.
- La ficha completa (bolsillo, rasgos, humor, hambre, sueño…) sale manteniendo Alt.
- Ya no salen fichas solo por estar cerca del jugador. El letrero de la E va debajo de los pies para no pisarla.

## 2026-11-05 — La tecla E ya no se lía
- Encima de lo que vas a usar sale un letrero «[E] …» (hablar con alguien, abrir la puerta, montar, gestionar el
  negocio, abrir el cofre…), así sabes qué pasará antes de pulsar.
- Manda el ratón: si apuntas a una de las cosas cercanas, esa es la que se usa.
- Si hay varias, Mayús + rueda del ratón o la tecla G pasan a la siguiente (el letrero dice «1/3»).
- A caballo, «bajar del caballo» va la última para que puedas hablar o abrir puertas sin bajarte.

## 2026-11-05 — El caballo existe de verdad
- Al comprarlo aparece junto al ganadero del Rancho del Sur, animado (anda, pace, galopa). En 2D (F10) se ve un dibujo
  provisional.
- E a su lado: montas; E otra vez: bajas y se queda esperando ahí. Solo montado vas un 45 % más rápido y no puedes ir en
  sigilo. Bajas solo al entrar en un edificio, acostarte o si te lleva la guardia.
- Se guarda dónde está y si ibas montado. Se mantiene el +15 % en las expediciones.
- Arreglo: ya no aparece dentro de la tienda del ganadero; si quedaría dentro de un edificio, sale a la calle por delante de la puerta.

## 2026-11-05 — Impuesto sobre lo que gana cada vecino (por tramos)
- Los sábados cada vecino paga según lo que GANÓ esa semana, no según sus ahorros: hasta 4 de oro al día, nada; de lo
  que gane entre 4 y 15 al día, un 15 %; de lo que pase de 15 al día, un 30 %. El edicto del alcalde (bajos, normales,
  altos) sigue multiplicando. Los recién llegados empiezan a contar al día siguiente de llegar.
- Medido en 22 días de partida sola: las arcas suben a ~900 cada sábado y bajan a ~385 antes del siguiente; ya no se
  arruinan. Con 20 % y 35 % sobraban ~250 a la semana (atrae asaltos).

## 2026-11-05 — El pueblo gana dinero con el mercado y las rutas
- Cada vendedor del mercado del miércoles paga 4 de oro por su puesto a las arcas.
- Las rutas comerciales dejan un arancel de 4 de oro al pueblo en cada intercambio (también en tus remesas). Es oro que
  entra de fuera del valle: los pueblos de fuera reponen su fondo de comercio cada lunes (+20, hasta 90).
- Quien recibe lo importado paga 1 de oro por unidad al pueblo de fuera.

## 2026-11-05 — Arreglos de la auditoría (2.ª parte): ningún oro nace ni desaparece
- Lo que cobras lo paga alguien de verdad: el tablón y los sueldos salen de las arcas; el golpe lo paga el perista;
  abastecer una tienda ajena lo paga su dueño; el cofre de una familia tiene lo que tengan sus miembros.
- Lo que pagas lo recibe alguien: el herrero por las mejoras, el médico por la cama de urgencias, la posadera por la
  cama, las cenas y la cena de paz, las arcas por multas y fianzas, el titular cuando le compras su negocio.
- Los vecinos ya no ganan oro del aire: las apuestas se juegan contra el posadero, ahorrar no crea monedas, los
  jornales los paga un taller con oro, y tus negocios solo ganan con ventas que paga un vecino.
- Puede notarse: si las arcas o los vecinos están sin dinero, algunos pagos no llegan ese día.

## 2026-11-05 — Arreglos de la auditoría (1.ª parte)
- F9 vuelve a cargar la partida; cambiar entre 2D y 3D es ahora F10.
- Cortar el circuito de farolas deja de verdad las calles a oscuras de noche.
- De 20:00 a 6:00 tu farol se ve en la mano al momento y te deja ver más lejos entre la niebla.
- El arcabuz en la mano se conserva al guardar y cargar.
- En tu sótano ya no aparece la salida de las alcantarillas.
- Si te pillan la escritura falsa al comprar casa, salen los guardias (y ya no te la compra con hipoteca a la vez).
- Fundar o mejorar el Puesto del Paso pide pulsar E dos veces.

## 2026-11-05 — Jabalíes con aspecto de lobo (provisional)
- En 3D los jabalíes se ven como lobos grises animados, porque no hay un jabalí del mismo estilo. Se siguen
  comportando como jabalíes (nombre, sitio, huida y ataque).
- Los animales que bajó el usuario (lobo, ciervo, corzo, zorro, ardilla, pájaro) no traen animaciones: guardados sin usar.

## 2026-11-05 — Ciervos, zorros y perros animados
- Ya no se deslizan: andan, galopan al huir, se quedan quietos o pacen, y al morir hacen su caída. Son los mismos
  animales de Quaternius, en su versión animada (gratis, CC0).

## 2026-11-05 — Ciervos, zorros y perros en 3D
- En la vista 3D, ciervos, zorros y perros tienen modelo 3D: siguen al animal, miran hacia donde andan y se tumban de
  lado al morir o quedar aturdidos. Aún no mueven las patas. Con F9 vuelve el dibujo plano.
- Conejo, jabalí, gato y gallinas siguen planos (faltan modelos). Vacas y caballos no andan por el mapa.

## 2026-11-06 (noche) — Edificios con sus piezas quietas juntas
- Cada edificio junta muros, suelos y muebles en una sola pieza por material (se ven igual). Puertas, ventanas,
  postigos, reja del calabozo, cuerpos de la morgue, tejado y altillo siguen sueltos.
- Piezas 3D dibujadas: de 2.317 a 1.409. La velocidad apenas cambia: lo que más frena es lo que «piensan» y cómo
  caminan los vecinos, no el dibujo.

## 2026-11-06 (noche) — Casas iniciales repartidas y árboles agrupados
- La mitad de las casas con que empieza la partida salen en los barrios apartados (Lago, Caseríos, Molino), así el
  pueblo nuevo se ve desde el primer día.
- Árboles y rocas iguales se dibujan juntos por zonas (se ven igual y se siguen talando). Gana poco: la mayor parte
  de lo que dibuja el juego son los edificios (unas 1.500 piezas) y los vecinos (unas 360).

## 2026-11-06 (noche) — La aldea empieza con 40 vecinos (provisional)
- Al empezar una partida nueva ya hay unas 40 personas (pueden ser algunas más si llegan familias con hijos):
  recién llegados sin oficio, solos, en pareja o en familia, con casas ya levantadas en solares libres.
- Es provisional, para probar todos los sistemas a la vez. Las partidas cargadas y las pruebas no cambian.
- Medido: de 18 a 43 vecinos, el juego pasa de unos 31 a unos 27 fotogramas por segundo.

## 2026-11-06 (noche) — Calles de pueblo, no de cuadrícula
- Las dos callejas del norte hacen una curva suave y las casas de su fila la siguen; en la calle norte algunas casas
  se retiran unos pasos.
- Dos huecos en las filas: el Pozo de la Ronda (sirve para coger agua y lavarse) y un huerto vecinal.
- El mapa del valle dibuja las calles curvas.

## 2026-11-06 (noche) — Tu casa mejorada y el gallinero en 3D
- La cabaña (madera y paja) y la casa de piedra (piedra y teja, con cofre) se ven en 3D, con cama, luz y tejado que
  se abre al acercarte.
- Gallinero con cerca de postes; si el zorro abre un agujero, falta ese tramo hasta que lo arreglas. Comedero con
  más o menos grano y nido con huevos cuando los hay. Las gallinas siguen planas.

## 2026-11-06 (noche) — Cada casa con su precio
- Casita 80 de oro, casa 100, casona 140. Los vecinos buscan la que pueden pagar con sus ahorros.
- Al comprar un solar ves si es casita, casa o casona y su precio; la hipoteca y la reventa van con el tamaño.

## 2026-11-06 (noche) — La aldea crece: tres tamaños de casa y barrios nuevos
- Casitas, casas y casonas mezcladas en cada calle. El tamaño va con el bolsillo de quien la encarga; la casona tiene
  una cama más.
- Barrios nuevos con sus sendas: Barrio del Lago (orilla sur, con embarcadero), Caseríos del Bosque (al oeste del
  bosque, con leñeros) y Molino del Este (junto al Puesto del Paso, con molino).
- Los vecinos huraños prefieren los barrios apartados; los demás van cuando el centro se llena.
- Arreglo: el pueblo 3D daba un error cuando desaparecía el cartel de un solar al construirse.

## 2026-11-06 (noche) — Niebla nocturna
- De noche la niebla se cierra sobre el valle: claro alrededor de ti y, a lo lejos, solo siluetas.
- Los bancos de niebla se mueven despacio; farolas y ventanas encendidas la atraviesan con brillo ámbar.
- Con el farol en la mano ves más lejos. De momento es solo visual: los vecinos ven igual que antes.

## 2026-11-06 (noche) — Objetos quietos en 3D
- Pozos, farolas y tablón de misiones ya no salen dos veces (el dibujo plano se esconde bajo el 3D).
- En 3D: tienda de campaña de lona, hoguera con caldero y su luz, tronco para sentarse, cartel, generador y aspersor.
- Huertos con tierra en surcos que se oscurece al regar; los cultivos crecen de brote a planta (zanahoria, col, trigo).
- Compostador como cajón de tablas. Los pozos aparecen también en los solares nuevos.
- Arreglo: al volver a 2D con F9, los pinos y rocas no reaparecían.
- Sigue plano: la casa mejorada del jugador (cabaña o piedra), el gallinero y los animales.

## 2026-11-06 (noche) — Fuera las 446 advertencias del editor
- Las fichas de color de 121 modelos 3D traían un dato de «luz ambiente» que Godot no usa y por el que avisaba una vez
  por color al importar. Quitado. Los modelos se ven igual.
- Decisión del usuario: el proyecto pasa de 2D a 3D. La vista 2D (F9) se mantiene de respaldo porque las pruebas la usan.

## 2026-11-06 (tarde) — Notas para seguir en otro ordenador
- Guía nueva de cómo bajar el proyecto en otro ordenador y qué toca hacer ahora.
- Apuntado en el tablero lo que sigue en plano (animales, pozos, farolas, huertos, campamento, tablón…).

## 2026-11-06

### El pueblo se ve en 3D de verdad
- **Personajes dentro del mundo:** los vecinos y tú estáis dentro del pueblo 3D. Las casas os tapan, proyectáis
  sombra y os ilumina el sol o la farola de turno.
- **Sombras y tejados de verdad:** el sol proyecta sombras de casas, árboles y personas. Los tejados son a dos aguas y
  cada casa es algo distinta: altura, tejado, ala, porche y chimenea. La iglesia tiene campanario.
- **Suelo y bosque 3D:** hierba 3D en todo el valle; el bosque, más oscuro, tiene pinos 3D que al talarlos dejan tocón,
  y la cantera, rocas 3D.
- **Lago del Oeste tres veces más grande,** con orilla de arena, sauces, el muelle y el lavadero en la orilla.
- **Menos amontonamiento al empezar:** se quitaron el carro, las cajas y los animales de adorno que no pintaban nada.
- **Arreglado:** al pasar de 2D a 3D con F9, tu personaje se quedaba quieto como una foto.

## 2026-11-05

### Estética retro 3D: «parece retro pero no lo es»
- **Vecinos que se mueven como personas:** andan, corren, talan, siegan, riegan, cargan, rezan, duermen tumbados, caen al
  morir, apuntan y golpean con animaciones reales en vez de balanceos de muñeco.
- **Un pueblo con un solo estilo:** casas con muros de entramado de madera, piedra o ladrillo y tejados de teja, pizarra
  o paja, todo con texturas pixeladas pintadas a mano. Volvieron las puertas, las ventanas y las chimeneas, que se
  habían perdido.
- **El 3D casa con el pixel art:** el mundo y los personajes se dibujan con píxeles gruesos y cuadrados.
- **Tejados a la vista:** el pueblo ya enseña sus tejados; solo se abren los de los edificios que tienes cerca.
- **Día nostálgico y noche inquietante:**
  - de día, luz cálida y colores algo desvaídos, como una foto vieja;
  - el atardecer es largo y dorado;
  - de noche todo queda frío y oscuro, salvo los charcos de luz de las farolas, las ventanas encendidas y un halo
    alrededor de ti (más grande con farol).

## 2026-11-04

### Transición 3D (Fase 3): Modelos 3D esculpidos y texturas reales integrados en personajes, armas, edificios y naturaleza
- **Personajes humanos esculpidos con ropa de fantasía:** los muñecos de cajas provisionales fueron reemplazados por cuerpos humanos 3D esculpidos y articulados (hombre y mujer, con trajes de aldeano y de explorador/guardia), cabezas con rostro, ojos, cejas, peinados 3D y barbas reales, teñidos según el oficio y la armadura de cada vecino.
- **Armas medievales, herramientas y armas de fuego 3D reales en mano:** espadas, dagas, hachas, martillos, picos, arcos de madera, guadañas, lanzas, escudos, jarras, libros, faroles y pistolas/arcabuces usan ahora modelos 3D esculpidos sujetos directamente a las manos del esqueleto.
- **Pueblo, interiores y naturaleza con modelos y texturas reales:** las paredes, suelos y tejados lucen texturas reales de piedra, ladrillo, estuco, madera y teja; los interiores cuentan con camas, mesas, sillas, estanterías con libros, cofres, barriles, calderos, yunques, bancos de trabajo, altares, candelabros y jaulas esculpidas; y el exterior incorpora árboles reales (robles, abedules, pinos y sauces), pozos, carros, cenador, vacas, caballos y burros en el rancho, cripta y lápidas talladas en el cementerio y farolas de hierro forjado.

### Transición 3D (Fase 2): Pueblo, edificios, interiores y tejados 3D con apertura automática + «Puesto del Paso» en el mapa
- **El pueblo entero en 3D:** caminos, plaza adoquinada, pozos, bancos, Parque del Robledal, Lavadero, Mirador del Lago, Ciénaga del Oeste, Cementerio Parroquial (con tumbas 3D reales), solares en obras y todos los edificios cuentan ahora con maquetas arquitectónicas en 3D alineadas al milímetro con el mapa.
- **Tejados que se abren solos e interiores 3D:** cada edificio tiene tejado a cuatro aguas con chimenea, puertas 3D que giran al abrirse y ventanas con contraventanas. Al entrar tú, entrar un vecino o pasar el ratón por encima, el tejado se retira suavemente y deja ver el interior 3D con sus camas, mesas, mostradores, cofres, fragua, morgue con camillas, celda de comisaría, bancos de la capilla, estanterías de la biblioteca y pupitres de la escuela.
- **Altillos (`+1`), alcantarillas (`-1`) y farolas con luz real:** cuando subes al piso de arriba ves la planta del altillo 3D con su escalera y camas; cuando bajas al subsuelo ves las bóvedas subterráneas de las alcantarillas; y de noche las farolas proyectan luz cálida 3D sobre las calles y fachadas si la red eléctrica funciona.
- **El «Puesto del Paso» ya existe físicamente en el mapa:** al final del camino del este se levanta ahora el recinto del asentamiento fronterizo (tanto en 3D como en 2D), donde puedes acercarte a pulsar `E` para fundarlo, recaudar su arca o levantar el aserradero, el granero y la atalaya, mientras los colonos reclutados caminan hasta allí a trabajar cada mañana.
- **Cambio instantáneo 3D / 2D con `F9`:** la tecla `F9` activa o desactiva a la vez todo el escenario 3D y los personajes 3D, volviendo al instante al mapa 2D original sin perder nada.

### Transición 3D (Fase 1): Maquetas 3D articuladas para jugador y vecinos, equipo visible, prótesis y Visor 3D
- **Muñecos 3D articulados en partida:** el jugador y todos los vecinos cuentan ahora con un modelo 3D provisional por piezas (cabeza con ojos, cejas, peinado y barba, torso con delantal de oficio o capa, brazos y piernas articulados que giran en 360 grados).
- **Armas, herramientas, armaduras y prótesis visibles:** todo lo que equipas (espada, martillo, hacha, pico, arco, hoz, regadera, caña, farol nocturno, cascos, petos, grebas, botas y sombreros de oficio) y las amputaciones o prótesis mecánicas de hierro y cobre se ven directamente en el cuerpo del personaje.
- **Arcabuz de chispa en mano (`[9]`):** si tienes el arcabuz y cargas de pólvora, puedes empuñarlo con la tecla `9` y disparar en tiempo real con fogonazo, humo 3D y estampido que alerta a los vecinos cercanos.
- **Visor 3D en primer plano (`[F8]`) y cambio en caliente (`[F9]`):** pulsa `F8` en cualquier momento para abrir un estudio de inspección 3D y probar de cerca todos los arquetipos, armaduras, armas, prótesis y animaciones, o pulsa `F9` para alternar al instante entre las nuevas maquetas 3D y los dibujos 2D originales (conservados íntegramente junto con una copia de seguridad del proyecto).

### Vida propia del pueblo, gasto de las arcas y auditoría completa del proyecto
- **Maestros Artesanos que venden de verdad:** se corrigió el título repetido («Maestro Maestro») y ahora los vecinos adinerados y los compradores del mercado de los miércoles adquieren sus Obras Maestras pagando de su bolsillo, de modo que sus existencias se mueven en vez de quedarse paradas.
- **El rebaño del rancho se renueva:** cuando los animales adultos del Rancho del Sur cumplen su ciclo de engorde, el ganadero los vende al carnicero (cobrando de su bolsillo y sumando carne y lana) y trae crías nuevas, manteniendo vivo el ciclo del corral.
- **Niños en la escuela y graduaciones:** las familias recién llegadas traen hijos en edad escolar que pueden alojarse también en camas libres de la posada; el maestro da clase desde que hay al menos un alumno, los niños acuden al aula por las mañanas entre semana y al cumplir los dieciséis años se gradúan con ventaja en su primer oficio.
- **El ayuntamiento invierte el dinero que sobra en las arcas:** cuando las arcas municipales acumulan mucho oro, el pueblo invierte parte del superávit en reforzar la defensa vecinal, financiar investigaciones en el taller del ingeniero, abrir rutas comerciales y cubrir parte del sueldo de la guardia y las autoridades.
- **Auditoría completa del proyecto (`docs/AUDITORIA_PROYECTO_COMPLETA.md`):** se revisaron todos los sistemas del juego para asegurar que ninguna recompensa forense o del hampa salga de la nada ni se pierda ningún pago (todo sale o entra del bolsillo de los implicados y de las arcas municipales) y que los discursos electorales también puedan salir mal si te trabas ante la plaza.

### Asaltos con motivo, que se ven venir y se pueden ganar
- **Por qué vienen:** los bandidos ya no llegan por calendario. Se fijan en el pueblo cuando las arcas están muy llenas, cuando las rutas comerciales corren la voz o cuando el Puesto del Paso les queda de camino. Un pueblo pobre y bien defendido deja de interesarles.
- **Se ven venir:** por la mañana te avisan de quién viene y por qué. A media tarde la guardia y los vecinos con más arrojo se reúnen en el camino del este, y el asalto llega al atardecer. Hasta entonces puedes encabezar la defensa hablando con el comisario o un guardia.
- **Se pueden ganar:** además de la guardia, defienden hasta 3 vecinos valientes. Si se pierde, los defensores salen magullados y se saquean las arcas.
- **Arreglado:** un error en la capilla al comprar una bula de perdón rompía la confesión.

### Revisión de PF–PQ: textos y detalles corregidos
- **Caballo:** ahora sí te hace ir un 25 % más rápido, también después de cargar la partida.
- **Amputaciones:** perder un miembro entristece al vecino (antes le alegraba) y la prótesis le anima de verdad.
- **Cambiar de oficio:** quien cambia de oficio vuelve a empezar de cero; la ventaja de la escuela solo vale para el primer trabajo.
- **Asentamiento:** se aclara que por ahora solo se gestiona desde los menús; queda pendiente darle un lugar en el mapa.
- Los nombres y el trasfondo nuevos (historia principal, alcantarillas, rutas…) quedan apuntados como provisionales.

### Revisión de PF–PQ: se cierran los atajos de dinero fácil
- **Tu negocio:** el mostrador empieza vacío; cada artículo se vende a su precio (una madera vale 3 y una prenda 14) y de noche un ladrón puede llevarse la mitad de la caja que no hayas recaudado (menos si tienes dependiente).
- **Corral:** los animales solo crecen y dan carne si les das de comer; tras 5 días sin comida mueren.
- **Pinos:** uno al día como máximo y hasta 12; ya no devuelven la semilla y vuelven a aparecer al cargar la partida.
- **Obras maestras:** el coleccionista paga 30, menos que en el taller (35), así que revenderlas no da ganancia.
- **Red eléctrica:** si el apagón lo provocaste tú, arreglarlo no se cobra; reparar no da luz sin generador encendido; cualquier vecino cercano puede verte tocar los cables.
- **Incursiones:** las barricadas pagadas llegan como mucho a +4 y cada incursión rechazada hace más fuerte a la siguiente; la atalaya del asentamiento ya no se pierde tras la primera.
- **Terminal:** solo está en el taller del ingeniero, no en la comisaría.

### Revisión de PF–PQ: cuatro fallos graves arreglados
- **Pisos y alcantarillas:** solo puedes subir al altillo o bajar al sótano estando en tu casa, y al salir vuelves solo a la calle, así que los vecinos vuelven a verte. Explorar las alcantarillas es una salida de ida y vuelta: ya no te quedas «bajo tierra» en la plaza, donde nadie podía verte robar.
- **Arcabuz:** ahora hace daño de verdad. Ya no se dispara desde la conversación con un vecino; de momento sirve en la defensa contra incursiones.
- **Historia principal:** llegar a alcalde ya cuenta para el capítulo IV.
- **Borrar la búsqueda de la guardia:** el sótano, el Pasadizo del Contrabandista y el archivo policial de la terminal comparten una espera de una semana.
- Informe completo y puntos pendientes en `docs/AUDITORIA_PF_PQ.md`.

### Escalado del pueblo a 100+ vecinos, ronda norte de solares y casas de dos plantas con 4 camas
- **Crecimiento hasta 100 vecinos y nueva ronda del norte:** el límite del pueblo sube a 100 habitantes y se abre una tercera calle al norte con siete solares residenciales nuevos. Además, cuando una casa instala un altillo o cuando el pueblo necesita más camas y ya no quedan solares vacíos, las viviendas se amplían hacia arriba para alojar hasta a 4 vecinos por casa.
- **Simulación ligera para otros pisos y vecinos lejanos:** los habitantes que están en otro nivel (en el altillo o en las alcantarillas) o muy lejos de tu vista se actualizan de forma simplificada para mantener el rendimiento fluido cuando la ciudad crece.

### Crear tu propio asentamiento fronterizo e Historia Principal en 4 capítulos
- **Fundar y gobernar el «Puesto del Paso»** (por ahora solo desde los menús, sin lugar en el mapa): puedes fundar tu propio asentamiento en el paso fronterizo abonando la carta municipal y aportando madera y piedra. Allí puedes reclutar vecinos sin oficio como colonos (con jornal diario pagado del arca del asentamiento), levantar un aserradero, un granero y una atalaya de guardia, y recaudar el excedente de los peajes comerciales.
- **Historia Principal en el panel de misiones (`[L]`):** la pestaña «👑 Principal» del diario de misiones sigue ahora un arco de cuatro capítulos («Las Raíces del Valle», «El Pulso Bajo la Piedra», «La Máquina de Cobre» y «La Placa de Petri») que conecta tu llegada al valle, los hallazgos subterráneos y arqueológicos, la ingeniería del generador y el destino político de la comunidad.

### Armas de fuego de chispa y Terminales lógicas electromecánicas con hackeo
- **Arcabuz de chispa y cargas de pólvora:** cuando el pueblo ha investigado las Cerraduras de Precisión, puedes encargar un arcabuz de chispa en la herrería o el taller y comprar cargas de pólvora negra. Llevar el arma cargada refuerza de forma decisiva la defensa contra incursiones (disparar desde la conversación se retiró en la revisión posterior; queda pendiente usarlo en combate).
- **Terminales lógicas y hackeo electromecánico:** una vez al día puedes manipular en sigilo la consola electromecánica de tarjetas perforadas y relés (con mejores probabilidades si se han investigado los Condensadores Voltaicos o llevas una bobina de cobre) para desviar un reembolso desde las arcas municipales, borrar cargos en el archivo policial o reprogramar el controlador de la red eléctrica; si fallas, salta una descarga voltaica y se activa la alarma policial.

### Niveles verticales por capas y Alcantarillas bajo el pueblo
- **Sistema de niveles verticales (sótano, calle y primer piso):** el mapa incorpora capas verticales en las mismas coordenadas (`-1` sótano y alcantarillas, `0` calle y planta baja, `+1` altillo o primer piso encargable al carpintero). Los vecinos que están en otro piso se ven atenuados y no pueden presenciar como testigos lo que ocurre en un nivel distinto al suyo.
- **Alcantarillas con localizaciones subterráneas nuevas:** comprando la llave maestra y el plano al perista o al arreglador puedes bajar al nivel `-1` para explorar una vez al día la Cisterna Vieja bajo la Plaza, el Pasadizo del Contrabandista (que además te ayuda a despistar a la guardia) y la Bóveda Inundada del Antiguo Gremio, recuperando piezas y monedas extraviadas por las rejillas o arriesgándote a sufrir mordeduras de ratas e infección en las aguas negras.

### Expediciones de exploración y Caballos y carretas de carga en el rancho
- **Caballos de silla y carretas de carga:** en el Rancho del Sur puedes comprar al ganadero un caballo de silla (mejora tu desplazamiento y aumenta las probabilidades de éxito en las expediciones) y una carreta de carga (incrementa el rendimiento de cada remesa que envíes por las rutas comerciales).
- **Expediciones de exploración fuera del valle:** una vez al día puedes organizar expediciones a las Ruinas de Cobre del Oeste, las Grutas de Cristal del Norte o la Atalaya Hundida del Pantano pagando los víveres al guía; si superas los peligros del camino regresas con bobinas antiguas, mineral o hierbas y sumas apuntes de campo a la biblioteca para acelerar las investigaciones del taller.

### Árbol de investigación tecnológica e Incursiones organizadas contra el pueblo
- **Ingeniería y árbol de investigación en el taller:** en el Taller de Reparaciones puedes financiar proyectos tecnológicos encadenados («Engranajes Hidráulicos», «Cerraduras y Empalizadas de Precisión» y «Condensadores Voltaicos»). El ingeniero avanza cada día aprovechando las lecturas acumuladas en la biblioteca o la chatarra que le lleves, y cada invento terminado mejora de forma permanente la producción y la defensa del valle.
- **Incursiones organizadas contra el pueblo:** cuando crece la amenaza en las fronteras, los vigías dan la alarma la víspera de un asalto contra el pueblo. Puedes pagar barricadas y milicia vecinal ante el comisario o los guardias y encabezar la defensa para cobrar recompensa de las arcas si rechazáis a los asaltantes; si las defensas ceden, saquean las arcas municipales, sabotean puestos y dejan heridos.

### Reforestación del ecosistema y Rutas de comercio con otros asentamientos
- **Sembrar árboles que enriquecen el bosque y la fauna:** hablando con el leñador puedes plantar pinos jóvenes usando semillas de cultivo o comprando un plantón de vivero. Cada árbol plantado crece como un pino real en el bosque, hace rebrotar hierbas y setas silvestres, atrae venados y conejos a los claros y mejora la fertilidad del suelo para dar más madera y grano al valle.
- **Rutas comerciales con otros lugares:** puedes abrir rutas regulares con asentamientos vecinos («Paso Alto», «Puerto Fluvial del Este» y «Vega del Sol») pagando la carta de arancel a las arcas municipales. Las rutas activas cambian a diario excedentes de los talleres locales por hierro, pescado o trigo importado (repartiendo los derechos de paso entre el artesano y el ayuntamiento) y te permiten enviar una remesa propia al día.

### Amputaciones y prótesis médicas y Sabotaje lógico de la red eléctrica
- **Amputaciones de urgencia e implantes protésicos:** cuando una herida en un brazo o una pierna se gangrena por una infección grave, el médico la amputa de urgencia para salvar la vida del paciente. Tanto los vecinos con ahorros como tú en la consulta del médico podéis encargar una prótesis articulada de hierro y cuero (pagando al médico y al arreglador y usando un kit de reparación) para recuperar por completo el miembro perdido.
- **Red eléctrica con circuitos independientes que se pueden sabotear:** en el cuadro eléctrico del taller puedes manipular por separado el circuito de las farolas (para dejar las calles a oscuras), la bomba eléctrica de riego (para cortar el aspersor) o el generador general (con riesgo de que salte un chispazo y te vea la guardia). Cuando la línea cae, el arreglador la repara a diario con cargo a las arcas municipales, o puedes repararla tú entregando una bobina de cobre para cobrar la recompensa del ayuntamiento.

### Cría de animales con etapas de crecimiento y Carreras y peleas de animales con apuestas
- **Animales que crecen desde crías hasta adultos:** tanto en el Rancho del Sur como en tu propio corral las crías pasan por etapas de crecimiento (cría, joven y adulto). Puedes comprar crías de aves, sabuesos o corderos, alimentarlas con grano o pan de tu mochila para que crezcan más rápido y ganen vigor, y recoger carne cuando llegan a adultos.
- **Carreras de animales y peleas clandestinas de gallos y perros:** una vez al día puedes apostar contra el bolsillo real de los vecinos en carreras de animales o en peleas clandestinas de gallos y perros (con riesgo de que la guardia oiga el alboroto); criar un ejemplar adulto vigoroso mejora tus opciones, aunque siempre puedes perder la apuesta.

### Idolatría obsesiva y Acompañantes del jugador
- **Admiradores obsesivos (muy raros):** un vecino solitario puede obsesionarse en secreto con alguien célebre del valle, seguirle a todas partes, dejarle regalos anónimos pagados de su propio bolsillo y coger celos enfermizos de sus amistades o pareja. Puedes tantear a los vecinos para descubrir quién es (sin que el menú lo delate antes), hacerle entrar en razón o avisar al afectado a cambio de una recompensa de su bolsillo.
- **Acompañantes y escoltas por el valle:** puedes pedirle a un buen amigo que te acompañe por el pueblo gratis o contratar a un vecino como escolta pagándole un jornal diario de tu bolsa al suyo. Tu acompañante camina a tu lado, te respalda para imponer respeto ante otros vecinos (una vez al día, con tirada de riesgo) y vuelve a sus quehaceres cuando lo despides o si dejas de pagarle.

### Graduación escolar con ventaja de oficio y Negocio propio con publicidad
- **Graduarse de la escuela da ventaja en los oficios:** ahora se cuenta a cuántas clases asiste cada niño entre semana; cuando cumple la mayoría de edad se gradúa con días de dominio adelantados según lo aprendido, de modo que al estrenarse en un oficio o heredar un taller empieza más cerca de ser Maestro.
- **Montar tu propio negocio desde cero y hacerle publicidad:** en un solar construido tuyo puedes encargarle al carpintero un mostrador para abrir tu propio bazar, abastecerlo con mercancía real de tu mochila, contratar a un vecino parado como dependiente (que cobra su jornal diario de la caja), pregonar carteles y publicidad por el pueblo para duplicar la clientela durante tres días y recaudar las ventas que los vecinos pagan de su bolsillo.

### Fama de los vecinos y Maestros Artesanos con estilo propio
- **Reputación y fama individual en el pueblo:** cada vecino gana o pierde fama según lo que hace (alcanzar maestría en su oficio, ganar peleas o ser alcalde sube su prestigio; ser pillado robando, engañar a su pareja o cometer un crimen lo hunde en la infamia). Su rango («🌟 Célebre», «✨ Conocido», «😠 Mal visto» o «🌑 Infame») se ve en el glosario de vecinos y cuando preguntas por él en el pueblo.
- **Maestros Artesanos y Obras Maestras de autor:** los artesanos con experiencia y buena mano alcanzan el título de Maestro con un estilo propio de su gremio y elaboran Obras Maestras firmadas con existencias limitadas. Los vecinos ricos y los nobles las compran pagando de su bolsillo, y en el mercado de los miércoles sus puestos tienen más prestigio.
- **Mecenazgo, coleccionismo y rumores en la plaza:** puedes comprar Obras Maestras en los talleres, patrocinar con mejores materiales a un artesano prometedor para que alcance antes la maestría, vender piezas firmadas a coleccionistas adinerados (que te pagan de su bolsillo) o regalarlas, y hablar maravillas o pregonar las faltas de un vecino en la plaza (con tirada de riesgo y días de espera).

### Revisión de las 29 mecánicas nuevas: errores, destripes y dinero fácil
- **Ya no fallan:** desmontar un crimen por imitación y los intrusos nocturnos funcionan sin errores.
- **El misterio vuelve a estar a salvo:** las cartas de amantes se encuentran hurgando bolsillos (se ofrece con cualquiera, así que no delata nada, y te pueden pillar). Consultar pólizas de vida cuesta 10 de oro, se puede preguntar por cualquier víctima, y también hay pólizas inocentes entre parientes: tener una no prueba que sea el asesino.
- **Sin dinero fácil:** vender una casa salda primero la hipoteca; la escritura falsa ya no inventa oro en las arcas y tiene riesgo de que descubran el sello falso (pierdes el papel y te busca la guardia); la caravana de contrabando solo acampa de noche cada tres días y con lotes limitados; los carteristas pueden ser pillados (y la guardia te vigila), máximo 3; esconderte en el sótano solo una vez por semana; la lejía se usa en la escena, no desde un diálogo.
- **Retos de verdad:** el debate electoral y el reto al jefe del hampa se pueden perder (el reto, una vez por semana); un debate por campaña; el patriarca solo te hace caso una vez por semana; enseñar un oficio cuesta 10 de oro en herramientas.
- **Detalles:** el intruso solo se enfrenta hablando con él, y si no lo haces se lleva algo de tu escondite; el indultado recupera el apellido de su familia; quien compra tu casa se muda a ella.

### Las 29 mecánicas pendientes de los siete bloques: crímenes, clanes, linaje, capilla, alcaldía, casa y bajos fondos
- **Crímenes y escena del crimen:** ahora puedes fregar la sangre de la escena con lejía antes de que la vean (con doble confirmación), sobornar al médico para falsear la autopsia, contratar a un limpiador nocturno para borrar rastros o chantajear a un vecino del que sepas un trapo sucio para que confiese en tu lugar. Además, hay pólizas de seguro de vida sospechosas, asesinos que trucan la hora de la muerte (descubrible revisando el cuerpo) y crímenes por imitación que culpan a un asesino anterior hasta que los desmontas.
- **Clanes y linaje:** cada familia tiene un patriarca o matriarca a quien obedecen los suyos; los clanes enemistados se sabotean los talleres de noche; circulan cartas de amor secretas que puedes interceptar, entregar o destapar ante la pareja; hay bodas concertadas con dote, padrinos de bautizo (que dan propina los domingos y acogen al niño si queda huérfano), niños a los que puedes enseñar un oficio para que empiecen con ventaja al crecer, y jóvenes que se escapan de noche al mirador.
- **Capilla y alcaldía:** cuando el cura no mira, puedes ponerte su hábito en el confesionario para escuchar pecados y cobrar penitencias, o fingir un milagro en el altar para ganar devotos y limosnas. En la alcaldía hay debates públicos entre candidatos que mueven votos, indultos para rehabilitar vecinos repudiados y el decreto de «Tributo de paz», que multa del bolsillo a quienes se peleen en la calle para llenar las arcas.
- **Tu casa y los bajos fondos:** puedes dar fiestas en casa para reconciliar vecinos, instalar un sótano secreto para esconderte cuando te busca la guardia y un hogar de leña que calienta y cura al dormir, defender tu puerta de intrusos nocturnos y vender tu casa reformada según el atractivo del barrio. En el mercado negro llega la caravana de contrabando de medianoche, puedes echar timbas de dados apostando contra el bolsillo de los vecinos, reclutar parados en tu red de carteristas, falsificar escrituras municipales para ahorrar en la compra de casas o locales y retar cara a cara al jefe de la «Red de las Sombras».

### Auditoría: veneno, confirmaciones, cama y fallos menores
- **El veneno ya no es un asesinato gratis:** alguien puede verte echarlo (y te buscarán); si nadie te ve, la víctima muere al día siguiente, y a veces lo vomita y sobrevive.
- **Pulsar E ya no compra ni decide de golpe:** comprar un solar, cambiar los impuestos o inscribirte como candidato piden una segunda E para confirmar.
- **Tu cama ya funciona como una cama:** solo de noche, y pasas la noche durmiendo hasta la mañana.
- **Alcaldía:** la moción contra el alcalde necesita firmas de vecinos que te aprecien y solo se puede intentar una vez al mes; nombrar comisario ya no borra tu búsqueda; solo puedes chantajear al alcalde si sabes algo turbio suyo.
- **Sin oro de la nada:** las recompensas de familias y herencias salen del bolsillo de quien te paga, y el testamento reparte el oro real del muerto.
- **Casas y familia:** quien se muda contigo deja su casa anterior; el niño que adoptas se viene a tu casa y no se puede volver a adoptar; cuando un niño cambia de apellido (al ser adoptado o reconocido por su padre) todos los registros del pueblo se actualizan con su nuevo nombre; una familia solo te guarda rencor por matar a uno de los suyos si alguien te vio o la ley te culpa.

### Auditoría de las 70 mecánicas: arreglos del misterio y del oro infinito
- **El misterio de los asesinatos ya no se destripa solo:** el menú del comisario ya no muestra el nombre del asesino antes de que lo averigües; la familia de la víctima solo odia al culpable cuando se cierra el caso (y nunca culpa por error al comisario); al asesino borracho o con fiebre hay que oírle tú antes de poder delatarle; el chivo expiatorio y el testigo asustado te piden ayuda en persona; solo se puede pedir la autopsia de un cuerpo ya encontrado.
- **Tumbas profanadas:** limpiando la lápida puedes (o no) encontrar algo del culpable; solo si se sabe quién fue, el cura lo aparta de la capilla.
- **Encargo de sicario:** primero escuchas la propuesta; si aceptas, el rico paga solo cuando el trabajo está hecho y solo lo que tiene.
- **Se acabó el oro infinito del hampa:** el perista solo compra objetos de valor que lleves encima y paga de su bolsillo; el robo por encargo hay que hacerlo yendo al sitio y alguien puede verte; la pelea clandestina se puede perder (y duele); la apuesta es a cara o cruz; el polvo de ocaso solo lo compra quien tiene con qué pagar; la «protección» se cobra una vez por semana y sale de la caja de la tienda; el ratero a sueldo te da solo parte de lo que robó; el moroso del usurero solo paga lo que tiene.
- **Tu casa:** el cofre de tu casa ya no regala oro cada día, y el local que posees solo te da parte de lo que hay en su caja.

### Siete bloques nuevos: clanes, crímenes, secretos de familia, capilla, alcaldía, casas propias y bajos fondos
*(Entrada corregida el 2026-11-04 tras la auditoría: la versión anterior anunciaba unas 25 cosas que no existían. Esas ideas están ahora en la lista de ideas pendientes.)*
- **Clanes y rencores:** al morir un vecino, su familia hereda sus enemistades; hay feudos entre familias, boicot en sus tiendas (a familias rivales y a ti si los ofendes), amor prohibido entre clanes que puedes ayudar, huérfanos acogidos por parientes, la oveja negra desheredada, cenas de paz, deudas de honor si les ayudas, testamentos disputados y tumbas profanadas por rencor.
- **Crímenes e investigación:** los asesinos pueden plantar pistas falsas, conseguir coartadas de parientes, intimidar testigos, actuar por encargo de un rico, usar veneno lento que parece muerte natural, mover el cadáver, irse de la lengua borrachos o con fiebre, o el comisario corrupto puede culpar a un inocente. Tú puedes investigarlo todo, incriminar a alguien y tender emboscadas con la guardia.
- **Hijos secretos y linaje:** las aventuras pueden dejar embarazos; el hijo hereda rasgos del padre real y eso despierta rumores. Puedes chantajear, revelar la verdad o ver al padre pagar manutención; hay bebés dejados en la capilla, adopciones, peleas de hermanos por el taller familiar, cazafortunas y vecinos con un pasado fuera del valle.
- **Confesionario:** los vecinos se confiesan entre semana y puedes espiarlos; el cura puede venderte secretos o tener una crisis de fe; hay penitencias, bulas para ricos, sermones con indirectas, excomunión, confesarte tú y acogerte a sagrado.
- **Alcaldía:** puedes presentarte, hacer promesas, dar mítines, pedir votos y difamar rivales; si ganas (o chantajeas al alcalde para tenerlo de títere) fijas impuestos bajos, normales o altos, firmas ley seca, toque de queda o subvención al mercado, encargas obras, nombras comisario, desvías dinero de las arcas o maquillas las cuentas. También puedes impulsar una moción para echar al alcalde.
- **Casa propia:** compras solar al contado o con hipoteca, duermes en tu cama, añades estantería, banco de trabajo o cerradura, huerto, escondite bajo el suelo, cenas para vecinos; puedes invitar a alguien a vivir contigo, comprar casas para alquilarlas, subir o perdonar la renta, desahuciar, comprar casas embargadas y locales comerciales.
- **Bajos fondos:** de noche hay un perista que compra lo robado y vende ganzúas, veneno lento, somnífero y papeles falsos; hay robos por encargo, «polvo de ocaso» que puedes destilar y vender, usura, «protección» a tiendas, ladrones y saboteadores a sueldo, pelea clandestina con apuestas, soborno de la ronda nocturna, delatar al perista o convertirte en jefe del hampa.

## 2026-11-03

### Revisión y arreglos de los 25 encargos
- **Guardado completo:** al guardar y cargar la partida ya no se olvidan los desahucios recientes, las herencias de talleres, quién leyó en la biblioteca, quién acaba de llegar al pueblo ni a quién invitaste al Oficio del domingo.
- **Atajo «📜 Encargo» corregido:** al hacer un encargo de ensuciar el nombre de alguien, el rival sale ahora primero y con atajo directo al hablar con cualquier vecino; además, el atajo ya no aparece por error en misiones que van por libre.
- **Cinco encargos pulidos:** nadie te pide investigar una infidelidad si ningún vecino ha visto nada todavía; dar dinero para la posada a un vecino sin techo le devuelve cama al momento; descubrir rasgos de un forastero por tu cuenta también vale para su encargo; y hablar con un deudor recién desahuciado ya no da error.
- **Panel de avisos limpio:** eliminados los 19 avisos amarillos que salían al abrir el juego en el editor.
- **Cuadro de conversación ajustado a la pantalla:** cuando un vecino tiene muchas opciones, aparece una barra a la derecha para bajar con la rueda del ratón o con W/S, y la ventana ya nunca se corta por arriba ni por los lados.
- **Esquina del minimapa limpia:** retirado el viejo letrero de prueba en inglés («Eliminate Frogs») que asomaba cortado encima del minimapa.
- **Barras de estado finas y dinámicas:** las barras de arriba a la izquierda ahora son más pequeñas, muestran solo su icono sin palabras encima, y las de hambre, sueño e higiene se esconden mientras estás bien (75 % o más) para no tapar la pantalla.

### Otras diez misiones (ya hay 25)
- Nuevos encargos (provisionales): donativos para las gachas, una carta de amor, una herencia disputada, apartar a alguien de la bebida o el juego, montar puesto en el mercado, las reuniones nocturnas (la secta), calmar una pelea anunciada, buscar techo a un desahuciado, un forastero del que nadie se fía y un asesinato archivado.
- El tabernero puede negarse a servir unos días a quien bebe demasiado, si se lo pides.

### Diez misiones nuevas y canteros trabajando
- 10 encargos nuevos (provisionales): descubrir una infidelidad, salvar una casa del desahucio, cazar un jabalí, comprar votos, destapar al alcalde, pagar medicinas a un pobre, devolver a alguien al Oficio, colocar a un aprendiz, sabotear a un rival y proteger a un testigo. Casi todos tienen más de una salida, y no siempre la honrada es la que paga.
- El cantero trabaja ahora en la roca, a la vista, y cada casa nueva le compra piedra a él y troncos al leñador.
- Si te piden mejorar la relación con alguien, al hablar con esa persona sale la opción del encargo arriba del todo.

### Cazadores prudentes, muertes claras y gachas
- El carnicero ya no muere siempre cazando: prefiere ciervos y conejos, se retira si un jabalí le deja malherido y el jabalí no remata a quien está en el suelo.
- Morir de hambre, por un animal o de una enfermedad ya no se investiga como asesinato: la crónica dice qué pasó («lo mató un jabalí», «murió de hambre»).
- Una partida nueva empieza con 1000 de oro en las arcas.
- El Albergue del Alba prepara cada mañana gachas para los pobres: 1 de oro, o gratis si no tienes nada. En la partida de prueba nadie se quedó sin comer.

### Casas a plazos y mapa más claro
- Las casas cuestan 100 de oro y se pueden comprar a plazos: con 15 de entrada, el pueblo o un noble presta el resto con un 25 % de interés. Quien deja de pagar 5 días seguidos pierde la casa. La deuda se ve en la ficha y en la crónica.
- El mapa grande (M) ocupa casi toda la pantalla y los nombres de los edificios ya no se pisan; al pasar el cursor sale el nombre completo.

### Ayudantes que cobran
- Quien ayuda en el negocio de su familia recibe ahora una parte del dueño cada día; antes no cobraba nada y acababa sin poder comer. En total, las comidas que fallan en el pueblo bajan a menos de un tercio.

### Granjeros que ya comen
- **Arreglado:** los dueños de la granja, el rancho y la cantera contrataban jornaleros con todo su dinero, aunque el almacén estuviera lleno, y luego no podían comprar comida. Ahora contratan solo a los que hacen falta y se guardan para comer.

### Casas, camas y rumores
- Una pareja sin casa puede juntar sus ahorros para encargarla; si alguien duerme al raso, el pueblo paga la casa antes.
- Ya no pueden tocarle a dos vecinos la misma cama de la posada.
- Si preguntas a alguien de confianza por un amigo suyo, puede contarte lo que ese amigo siente por otra persona. En la red social sale «🗣️ Según…» hasta que lo confirmes tú.

### Pulido del pueblo que crece
- Llegan **familias con hijos**; los niños reciben una paga de sus padres para comer y salen a jugar al acabar la escuela; el cartel de la escuela dice si está abierta, quién enseña y cuántos alumnos hay; un hijo que se hace mayor puede quedarse a ayudar en el negocio de casa.
- **Arreglado:** al cargar una partida se perdían los nobles y los niños. **Arreglado:** el pueblo parecía tener hambre para siempre tras la primera comida que alguien no pudo pagar.
- Dos solares más para casas: ya caben 50 vecinos. Con 50, el juego va fluido (unos 6 ms por fotograma).

### Diálogos más limpios
- **UI1**: al hablar con alguien, arriba solo sale su nombre, lo que hace y su humor, y unas pocas opciones: lo importante del momento, «Charlar…», «Invitar o regalar…», «Lo turbio…», «Ver ficha» (con todos sus datos y su red social) y Salir. «Manipular testigo» solo aparece si hay un caso abierto.

### Crecer el pueblo: nobles, hijos y más casas
- **V6**: en la loma del este vive el **señor del valle** en su mansión, con su pareja y su heredero; en la loma del norte, una familia de **rentistas** en una casa grande. Los lunes el señor cobra la renta a quien lleva la granja y el rancho, y quien vive de sus tierras tiende a votar a quien el señor prefiere.
- **V9**: las parejas con casa pueden **tener hijos**. Los niños nacen en casa, se parecen algo a sus padres, crecen, juegan y, cuando hay bastantes, llega un **maestro** y van a la escuela. A los 16 son mayores y buscan su sitio.
- **Más solares** para casas en una segunda fila al norte.
- **V7**: una sonda que mide cómo crece el pueblo y cuánto cuesta el juego con 50 vecinos.

### Crecer el pueblo: llegadas y marchas
- **V3**: ya no llegan siempre tres viajeros. El pueblo tiene un **atractivo** que sube con el trabajo libre y las camas libres, y baja con los mendigos, las muertes, las peleas y el hambre. Si va bien, llega gente a quedarse (jornaleros, artesanos con ahorros o una pareja), siempre que haya donde dormir, hasta 50 vecinos. Si va mal, se marchan los que no tienen casa ni amigos, sobre todo si duermen en la calle. Cuando faltan casas, el carpintero construye una: la paga quien llegó con ahorros o, si no, las arcas del pueblo. Hay dos solares nuevos para casas.

### Crecer el pueblo: biblioteca, escuela, mercado y taller
- **V5e**: en la calle norte hay una **biblioteca**: algunos vecinos van a leer en su tiempo libre (sobre todo los curiosos), y cuando llueve es casi el único sitio al que la gente sale. Tú puedes leer un rato una vez al día y aprender algo de un oficio. Al este está la **escuela**, vacía hasta que haya niños. Los **miércoles por la mañana** hay **mercado** en la plaza: las tiendas con género de sobra montan un puesto y los vecinos se acercan a comprar y charlar. Y hay un **Taller de Reparaciones**: si te sabotean un negocio, el arreglador lo deja como nuevo antes, cobrando. Nombres provisionales.

### Crecer el pueblo: las afueras
- **V5d**: al sur están la **Granja del Sur** con sus campos y el **Rancho** con su corral, al noroeste la **Cantera** y en la linde del bosque la **Cabaña del Leñador** (nombres provisionales). Empiezan sin dueño. Venden trigo, zanahorias, lana, carne, piedra y madera, y los oficios de siempre les compran. Cada mañana sus dueños **contratan jornaleros** entre la gente sin oficio, primero a los más necesitados: van andando a trabajar y cobran por las horas que de verdad trabajan; si el dueño no puede pagar, se enfadan. Junto al lago hay un **lavadero** donde algunos van a lavarse y, de paso, a contarse chismes.

### Crecer el pueblo: sitios para pasar el rato
- **V5c**: hay un **parque** (el Parque del Roble, junto a la Botica), **bancos en la plaza** y un **mirador** junto al lago. Al salir del trabajo y los fines de semana, algunos vecinos van a pasar el rato: más los sociables o los que se sienten solos, casi nadie si llueve. Quien coincide charla, se cuenta chismes y se va llevando mejor (o se roza, si ya se llevaban mal). Las quedadas también usan estos sitios; el mirador gusta a las parejas.

### Crecer el pueblo: ayuntamiento, albergue y El Candil
- **V5b**: en la calle norte está el **Ayuntamiento**. El día de elecciones los vecinos **van en persona a votar** cuando están libres (sobre todo al salir del trabajo); quien no va no vota. El sábado por la tarde el alcalde pasa a cuadrar las cuentas. Las **arcas del pueblo** están en un cofre que se puede forzar: el oro sale de las arcas de verdad, y al día siguiente todo el pueblo sabe que falta dinero y el alcalde queda mal. Junto al camino del este están el **Albergue del Alba**, donde quien se queda sin dinero duerme bajo techo (si hay sitio) en vez de a la intemperie, y **El Candil**, una posada humilde a 3 de oro la noche para quien no puede pagar El Jabalí Dorado. Nombres provisionales.

### Crecer el pueblo: panadería y sastrería
- **V5a**: en la calle norte hay una **panadería** («La Espiga») y una **sastrería** («El Dedal»), nombres provisionales. Empiezan sin dueño y se quedan con ellas un vecino con ganas de prosperar o alguien que llega al valle. El panadero madruga y hornea con harina del molino y leña; los vecinos compran allí el pan. El sastre cose ropa con cuero; quien tiene dinero de sobra estrena ropa de vez en cuando (los ricos más) y se pone de buen humor. Puedes comprar pan y ropa y venderles trigo, leña, cuero o pieles. El mapa del valle ahora llega a los solares nuevos.

### Crecer el pueblo: solares
- **V4**: alrededor del pueblo hay ahora **16 solares** con su cartel: una calle nueva al norte, el camino del este alargado, campos al sur, una ladera al noroeste y dos lomas apartadas para mansiones. Se puede encargar una **casa**: alguien la paga y el **carpintero va en persona a construirla**; solo avanza mientras trabaja allí, así que si enferma o falta, la obra se para. Al terminar es una casa de verdad, con puerta, cama y cofre, y se guarda con la partida. Todavía nadie las encarga: eso llega con las llegadas de gente (V3).

### Crecer el pueblo: rendimiento
- **V2**: los vecinos que están **fuera de la pantalla** se mueven y piensan con menos frecuencia (lo social sigue igual). Con 50 vecinos ahorra un tercio cuando estás lejos. Queda pendiente un coste alto cuando estás en medio de la multitud de la plaza; se volverá a medir con el mapa ampliado.
- **V8**: el **panel de misiones** (L) sale centrado. Si un negocio se queda sin dueño, un **vecino ambicioso** del pueblo puede quedárselo antes de que llegue un forastero. Descubrir una **infidelidad** puede, muy raramente, acabar en un plan de asesinato por celos, con señales antes.
- **V1**: medido cuánto aguanta el juego con más vecinos. A medianoche había un **tirón** que crecía mucho con la gente: medio segundo con 18 vecinos y casi 4 segundos con 70. Arreglado: ahora es una décima con 50. Se nota también algo menos de trabajo en cada fotograma.

### La secta: surge sola
- **O8**: la secta ya **no nace en una fecha fija** ni renace a los 30 días. Nace solo si el pueblo **lo pasa mal** (pobreza, enfermedad, duelo, robos, muertes, escándalos) o hay **ricos aburridos**, y además hay alguien con **poder de convencimiento** y un motivo. Si no, no nace nunca. Hay dos clases: «los Hijos del Ocaso» (desesperados, de madrugada en el cementerio) y «el Círculo de la Luna Velada» (ricos, en casa del líder). Crece despacio, hasta unos 13, y se apaga poco a poco cuando la crisis pasa. El fundador destapado ya no convence a nadie. **Aldric ahora es Manipulador**: es el candidato natural a fundar una secta si el pueblo cae en crisis.

### La secta secreta
- **O1–O7**: en los primeros días, un vecino de perfil inquietante funda en secreto **«los Hijos del Ocaso»** (nombre provisional) y capta a gente vulnerable: pobres, adictos, solitarios, resentidos. Quien se niega puede ir contándolo. Se reúnen **los viernes de madrugada en el cementerio** (si alguien de su casa les oye salir, corre el rumor), pagan un diezmo, se encubren y se votan entre ellos, y a veces pintan un **sol negro** en la capilla. Muy raramente preparan un **rito de sangre**, con señales antes. Si la sospecha crece, el sacerdote los señala; tú puedes descubrirlos, chantajearlos, denunciarlos, avisar a la víctima o **unirte** (con rangos). Nuevo documento `docs/APORTES_CREATIVOS.md`: todo el lore, nombres y misiones provisionales del proyecto, por temas, para revisarlos.

### Instituciones y corrupción
- **I1–I6**: el pueblo elige **alcalde** al empezar y cada 28 días (votan los vecinos según a quién aprecian y su bando; tú puedes pedirles el voto). Cada **sábado se cobran impuestos** y el alcalde reparte una ayuda a los pobres. Un alcalde **corrupto** se queda parte; si se destapa (porque lo sabe medio pueblo o porque lo denuncias al comisario) devuelve lo robado y hay elecciones anticipadas. Un **comisario corrupto** deja escapar a ladrones por dinero, y **tú puedes sobornarle** para que olvide tus cargos (si es honrado, la multa sube). Los nobles quedan para más adelante.

### Economía y necesidades
- **E1–E7**: vecinos y tú tenéis **higiene** (nueva barra 🧼): se lavan en los pozos o en casa; si van sucios están de peor humor, caen peor y enferman más; si tú hueles mal, te lo notan. Hay **enfermedades que se contagian**: un resfriado y la fiebre gris, que obliga a guardar cama y, si nadie la trata, muy rara vez mata; el médico cura (a ti por 8 de oro). Cada vecino es **rico, acomodado, humilde, pobre o mendigo**; los mendigos piden limosna en la plaza. Hay **ladrones** de noche (a vecinos, a los puestos o a ti): si alguien los ve, el comisario les hace devolverlo; tú puedes denunciarlos o callar. Algunos se enganchan a la **bebida o al juego**, gastan su oro en la taberna y, borrachos, se les escapan secretos. Tú puedes dar limosna, regalar oro o invitar a una ronda para que te cuenten cosas.

### Grupos y fe
- **G1–G7**: el pueblo tiene una fe propia, la **Fe del Alba** (provisional), y la capilla se llama ahora **Capilla del Alba**. Llega un personaje nuevo, el **Hermano Anselmo**, el sacerdote. La semana tiene 7 días y el reloj dice cuál es: el **sábado** se trabaja solo por la mañana y el **domingo** se descansa; el fin de semana los vecinos salen más. El domingo por la mañana los creyentes **caminan a la capilla** para el Oficio: salen de allí llevándose mejor y con chismes nuevos, los más devotos se fijan en quién faltó y, si el sacerdote le tiene manía a alguien, lo nota todo el que fue. Si tú vas, los creyentes te aprecian más. Los vecinos forman **bandos** (familias, pandillas de amigos, seguidores de un líder) que defienden a los suyos. Tienes **fama con los creyentes, los escépticos y cada bando** (se ve en el glosario, tecla J), y puedes preguntar al sacerdote por la fe, donar o burlarte.

### Deseos propios
- **D1–D6**: algunos vecinos quieren algo y dan pasos para lograrlo. **Venganza** contra quien odian (hablar mal, contar sus secretos, estropearle el negocio, buscar pelea). **Ambición** (ahorrar, envidiar y perjudicar al que más tiene). **Contra ti**, si te odian: van diciendo que no eres de fiar, no te venden, te denuncian o cuentan tus chantajes. Y, muy raramente, **planes de asesinato**: hay señales unos días antes; si te enteras puedes avisar a la víctima o al comisario, y si ocurre, el comisario tendrá pistas del asesino. Los deseos se descubren preguntando «¿qué te ronda la cabeza?» (si te aprecian), por chismes, o porque algunos lo dicen abiertamente.

## 2026-11-02

### Chismes
- **R5**: en el pueblo se habla más. Ahora también se comentan citas, coqueteos, noviazgos, celos, llegadas y marchas, y en cada charla pueden contar novedades los dos vecinos.

### Secretos
- **S1–S6**: infidelidades raras (las personas fieles nunca; las infieles bastante más) que pueden descubrirse si alguien los ve juntos. Entonces corre el chisme, deformado a veces: puede acabar señalando a un inocente. Si llega a la pareja, lo normal es que rompan. Un vecino malicioso puede chantajear al infiel. Tú también: si sabes el secreto puedes pedirle oro, prometerle callar o contárselo a su pareja.

### Recuerdos que se degradan
- **R1–R4**: los vecinos olvidan los chismes con el tiempo (los memoriosos tardan más, los olvidadizos menos; los protagonistas casi nunca) y al contarlos pueden deformarlos: exageran o se equivocan de persona, y el error se contagia. Lo que te cuentan es su versión, y la crónica la apunta («❓ … te contó»). Un testigo que olvidó algo ya no se lo dirá al investigador.

### Interfaz
- **HUD1**: barras de estado más bonitas y legibles, en un recuadro arriba a la izquierda. Se ven resistencia, aguante, hambre y sueño; ya no salen las de sangre ni aturdimiento.

### Crónica del pueblo
- **C5**: la crónica ya cuenta la vida diaria: quedadas, chismes («Ana le contó a Luis…») y cuándo alguien se hace amigo, se distancia o empieza a caerle mal otro vecino. Guarda los 500 últimos sucesos y las pestañas caben todas.
- Arreglo: la crónica parecía vacía porque abría en la última pestaña usada y no se actualizaba estando abierta. Ahora abre en «Todo» y lo nuevo aparece solo.
- Pulido: los cambios de amistad y romance dicen «Durante el día» en vez de «00:00», el panel sale centrado y las peleas dicen «peor parada» o «magullada» cuando es una mujer.
- **C1–C4**: nueva crónica con la tecla **O** (la C ya era agacharse): un libro con los 160 últimos sucesos del pueblo, por días y con pestañas (Amor, Peleas, Muertes, Llegadas, Tú). Apunta también muertes descubiertas, casos cerrados y misiones. En el juego final solo verás lo que sabes; ahora, en pruebas, se ve todo y lo secreto lleva 🔒.

### Relaciones de un solo sentido
- **U7**: medido en partidas largas. Ajustes: cada vecino tiene más o menos «química» con cada otro, el carácter sociable pesa más y el enfriamiento por distancia ya no borra las diferencias. Sin jugador, en 25 días aún son pocas las relaciones muy desiguales: aparecerán sobre todo con lo que tú hagas y con el paso del tiempo. Bloque de relaciones terminado.
- **U6**: si dos vecinos dejan de verse una semana, lo que sienten (bueno o malo) se va apagando poco a poco. Parejas y familia no.
- **U5**: lo que siente cada vecino por los demás empieza oculto: lo descubres preguntándole qué opina de los vecinos. En el glosario verás lo que siente cada uno por separado («↩»), así se notan los cariños no correspondidos. Las partidas guardadas antes de este cambio lo siguen viendo todo.
- **U4**: amistad desigual: si invitas a alguien que apenas te aprecia, te pondrá una excusa. Y los vecinos hablan de lo que sienten ellos («es mi mejor amiga», «no lo soporto»).
- **U3**: amores no correspondidos. Quien está muy ilusionado con alguien que no siente lo mismo puede declararse y llevarse un «no» (se entera el pueblo). Si la persona que te gusta se empareja con otro, le coges celos a su nueva pareja. Y la misión «Averigua qué piensa de mí» ahora dice la verdad del otro: si le gustas, si solo te ve como amigo o si le eres indiferente.
- **U2**: ahora cada vecino vive a su manera lo que pasa. Una misma charla le sabe mejor al sociable; hay manías de un solo lado (al Honrado le irrita el Chismoso, al Serio el Bromista...); el Romántico se ilusiona antes que el Desapegado; un favor pesa más para quien lo recibe; y lo que cuentas de alguien solo cambia la opinión de quien te escucha. Con el tiempo se tiende un poco a corresponder, sin igualarse: pueden surgir amores no correspondidos.
- **U1**: preparada la base para que lo que siente un vecino por otro pueda ser distinto de lo que siente el otro (aprecio y chispa de cada uno). Todavía no cambia nada en el juego; las partidas guardadas se adaptan solas.

### Planificación
- Nuevo documento `docs/VISION_Y_FUTURO.md` con la visión del juego, el orden acordado para construirlo y toda la lluvia de ideas (secta, corrupción, higiene, niños, vehículos, alcantarillas...). Es el objetivo a largo plazo; nada se construye sin plan aprobado.

### Correcciones y pruebas
- Limpiados los 14 avisos amarillos que mostraba Godot. No eran fallos y el juego no cambia.
- Los rumores que corren de boca en boca ya no dicen quién los empezó (antes se colaba el nombre del autor, lo que estropeaba la misión de averiguarlo).
- Si un guardia tiene que escoltarte mientras está peleando con un vecino, ahora deja la pelea al momento (antes tardaba unos segundos).
- Nueva prueba de guardar y cargar con misiones, ofertas y rasgos descubiertos; todo se conserva bien.

### Rasgos de personalidad
- **T5**: medido en una partida larga con los 6 rasgos: todo en cifras parecidas a antes salvo las calumnias entre vecinos, que se habían multiplicado (7 en 25 días). Bajadas a la mitad.
- **T2b**: lo que te cuentan otros vecinos sobre el carácter de alguien sale como «Se dice: Violento (según Marta)» hasta que lo compruebes. Un vecino mentiroso o malicioso que se lleva mal con otro puede inventárselo; si luego descubres un rasgo que lo contradice, o le conoces del todo, el bulo desaparece.
- **T2**: ya están los 140 rasgos en el juego. Cada vecino tiene 6, nunca dos opuestos, casi siempre con uno o dos difíciles y a veces uno raro. Los vecinos de siempre conservan sus 3 rasgos y ganan otros 3 (siempre los mismos); las partidas guardadas se completan igual. Los rasgos se muestran en femenino cuando toca (Celosa, Trabajadora). Además, las investigaciones ya tienen en cuenta el carácter real del sospechoso (antes miraban otra lista).
- **T2 (preparación)**: listo el reparto de rasgos para cuando apruebes la lista: nunca junta opuestos, admite como mucho un rasgo raro y respeta los que ya tiene cada vecino. Aún no cambia nada en el juego.
- **T4 (2)**: los vecinos sociables charlan más a menudo y proponen más quedadas, y los fríos menos; los trabajadores rinden hasta un 15 % más en su oficio.
- **T4**: el carácter influye en más cosas: los agresivos pegan más fuerte y acumulan tensión antes; los desconfiados se creen menos lo que les cuentas; los honrados cuesta más que te cubran y pueden rechazar sobornos; los chismosos cuentan más novedades; los investigadores sospechan de los caracteres oscuros; y los generosos pagan mejor las misiones.
- **T3**: los rasgos de los vecinos empiezan ocultos (❓ en el glosario, el mapa y la taberna) y se descubren al ganar su confianza, al conocer su historia, con Carisma alto, espiándoles, viéndoles calumniar o pelear, o porque otro vecino de confianza te lo cuenta.
- **T1**: nuevo catálogo de rasgos. Cada rasgo sube o baja tendencias como la malicia o el rencor. Ahora las calumnias dependen de la malicia: un vecino rencoroso y celoso calumnia bastante, uno con un solo rasgo malo a veces, y uno bondadoso y leal nunca.

### Misiones
- **Q4**: se midió la frecuencia en partidas largas: unas 7 ofertas de misión cada 25 días y nunca más de 3 a la vez. Dos ajustes: un vecino al que no hiciste caso ya no te vuelve a pedir lo mismo al día siguiente, y los vecinos rencorosos o chismosos ahora sí calumnian alguna vez (antes no lo hacían nunca). Las misiones quedan organizadas para poder añadir muchos tipos más; la guía está en `docs/MISIONES.md`.
- **Q3 (parte 2)**: los vecinos rencorosos o chismosos a veces hablan mal de su rival a sus espaldas. Si el rumor le llega al afectado de segunda mano, no sabe quién lo empezó y puede pedirte que lo averigües: preguntas «¿quién te lo contó?» hasta llegar al origen y luego señalas a alguien (sea verdad o no) o confiesas si fuiste tú. Con esto ya están los 5 tipos de misión.
- **Q3 (parte 1)**: dos misiones nuevas. «Encuentra a quien lo mató»: tras un asesinato, alguien muy cercano a la víctima puede pedirte justicia; se resuelve con el veredicto (falla si te culpan a ti o se archiva el caso). «Averigua qué piensa de mí»: alguien que siente atracción te pide sonsacar a otro vecino; al volver puedes decirle la verdad o mentir. Una mala respuesta le quita la ilusión, pero nunca se fuerza una pareja.
- **Q2**: los vecinos con una enemistad larga pueden pedirte ayuda en persona (❗ sobre la cabeza). Según su carácter te piden hacer las paces con su rival o ensuciarle el nombre por el pueblo. Se acepta, se abandona y se cobra hablando con ellos; falla si muere alguno de los dos. Son poco frecuentes: como mucho 3 a la vez.
- **Q1**: nuevo panel de misiones con la tecla **L**, con pestañas «Secundarias» y «Principal» (esta última, para la futura historia). Las misiones se guardan con la partida. Todavía no hay ninguna: los vecinos empezarán a pedirlas en el siguiente bloque.

### Vida social e investigaciones
- **M1**: los investigadores tienen en cuenta el móvil. Quien se peleó o lleva tiempo enemistado con la víctima empieza con algo más de sospecha, los testigos cuentan las peleas, rupturas y calumnias que conocen, y si el jugador habló mal de la víctima y lo sabe medio pueblo, también tiene móvil. El móvil suma, pero nunca decide un culpable por sí solo.

### Refuerzo del código
- **R5**: el bucle principal de los vecinos pasa de 211 a 25 líneas, dividido en 8 pasos con nombre; el juego no cambia. Refuerzo cerrado.
- **R4**: investigaciones, interrogatorios y juicio pasan a `VillageJustice.gd`; el juego no cambia.
- **R3**: quedadas, peleas y chismes pasan a `VillageSocialLife.gd`; el juego no cambia.
- **R2**: la construcción del pueblo pasa a `VillageWorldBuilder.gd`; el mundo sigue idéntico.
- **R1**: nuevo test del ciclo completo de guardar y cargar una partida; no encontró errores y el juego no cambia.

### Documentación
- Puesta al día del traspaso: nuevo `CLAUDE.md`, este registro y `docs/HANDOFF.md` actualizado.

### Vida social — Fase 6 (cerrada)
- **B6.4** (`87f4c74`): las quedadas ya no se cancelan casi siempre al irse a dormir: duran menos y no se planifican después de las 20:15. Revisión del código: 9 correcciones; la más importante evita que los chismes revelen muertes aún sin descubrir. El efecto en quedadas y parejas no se llegó a medir.
- **B6.3** (`7146515`): dos partidas de 60 días medidas: 4 peleas y 3 parejas nuevas en cada una, sin muertes ni vecinos aislados.

## 2026-11-01

### Vida social — Fases 4 a 6
- **B6.1 y B6.2** (`7b1bf12`): los vecinos se cuentan novedades, puedes preguntarles por ellas y lo muy sabido aparece en el tablón de la plaza.
- **B5.4** (`dea66aa`): casamentero: animar a dos solteros compatibles a acercarse.
- **B5.3** (`5545530`): mediar entre enemigos y separar peleas en marcha.
- **B5.2** (`b32e6b5`): hablar bien o mal de un vecino con Carisma, una vez al día.
- **B5.1** (`c3781c4`): preguntar qué opina un vecino de otros y escuchar a escondidas.
- **B4.2** (`b85d166`, `36972fe`): peleas visibles, breves y raras, solo tras una enemistad larga, con moratón leve, testigos y guardia.
- **B4.1** (`74d1f87`, `5e50d81`, `ab76242`): resolución interna de peleas con dados; corregido el uso de la salud y la tirada diaria.

### Vida social — Fases 0 a 3
- **B3.1 a B3.5**: cortejos, citas, celos, rupturas, reconciliaciones, duelo y visitas al cementerio.
- **B2.1 y B2.2**: quedadas en la plaza y la taberna; los rivales se evitan.
- **B1.1 a B1.3**: conversaciones reales de 2 turnos entre vecinos.
- **B0.1 a B0.9**: nombres únicos, fichas de persona, generador de vecinos nuevos, relaciones por identificador, guardado, registro de eventos, Director Social, pareja inicial y simulador de 60 días.

### Otros cambios
- Velocidad de tiempo persistente 1x/2x/4x/8x.
- Sprites de vecinos, suelos, muros y empedrado renovados.
