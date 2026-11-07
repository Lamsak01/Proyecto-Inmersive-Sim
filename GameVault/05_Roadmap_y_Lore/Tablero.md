---

kanban-plugin: board

---

## 🔥 Prioridad alta (presencia física)

- [ ] Arcabuz de chispa usable en combate directo ([[Armaduras, Sigilo y Arcabuz]])
- [ ] Recinto caminable del [[Puesto del Paso]]
- [ ] Sótanos y altillos dibujados en el tilemap ([[Capas Verticales y Alcantarillas]])


## 🔒 La Secta (autor)

- [ ] Jerarquía interna (iniciado, acólito, círculo interior)
- [ ] Infiltración en las instituciones
- [ ] Choque abierto con la [[Fe del Alba]]


## ❓ Lore por confirmar

- [ ] Premisa de los 4 capítulos («experimento cerrado»)
- [ ] Nombres de las 3 rutas comerciales
- [ ] Nombres de los 3 enclaves de expedición
- [ ] Nombres de las 3 tecnologías del taller
- [ ] Nombres de los 6 estilos de Maestro Artesano
- [ ] Orígenes de [[La Secta]] y el Sol Negro
- [ ] Nombres de la [[Fe del Alba]]
- [ ] Revisar el tono de las [[Misiones secundarias]]


## 🧹 Pulido

- [ ] Personajes 3D con más estilo, tipo Signalis ([[Assets de pago]])
- [ ] Rendimiento: abaratar el cálculo de los vecinos sin cambiar lo que hacen
- [ ] Animales 3D: conejo, gato y gallinas siguen planos (buscar modelos animados del mismo estilo)
- [ ] Buscar un jabalí 3D animado que guste al usuario (ahora es un lobo provisional)
- [ ] Hacer físicos: caravanas, expediciones, cenas y fiestas
- [ ] Dibujo 2D propio del caballo (ahora es el ciervo teñido) y postura de jinete a horcajadas


## 🚧 En progreso



## ✅ Hecho

- [x] Paso 1 — Arreglos rápidos (`1a`, `1b`, `1c`): examen forense real para cualquier vecino muerto fuera de caso según sus heridas y arma real (`stealth_assassinate` + `HealthComponent.wounds`), fondo en esquema limpio de pocas líneas del lugar real, barra de 4 fases de deterioro del cadáver, hilos del tablero por detrás de las tarjetas, variedad de ropa/peinados/barba/piel en vecinos, hombros sin atravesar ropa, libro a escala normal, sapos sin cono de visión, agua del lago con colisión y muelle único, despacho del dueño en «Il Corvo», letreros sin pisarse y lápidas a escala humana ([[Investigación Forense]], [[Estética Retro 3D]]) (2026-11-07)
- [x] Herramientas del detective — Preparado para 10 casos (`D5`) y fachada 3D de estuco claro en «Il Corvo» (`FALLOS_VISIBLES.md`): archivo de datos `DetectiveCaseData.gd` con los 10 huecos de casos, esqueleto del Caso I («La mujer del bosque») con `PENDIENTE_DECISION_USUARIO` en los huecos de trama y reparto de papeles entre vecinos vivos ([[Investigación Forense]], [[Trattoria Il Corvo]]) (2026-11-07)
- [x] Herramientas del detective — Cuaderno y tablero del caso (`D4`): atajo con tecla `[N]` en cualquier momento, tablero de corcho con fichas arrastrables de sospechosos y pistas anotadas, unión y borrado de hilos rojos entre fichas, y guardado/carga en la partida ([[Investigación Forense]]) (2026-11-07)
- [x] Herramientas del detective — Escena del crimen (`D3`): búsqueda a oscuras moviendo el farol con el ratón sobre el fondo cenital 3D en esquema, pistas físicas reales de `VillageForensics` (sangre o su ausencia, arrastre, huellas, objetos plantados) y testigos cercanos con «Preguntar» y «Presionar» según su carácter y afinidad ([[Investigación Forense]]) (2026-11-07)
- [x] Herramientas del detective — Autopsia en la morgue (`D2`): mesa de autopsias con el Dr. Valen, 4 pruebas por pasos con riesgo de fallo (`sangre` con 2 viales y tabla de colores, `cuello`, `estomago`, `piel`), consejo del forense a cambio de minutos, actualización de la causa real y conexión con `VillageForensics` ([[Investigación Forense]]) (2026-11-07)
- [x] Herramientas del detective — Examen del cuerpo en la escena (`D1`): pantalla fiel a `docs/bocetos/examen_cuerpo.html` al pulsar `[E]` junto a un cadáver, con fondo cenital 3D en esquema del lugar real, silueta plana de mujer u hombre según la víctima, 7 zonas clicables, acciones superficiales que avanzan minutos del reloj, marcas sobre el cuerpo y tira inferior del cuaderno del caso ([[Investigación Forense]]) (2026-11-07)
- [x] Prueba de primera persona (`B7`, prototipo en evaluación): tecla `[F6]` / `[F8]` cambia al vuelo entre la vista normal y primera persona (`PROJECTION_PERSPECTIVE`, FOV 70° a la altura de los ojos, giro con ratón/flechas, `W/A/S/D` relativo a hacia dónde miras, `[E]` en el centro de la pantalla, avatar propio oculto y tejados cerrados al entrar en edificios) ([[Assets de pago]]) (2026-11-07)
- [x] Los 21 vecinos fundadores con historia (`B6`): 6 rasgos coherentes sin contradicciones (más variantes entre partidas), amistades y rencores cruzados, 2 o 3 secretos propios por fundador y las 21 fichas de vecinos completadas ([[Los 21 Vecinos Originales]], [[Identidad y Rasgos Ocultos]], [[Secretos y Deseos Propios]]) (2026-11-07)
- [x] Lo que se ve en la calle (`B5`): bocadillos cortos de 1,5 s sin pausar al cruzarse enemigos o familias en feudo (apartándose en la calle), merodeo nocturno alrededor de la casa de la víctima antes de una venganza, pregón de obras maestras y decretos/inauguraciones, y fila escolar a las 9:00 en la puerta de la escuela ([[Clanes Familiares]], [[Secretos y Deseos Propios]], [[Maestros Artesanos]], [[Escuela y Graduación]]) (2026-11-07)
- [x] Coherencia del ambiente (`B4`): la niebla nocturna recorta de madrugada la vista de los vecinos salvo cerca de farolas o faroles encendidos; los talleres saboteados echan humo y chispas en 2D y 3D hasta repararse y la lluvia apaga el fuego exterior; quitada la etiqueta «(dormida)» de las tendencias conectadas en `TraitCatalog.gd` y paseos nocturnos para Noctámbulos, Insomnes y Sonámbulos ([[Supervivencia y Clima]], [[Identidad y Rasgos Ocultos]]) (2026-11-07)
- [x] Del campamento del lago al pueblo (`B3`): con casa construida en el pueblo, trasladar a Toby (y su comedero) y tu gallinero/animales a tu solar, manteniendo el campamento del oeste como puesto de pesca, caza y refugio ([[Campamento, Agricultura y Pesca]], [[Vivienda e Hipotecas]]) (2026-11-07)
- [x] Calabozo de verdad (`B2`): los vecinos pillados en delitos nocturnos, peleas graves, veredictos o al delatar al jefe de «La Familia» van encerrados a la celda de la comisaría; se puede hablar con ellos entre rejas, pagar su fianza a las arcas o ayudarlos a escapar con ganzúas ([[Justicia y Comisaría]]) (2026-11-07)
- [x] El jugador descubre «La Familia» e interviene (`R4`, espiando reuniones nocturnas en el reservado, avisando a la víctima, delatando al Comisario o trabajando para el jefe) y **Don Vittorio Corvo** lidera «La Familia» desde el Día 0 ([[Trattoria Il Corvo]]) (2026-11-06)
- [x] Negocios discretos de «La Familia» (`R3`): cobro en persona de comisión de «tranquilidad» a comercios prósperos, préstamos del reservado y soborno a guardias poco honrados para que hagan la vista gorda de noche ([[Trattoria Il Corvo]]) (2026-11-06)
- [x] «La Familia» (`R2`): nace sola de un vecino ambicioso, sin escrúpulos y persuasivo; recluta de 2 a 4 vecinos de uno en uno (con rechazos y rumores) y se reúne de noche en el reservado de la [[Trattoria Il Corvo]] si no hay guardias cerca (2026-11-06)
- [x] Trattoria «Il Corvo»: restaurante grande con comedor, terraza, cocina, cámara fría, bodega, cuarto del dueño y reservado ([[Trattoria Il Corvo]]) (2026-11-06)
- [x] Rehacer el combate (`C7` fases 1–4 + `B1`, 2026-11-06 / 2026-11-07): peso y sonidos, rivales con las mismas reglas, cadena de espada, golpe cargado, guardia alta, empujón, zonas por dirección, armas melladas, desarmar y ruido con testigos en la misma planta y línea de visión ([[Armaduras, Sigilo y Arcabuz]])
- [x] Asaltos al pueblo medidos y puestos en pausa (el usuario prefiere crimen interno de bajo perfil) (2026-11-06)
- [x] Versión para Windows con «Léeme» para los amigos (2026-11-06)
- [x] Los vecinos lejanos viven siempre del todo (sin simulación «a ratos»); rendimiento medido y aparcado (2026-11-06)
- [x] Guardar y cargar sin sustos: lo que estaba a medias se retoma o se anula sin perder nada (2026-11-06)
- [x] Amputaciones y prótesis para el jugador, con prótesis sencilla (50 %) y buena (75 %) ([[Medicina Anatómica]]) (2026-11-06)
- [x] Club de pelea en el sótano de la taberna y sabotajes nocturnos de verdad (2026-11-06)
- [x] Rentas y cobros en persona; desfalco en el cofre del ayuntamiento (2026-11-06)
- [x] El perista espera de noche en el callejón, con capucha, y rumores sutiles (2026-11-06)
- [x] Animales 3D, paso 1: ciervo, zorro y perro, animados (2026-11-05)
- [x] Jabalíes con aspecto de lobo animado, provisional (2026-11-05)
- [x] Auditoría de Antigravity: 7 fallos y 22 fugas de oro arreglados (2026-11-05)
- [x] Arcas equilibradas: mercado, rutas e impuesto sobre la renta por tramos (2026-11-05)
- [x] Caballo físico: se ve, se monta y se desmonta (2026-11-05)
- [x] Tecla E con letrero, el ratón manda y Mayús+rueda o G cambian de opción (2026-11-05)
- [x] Una sola ficha corta del vecino bajo el ratón; completa con Alt (2026-11-05)
- [x] Letreros de edificios sin pisarse: solo cercanos o bajo el ratón (2026-11-05)
- [x] Asaltos físicos: atacantes reales y pelea en el mapa (2026-11-05)
- [x] Terminal lógica, cuadro eléctrico y objetos de los 3 grandes robos hechos físicos en 2D y 3D (2026-11-05)
- [x] Alcantarillas caminables de verdad: 3 rejillas en la calle, túneles subterráneos conectados, escalerillas y cofres de contrabando (2026-11-05)
- [x] Rejillas y escalerillas de alcantarilla vigiladas: bajar o salir delante de un guardia sube la búsqueda y delante de un vecino deja chisme (2026-11-05)
- [x] Ganado vivo del rancho y animales propios en tu corral con alimentación y esquila/recogida en persona (2026-11-05)
- [x] Interior físico de tu propia casa: huerto cosechable, banco de trabajo y alquimia, escondite bajo las tablas y escalera/trampilla `+1`/`-1` con `[E]` (2026-11-05)
- [x] Combate cuerpo a cuerpo con esquiva rodando (`[Espacio]`), parada a tiempo (`[Q]`) y golpes enemigos que avisan (`COMBATE-1`, 2026-11-06)
- [x] Pasos 3D sin patinar y armas y herramientas orientadas al derecho en la mano (`ANIM-1`, 2026-11-06)
- [x] Tienda propia («Bazar del Forastero») hecha física: mostrador con caja 2D/3D, dependiente en puesto y clientes a pie (`P1`, 2026-11-06)
- [x] Carreta de carga física en el rancho: tirar a mano o enganchar al caballo siguiendo el rastro, caja de 40 unidades y robo nocturno fuera de lugar seguro (`P2`, 2026-11-06)
- [x] Caravanas comerciales con mula en la plaza y campamento nocturno de contrabando con carro y farol en el claro noreste (`P3`, 2026-11-06)

- [x] Edificios con sus piezas quietas juntas (2026-11-06)
- [x] Casas iniciales repartidas por los barrios y árboles agrupados para dibujar menos (2026-11-06)
- [x] La aldea empieza con 40 vecinos, provisional para probar (2026-11-06)
- [x] Ampliar la aldea, paso 2: callejas curvas, casas escalonadas, Pozo de la Ronda y huerto vecinal (2026-11-06)

- [x] Casa mejorada del jugador (cabaña y casa de piedra) y gallinero en 3D (2026-11-06)

- [x] Precio según el tamaño: casita 80, casa 100, casona 140 (2026-11-06)

- [x] Ampliar la aldea, pasos 1 y 3: casitas, casas y casonas; Barrio del Lago, Caseríos del Bosque y Molino del Este (2026-11-06)

- [x] Niebla nocturna estilo Gloomwood: claro alrededor del jugador, siluetas a lo lejos, las luces la atraviesan (2026-11-06)

- [x] Objetos quietos en 3D: pozos, farolas, tablón, tienda de campaña, hoguera con caldero, tronco, cartel, generador, aspersor, huertos y compostador (2026-11-06)

**Complete**
- [x] Biblia del proyecto exportada a Obsidian
- [x] Estética retro 3D: animaciones reales, texturas pixeladas, día y noche ([[Estética Retro 3D]])
- [x] 3D de verdad: personajes en el escenario, sombras, tejados a dos aguas, bosque 3D y lago grande


%% kanban:settings
```
{"kanban-plugin":"board","list-collapse":[false,false,false,false,false,false]}
```
%%
