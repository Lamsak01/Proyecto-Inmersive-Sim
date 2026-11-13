# Editor del mapa — guía para el usuario (puesta al día el 2026-11-12, mapa ×5)

Hay **dos editores**, los dos dentro de Godot:
- **Mundo3D** (carpeta `mapa` → doble clic en **Mundo3D**): todo el pueblo en 3D. Aquí mueves edificios, objetos,
  caminos, árboles, rocas y decorado. Es el que vas a usar casi siempre.
- **EditorMapa** (carpeta `mapa` → doble clic en **EditorMapa**): el río y sus puentes, visto desde arriba en 2D.

Guarda siempre con **Ctrl+S** y prueba con **F5** (o el ▶ de arriba a la derecha): el juego usa lo que hay guardado.
**Ctrl+Z** deshace. Si algo se rompe de verdad, pide a Claude que lo vuelva atrás: todo está en GitHub.

## 1. Moverse por Mundo3D
- Al abrirlo pulsa **3D** (arriba, junto a 2D). Verás una maqueta del valle: suelo con relieve, río, lago, caminos y, encima,
  las piezas de verdad (edificios con su «foto», árboles, rocas, objetos).
- **Volar:** mantén el **botón derecho** y mueve el ratón para mirar; con el botón derecho pulsado, **W A S D** para avanzar,
  **Q/E** para bajar y subir, y **Mayúsculas** para ir rápido. La rueda del ratón acerca y aleja.
- **Elegir una pieza:** clic izquierdo encima. Lo elegido se marca naranja en la lista de la izquierda («Escena»).
  Si no aciertas, búscalo en esa lista: las carpetas son **Edificios**, **Objetos**, **Caminos**, **Vegetacion**,
  **Decorado**, **BajoTierra** (oculta) y **Decoracion** (tus modelos).
- **Ir hasta lo elegido:** con la pieza elegida, pulsa **F** con el ratón sobre la vista 3D.

## 2. Mover, girar, agrandar
- **Mover:** tecla **W** y arrastra las flechas (roja = este-oeste, azul = norte-sur). No muevas la verde (altura): el juego
  pone cada cosa a ras del suelo.
- **Girar:** tecla **E** y arrastra el aro verde (el del eje vertical). O escribe el ángulo en el Inspector (derecha):
  Transform → Rotation → **Y**.
- **Agrandar:** tecla **R**. Solo tiene sentido en los **caminos** (ver más abajo). Edificios y objetos no se agrandan aquí.
- **Copiar:** elige la pieza y pulsa **Ctrl+D**; la copia aparece encima, muévela. **Borrar:** **Supr**.
- **Varias a la vez:** clic con **Mayúsculas** para ir sumando piezas; luego W y arrastra.

## 3. Qué hay en cada carpeta
- **Edificios (29):** cada casa, tienda y edificio público, con su interior dentro (carpeta **Muebles**). Al mover un
  edificio se mueve todo lo suyo: muros, puerta, muebles, cama y mesa de la familia, puesto de trabajo, zonas de uso.
  **Girar: de 90 en 90 grados** (si pones 37°, el juego lo redondea a 0 o 90). Los muebles de dentro se pueden mover
  uno a uno, y su pared invisible va con ellos (campo **Choque** del mueble: lo que ocupa visto desde arriba; en 0, 0
  se atraviesa, como una silla). **No cambies «Id edificio»** ni «Centro original». No copies un edificio con Ctrl+D: saldría un clon con el
  mismo nombre interno y el juego no sabe cuál es cuál (una casa nueva la añade Claude).
  **Puerta, ventana y tamaño (2026-11-11):** dentro de cada edificio (doble clic en su escena) las cruces `puerta` y
  `ventana` de **Marcas** dicen por dónde se entra y dónde se abre la ventana en el juego; el lado de la puerta es el
  muro al que la cruz esté más pegada, y la ventana va en ese mismo muro. En el Inspector de la pieza, «Planta m» es el
  ancho × fondo que se pisa y choca, y «Puerta ancho m» el hueco. Ojo: esto mueve lo que se pisa, no el dibujo de las
  paredes; si cambias puerta o tamaño, pide a Claude que rehaga el dibujo.
  **Paredes de dentro:** en la escena del edificio, carpeta **Tabiques**: cada caja roja translúcida es una pared que
  no se puede atravesar. Muévela, cambia su tamaño en «Tam m» (ancho × fondo), cópiala con Ctrl+D o bórrala. «Tapa
  vista» desmarcado = se ve a través (rejas). Igual que la puerta: mueve lo que choca, no el dibujo de la pared.
  **Cartel con el nombre (2026-11-12):** en la escena de cada edificio, la pieza **Cartel** es la tabla de madera
  junto a la puerta. Muévela o gírala con el ratón; en el Inspector, «Ancho m» la hace más ancha o estrecha. El nombre
  lo escribe el juego (en las casas de solar, el de la familia); en el editor sale el nombre del edificio.
  **Casas de recién llegados:** todas son copias de tres **casas modelo** (`mapa/edificios/modelo_casita`, `modelo_casa`
  y `modelo_casona`). Abre una con doble clic, mueve muebles o las cruces de **Marcas** (`cama_1`, `mesa`, `cofre`…) y
  guarda: cambia en todas las casas de ese tamaño, también las que se construyan jugando. Si añades una cruz `cama_3`,
  la casa gana una plaza. Las casas con la puerta al norte son la misma casa con media vuelta.
- **Solares (41):** las parcelas del pueblo (losas amarillas translúcidas con su nombre). Mueve un solar y la obra, la
  casa que se construya en él, su letrero y sus campos saldrán ahí; girarlo gira la casa de 90 en 90 grados. Las casas
  de recién llegados ya no son piezas sueltas: salen en su solar. Si el solar tiene un edificio propio en «Edificios»
  (tiendas, ayuntamiento, escuela…), muévelos **juntos** (clic en uno, Mayúsculas+clic en el otro). **No cambies «Id solar»**.
  El **Puesto del Paso** (frontera este) es un solar más: muévelo y van con él su camino, estacas, sacos, foco y letrero.
  En el Inspector de cada solar puedes cambiar su **zona** (borde, barrio, afueras, apartado), el **barrio**, el tamaño de
  la **casa** (small = casita, medium = casa, large = casona), si la **puerta mira al sur** y cuánto se **aparta el
  edificio** para dejar sitio a campos. Todavía **no** se añaden solares duplicando uno (llegará en el paso final).
  El Puesto del Paso lleva dentro sus **Marcas** (centro, puerta y los tres sitios de trabajo de los colonos): muévelas
  dentro del solar y el puesto las seguirá. **No cambies «Id marca».**
- **Sitios (232):** cruces con nombre, sin dibujo: por dónde pasean los vecinos sin oficio (`paseo_…`), dónde esperan
  los recién llegados (`espera_…`), a dónde sale cada artesano por la mañana (`expedicion_…`), dónde trabajan los
  jornaleros (`jornal_…`), por dónde entran los asaltantes, el carro, el mirador y el contrabandista; los sitios de ocio (`ocio_…`), la ronda
  nocturna (`ronda_noche_…`), los puestos del mercado (`mercado_…`), el lavadero, la caravana, la puerta del este, el
  caballo, el botín de los asaltantes, el callejón del perista, las dos entradas del pueblo (`entrada_…`), la cama y el cuenco de cada mascota
  (`mascota_…`), el claro del Caso I (`claro_caso1`, `cuerpo_caso1`) y las 47 farolas de las calles y la plaza
  (`farola_calle_…`: mueve la cruz y la farola, con su luz, aparece ahí). Del bosque: madrigueras, guaridas de zorro,
  claros de ciervos y hozaderos de jabalí, hierbas (`hierba_…`), setas (`seta_…`), sus 5 carteles (`cartel_bosque_…`) y
  el borde del bosque que dibuja el mapa del valle (`linde_bosque_…`). Los 6 postes indicadores de los caminos
  (`poste_…`: gíralos y la tabla mira hacia ahí). Mueve una cruz y
  los vecinos irán ahí. Si mueves un campo o el lago, mueve también sus cruces. **No cambies «Id sitio».**
- **Zonas (3):** la plaza, el lago y la ciénaga (losas azules translúcidas con su nombre). Mueve una y van con ella su
  suelo o su agua, la hondonada del terreno, el muelle y dónde se nada y se pesca. No se giran ni cambian de forma. Los
  bancos, árboles y adornos de encima son piezas aparte: selecciónalos a la vez para moverlos juntos.
- **Objetos (10):** los 3 pozos, las 6 farolas de la plaza y el tablón de encargos. Muévelos o gíralos y el juego los
  pone ahí con todo su uso (sacar agua, luz, encargos). Lo demás sin dibujo propio son cruces de **Sitios**.
  **No cambies «Clave»**.
- **Caminos (32):** cada tramo recto es una losa que puedes mover, girar y **estirar con R**: el eje **X** es el largo y el
  **Z** el ancho. Para una calle nueva: Ctrl+D en un tramo y colócalo. Si hay tramos, el juego solo dibuja estos.
- **Vegetacion:** árboles, rocas, plantas, troncos, vetas de mineral. Son piezas sueltas: mueve, gira, borra o copia.
  Para pintar bosques enteros usa el **Pincel del mapa** (pestaña abajo, junto a «Output»): guía en `PINCEL_MAPA_GUIA.md`.
  En el Inspector, «Modelo» cambia el dibujo y «Choque» si se puede atravesar.
- **Decorado:** puentes, muelle, vallas, corrales, bancos, trozos de calleja… por zonas. Se mueven como las demás piezas.
  Los que chocan (bancos, verja y tumbas del cementerio, troncos del claro) llevan su pared invisible con ellos.
- **Decoracion:** arrastra aquí modelos de tu carpeta `mis_recursos` (o cualquier `.obj`/`.gltf`). Aparecen en el juego
  tal cual y son sólidos; para que se atraviesen: Inspector → Metadata → añade «atravesable» = true.
- **BajoTierra:** las alcantarillas enteras (oculta: ábrela con el ojo). Solo se mueven, no giran.

## 4. El río y los puentes (EditorMapa)
- Despliega **Rio**: cada **Punto** es un punto del cauce de norte a sur. **W** y arrastra la cruz. **Ancho** (Inspector)
  ensancha el río en ese punto. Con el mapa ×5 el río del pueblo anda por **100–150** y una persona mide unos 10.
- Punto nuevo: elige uno, **Ctrl+D** y arrástralo. Quitar: **Supr**. **Curvas naturales** (en Rio): 1 = orillas
  irregulares; 0 = el agua pasa justo por tus puntos.
- **Cruces:** cada puente o vado. Arrástralo encima del agua. En el Inspector: nombre, tipo, ancho y largo. El juego alarga
  solo cada paso hasta las dos orillas, así que el largo apenas importa; el ancho sí (menos de 32 y no se cabe).
- **Rojo:** un edificio con borde rojo es que el agua lo pisa (aparta el río). Un puente rojo no llega a las orillas.
- Al mover el río, en Mundo3D marca «Regenerar» (Inspector del nodo raíz) para que la maqueta lo enseñe en su sitio.

## 5. Medidas con el mapa ×5 (2026-11-11)
- Todo está **cinco veces más lejos** que antes; los edificios miden lo mismo. Una casa mediana mide unos 130 × 96 y la
  plaza unos 700 × 390. Un metro del juego son unos 18 de estas unidades.
- Lo que el código coloca por su cuenta (rutas de vecinos, pistas, zonas) sigue a las piezas que muevas gracias a las
  «anclas». Si algo se queda atrás al mover una pieza, apúntalo en `docs/FALLOS_VISIBLES.md` con una frase.

## 6. Avisos
- Si Claude cambió el mapa mientras tenías Mundo3D abierto, Godot te lo dirá: **cierra la pestaña sin guardar** y vuelve
  a abrirla, o Proyecto → Recargar proyecto actual. Si guardas encima, pisas sus cambios.
- Los avisos amarillos del editor (abajo) no los ve Claude: hazle una captura con el archivo y la línea.
- Nunca borres las carpetas raíz ni cambies los nombres internos («Id edificio», «Clave»).
