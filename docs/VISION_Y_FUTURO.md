# Visión a largo plazo y banco de ideas

Documento permanente con la aspiración del juego y la lluvia de ideas del usuario.
**Cualquier asistente (sea el modelo que sea) debe leerlo antes de proponer sistemas nuevos.**
Nada de esta lista está aprobado para construir: cada idea necesita su plan corto y la aprobación del usuario
(ver reglas en `docs/HANDOFF.md`). No se borra ninguna idea sin que el usuario lo pida; se pueden marcar como
descartadas o aplazadas con el motivo.

Última actualización: 2026-11-04 (revisado punto por punto contra el juego tras el bloque N).

## 1. Aspiración

Un pueblo **realista, con lo bueno y lo malo**, con la profundidad de mecánicas e historias que surgen solas de
*Dwarf Fortress*, *Song of Syx* y *RimWorld* (más los referentes originales: *Kenshi* y *Stardew Valley*, ver `ROADMAP_PROYECTO.md`).
Época **anacrónica**: conviven lo tradicional con tecnología (electricidad, ordenadores, armas de fuego...).
Cuando muere alguien llegan personas nuevas generadas al azar, así que todo sistema debe funcionar con gente procedural.

### Decisiones firmes del usuario (2026-11-02)
- **Tamaño**: se empieza pequeño (máxima profundidad en pocas casas), pero el **objetivo final es una ciudad de al menos 100 vecinos**. Orden: profundidad primero, tamaño después. Hará falta simulación simplificada para los vecinos lejanos o en otro nivel (rendimiento).
- **Habrá sótanos y varios pisos.**
  - Sótanos: como en otros juegos del estilo, un mapa aparte que se desarrolla debajo del mapa principal (bodegas, túneles, alcantarillas; puede extenderse más allá de los edificios).
  - Pisos superiores: **aprobado el sistema de capas tipo *Project Zomboid*** (sección 6).

## 2. Principio de diseño (acordado)

La profundidad sale de **pocas piezas generales que se combinan**, no de muchas mecánicas sueltas.
Cada idea nueva debe construirse sobre estas piezas; si no encaja en ninguna, es una señal de alarma.

| Pieza | Qué es |
|---|---|
| P1 Persona | Rasgos (140, con opuestos), relaciones de un solo sentido, recuerdos que se degradan con el tiempo |
| P2 Secretos | Quién sabe qué y quién se lo contó (base: los chismes con `heard_from`) |
| P3 Deseos propios | Cada vecino persigue algo: amor, dinero, poder, venganza, fe, fama |
| P4 Grupos | Familia, iglesia, policía, ayuntamiento, bandas, secta; lealtad y miembros ocultos |
| P5 Economía y necesidades | Dinero real, precios, pobreza, higiene, salud, vicios |
| P6 Instituciones | Cargos con poder: alcalde, jefe de policía, cura, maestro; leyes y corrupción |

Reglas que acompañan al principio:
- Cada pieza tiene que **verse** (diálogos, textos flotantes, crónica). Si el jugador no lo nota, no vale la pena.
- Cada pieza se **mide en partidas largas** antes de pasar a la siguiente.
- Cada fase deja el juego **jugable y mejor**, nunca medio montado.
- Lo dramático y extremo (peleas, obsesiones, asesinatos) es **raro**: una partida tranquila también es válida.

## 3. Orden recomendado (acordado en principio)

1. ✅ **HECHO** — Los 140 rasgos (T1–T5) → relaciones de un solo sentido (U1–U7, E4) → recuerdos que se degradan y deforman (R1–R5).
2. ✅ **HECHO** — **Crónica del pueblo** (C1–C5, tecla `O`, hasta 500 sucesos con pestañas).
3. ✅ **HECHO** — Secretos (S1–S6: infidelidad, testigos, rumores deformados y chantaje).
4. ✅ **HECHO** — Deseos propios (D1–D6 y V8: venganza, venganza pasional por celos, planes de asesinato, ambición con sucesión de tienda y conspiraciones contra el jugador).
5. ✅ **HECHO** — Grupos y fe (G1–G7: Fe del Alba, sacerdote, Oficio de los domingos, familias, pandillas, seguidores y reputación por grupo).
6. ✅ **HECHO** — Economía y necesidades ampliadas (E1–E7 y J4: higiene, resfriado y fiebre gris, ladrones nocturnos, adicciones a bebida y juego, clases sociales, mendigos y gachas en el Albergue).
7. ✅ **HECHO** — Instituciones y corrupción (I1–I6, V5b, V6 y H1–H5: alcalde elegido con urna en el Ayuntamiento, impuestos, desfalco, comisario sobornable, nobles rentistas y préstamos hipotecarios con desahucio).
8. ✅ **HECHO (base completa; el usuario la ampliará más adelante)** — La secta secreta (O1–O8: «Hijos del Ocaso», nace sola por crisis o aburrimiento de los ricos, reuniones nocturnas, captación, bando oculto, profanaciones y rito de sangre).
9. 🟡 **HECHO HASTA 50 VECINOS (falta escalar a 100+)** — Crecer el pueblo (V1–V9 y bloques A–K: 20+ solares, panadería, sastrería, posada barata, albergue, ayuntamiento, biblioteca, escuela con maestro, mercado de los miércoles, granja, rancho, cantera, leñador, taller de reparaciones, jornaleros, llegadas y marchas, matrimonios con hijos que crecen y simulación simplificada para lejanos).
10. 💡 **PENDIENTE** — Grandes ampliaciones técnicas (ver sección 5, grupo "Lejano", y sección 6, niveles verticales).

## 4. Banco de ideas por pieza

Estado: **✅ HECHO** = ya construido y funcionando en el juego. **🟡 EN PARTE** = una parte ya está hecha y otra sigue pendiente. **🧱 BASE** = existe el cimiento sobre el que construirlo. **💡 PENDIENTE** = nada construido todavía.

### Vida social y emocional (P1, P2, P3)
- ✅ **HECHO** — Relaciones de un solo sentido: amor no correspondido, amistad desigual, «le cae mal y el otro ni se entera», declaraciones con rechazo, excusas al quedar, sentimientos ocultos que descubres hablando y opiniones contadas por terceros («según X»). *(Hecho en U1–U7 y bloque E4.)*
- ✅ **HECHO** — Triángulos amorosos, celos, infidelidades, descubrir aventuras, chantaje y rupturas. *(Hecho en B3.3, S1–S6 y U3.)*
- 🟡 **EN PARTE** — Ideas tras S (2026-11-02):
  - ✅ **Hecho en V8:** venganzas del engañado y celos que acaban en violencia o asesinato pasional (en 5 días en vez de 14).
  - ✅ **Hecho en M1 / D5:** las rupturas por infidelidad y las amenazas cuentan como móvil en las investigaciones, y el asesino vecino deja rastro sin coartada.
  - 💡 **Pendiente:** hijos fuera de la pareja (hoy `VillageFamily` solo concibe dentro de la pareja estable), otros secretos chantajeables (crímenes antiguos ocultos) y que los rasgos rumoreados falsos también se olviden solos con el paso del tiempo (hoy se borran al descubrir el rasgo real).
- ✅ **HECHO** — Degradación de relaciones con la distancia (si llevan más de 7 días sin verse, el aprecio y la chispa se enfrían poco a poco hacia neutro). *(Hecho en U6.)*
- 💡 **PENDIENTE** — Idolatría u obsesión por un personaje (muy rara). *(Hoy existen seguidores de un vecino con rasgo Líder en G4 y amor no correspondido en U3, pero no obsesión patológica.)*
- 🟡 **EN PARTE** — Fama: alguien puede volverse famoso (por sus obras, peleas, oficio, escándalos). *(Hoy el jugador tiene fama de ley y de fe, y los vecinos tienen la tendencia `fame` en sus rasgos, pero aún no hay puntuación de fama individual para cada vecino.)*
- ✅ **HECHO** — Enemigos que conspiran contra el jugador (si te odian ≤ −50 durante 7 días: hablan mal de ti, se niegan a venderte en su tienda, te denuncian al comisario —incluso con cargos falsos si son mentirosos— y difunden tus secretos). *(Hecho en D4.)*
- 🟡 **EN PARTE** — Rencores entre familias que pasan a los hijos; reputación del jugador por grupo:
  - ✅ **Hecho en G4 y G5:** reputación del jugador con cada grupo/familia en el glosario `[J]`, y defensa de bando en vivo (si peleas, calumnias o chantajeas a alguien, su familia te coge manía).
  - 💡 **Pendiente:** que al morir un vecino (o marcharse), sus hijos y familiares hereden parte de sus odios y rencores profundos.
- ✅ **HECHO (25 de 25 tipos)** — Misiones nuevas que salen de estas piezas: «¿Me engaña X?», «Las cuentas de X», «La última copa», «Que no me quiten la casa», «La herencia de X», «El testigo con miedo», «La tumba sin nombre», etc. *(Hecho en Q1–Q4 y bloques M y N; ver `docs/MISIONES.md`.)*

### Ciclo de vida
- ✅ **HECHO** — Nacimientos de niños con etapas de crecimiento (embarazo de 9 días, nacen en casa, crecen 1 año cada 4 días, van a la escuela desde los 6 años, juegan por las tardes y a los 16 pasan a jóvenes adultos que buscan trabajo o heredan el taller familiar). *(Hecho en V9 y bloque B; pendiente solo dibujo propio de bebé/anciano.)*
- 🧱 **BASE** — Animales con etapas de crecimiento y crianza. *(Base: mascotas, gallinero, corral del rancho en V5d y fauna salvaje; falta ciclo de crías que crezcan.)*
- ✅ **HECHO (base completa)** — Escuelas y maestros: escuela en pie, maestro contratado cuando hay ≥ 2 niños en edad escolar, clases de 9 a 14 h entre semana y cartel con alumnos. *(Hecho en V5e, V9 y bloque B; pendiente que el número de clases recibidas dé bonificación al elegir oficio de mayor.)*

### Salud y cuerpo (P5)
- ✅ **HECHO** — Estadística de higiene para vecinos y jugador; lavarse en pozos y en el lavadero; mal olor que molesta a los demás; si no se cuidan surgen enfermedades contagiosas (resfriado y fiebre gris, que encama y puede matar si el médico no la trata). *(Hecho en E1–E2.)*
- 🟡 **EN PARTE** — Adicciones (alcohol, drogas, juego):
  - ✅ **Hecho en E5 y M14:** adicción de los vecinos a la bebida y al juego, borracheras que sueltan secretos, síndrome de abstinencia que empuja a robar y misión para ayudar a dejar la bebida.
  - 💡 **Pendiente:** drogas (como el «polvo de ocaso») y adicción para el propio jugador.
- 🧱 **BASE** — Amputaciones e implantes / prótesis. *(Base: medicina anatómica estilo RimWorld con órganos, fracturas y sangrado; falta pérdida permanente de miembros y prótesis.)*

### Sociedad, crimen y poder (P4, P6)
- ✅ **HECHO** — Secta secreta en el pueblo («Hijos del Ocaso» provisional: nace sola con crisis o ricos aburridos si hay líder persuasivo, captación, reuniones de noche, bando oculto, profanaciones, rito de sangre muy raro; puedes espiarla, unirte, chantajear o denunciarla). *(Hecho en O1–O8.)*
- **El usuario ampliará el sistema de sectas más adelante** (2026-11-03): lo construido le deja sitio.
- 💡 **PENDIENTE** — Ideas tras O (2026-11-03): encargos internos de la secta para el jugador, la droga «polvo de ocaso» como cebo, que la secta capte al comisario o al alcalde a propósito, rivalidad abierta con el sacerdote, varias sectas o cultos, que el fundador huya en vez de pagar multa, un lugar de reunión propio (cripta o sótano), la secta como gancho de la historia principal. *(Nota: en M16 ya existe la misión externa «Lo que se lee de noche» para descubrir la secta desde la biblioteca.)*
- ✅ **HECHO** — Alcalde que puede ser corrupto; policías corruptos (elecciones con urna en el Ayuntamiento, impuestos de los sábados, alcalde que desfalca las arcas y puede ser destapado, comisario sobornable por ladrones y por el jugador). *(Hecho en I1–I6 y V5b.)*
- 🟡 **EN PARTE** — Ideas tras E e I (2026-11-03):
  - ✅ **Hecho en V6 y bloque H:** nobles y señor del valle (mansión, rentistas, cobro de rentas a granja y rancho, influencia en las elecciones y préstamos hipotecarios para casas con interés del 25 % y desahucio).
  - ✅ **Hecho en V4, V3 y J4:** obras públicas y gasto social pagados con las arcas (casas de oficio/vivienda y gachas del Albergue).
  - ✅ **Hecho en M4:** compra de votos y promesas electorales para un candidato (`vote_buying`).
  - 💡 **Pendiente:** que el jugador pueda presentarse a alcalde y gobernar, adicción del jugador, epidemias con cuarentena, mercado negro de objetos robados y una casa de baños cubierta (el lavadero al aire libre ya está hecho en V5d).
- ✅ **HECHO** — Planes de asesinato entre vecinos (muy raros, con señales previas, rumor de amenaza, opción de avisar a la víctima o denunciar al comisario, y pistas forenses). *(Hecho en D5.)*
- 🟡 **EN PARTE** — Ideas tras D (2026-11-03):
  - ✅ **Hecho en V8:** que el vecino ambicioso se quede con un negocio vacante antes de traer a un forastero.
  - 💡 **Pendiente:** venganzas heredadas por la familia al morir un pariente, que el asesino deje pistas falsas para culpar a un rival, y que un vecino pueda planear asesinar al propio jugador (hoy en D4 conspiran contra ti, pero sin matarte).
- ✅ **HECHO** — Personas religiosas y no creyentes (la Fe del Alba provisional, con el sacerdote Hermano Anselmo, sermones y Oficio en la capilla los domingos). *(Hecho en G1–G7.)*
- 🟡 **EN PARTE** — Ideas tras G (2026-11-03):
  - ✅ **Hecho en V5e:** día de mercado entre semana (miércoles por la mañana en la plaza).
  - 💡 **Pendiente:** confesión con el sacerdote como fuente de secretos (y un sacerdote que los use), fiestas del Alba al año, bodas y entierros con ceremonia en la capilla, sacerdote corrupto o secta nacida de fanáticos, aspecto propio para el sacerdote, rivalidad entre bandos que crece con el tiempo.
- ✅ **HECHO** — Ladrones (robos nocturnos a vecinos, tiendas o al jugador, testigos, denuncias y devolución con multa o soborno). *(Hecho en E4.)*
- 💡 **PENDIENTE** — Prostitución. *(Recomendación: solo implícita, fuera de cámara, como oficio y hecho social; nunca explícita. Se puede quitar sin perder nada importante.)*
- ✅ **HECHO** — Clases sociales: nobles, ricos, acomodados, humildes, pobres y mendigos (con limosna en la plaza, Albergue del Alba y raciones de gachas). *(Hecho en E3, V5b, V6 y J4.)*

### Economía, oficios y negocios (P5)
- ✅ **HECHO** — Más servicios y trabajos en el pueblo: panadería, sastrería, segunda posada («El Candil»), albergue, granja, rancho, cantera, cabaña del leñador, taller de reparaciones, biblioteca, escuela y jornaleros por horas. *(Hecho en V5a–V5e y V9.)*
- 💡 **PENDIENTE** — Maestros artesanos con estilos propios (su obra se reconoce y tiene valor).
- 🧱 **BASE** — Montar tu propio negocio y hacerle publicidad en el pueblo. *(Base: propiedad híbrida y compra de negocios existentes; falta fundar un negocio desde cero en un solar y hacerle publicidad.)*
- 💡 **PENDIENTE** — Rutas de comercio con otros lugares.
- 💡 **PENDIENTE** — Ingenieros que investigan nuevas tecnologías (árbol de investigación).

### Ocio, apuestas y peleas
- ✅ **HECHO** — Casino y apuestas: póker, blackjack, ruleta y billar en la posada para el jugador, y vecinos que van a apostar por las tardes y pueden engancharse al juego. *(Base + hecho en E5.)*
- 💡 **PENDIENTE** — Carreras de animales; peleas de perros y gallos.
- 🧱 **BASE** — Club de la lucha, boxeo, peleas callejeras. *(Base: peleas entre vecinos en B4.1–B4.2 y misión de pelea anunciada en M17; falta un club de boxeo organizado con apuestas.)*

### Mundo, ecosistema y exploración
- 💡 **PENDIENTE** — Sembrar árboles y que influya en el ecosistema (fauna, suelo, recursos).
- 💡 **PENDIENTE** — Ataques al pueblo (bandidos, fauna, otros asentamientos). *(Hoy hay asaltantes en los caminos de fuera, pero no incursiones organizadas contra el pueblo.)*
- 💡 **PENDIENTE** — Investigación y exploración.
- 💡 **PENDIENTE** — Alcantarillas con localizaciones nuevas.
- 💡 **PENDIENTE** — Niveles verticales: sótanos, edificios de varios pisos (diseño aprobado en la sección 6).
- 🟡 **EN PARTE** — Housing (casa propia, decorarla, comprar/alquilar):
  - ✅ **Hecho para los vecinos (V4, V3 y bloque H):** compra de casas en solares, hipotecas a plazos con interés, alquiler y desahucios.
  - 💡 **Pendiente para el jugador:** comprar o construir tu propia casa en un solar libre y decorarla por dentro.
- 💡 **PENDIENTE** — Crear tu propio asentamiento.

### Jugador
- 💡 **PENDIENTE** — Acompañantes del jugador (vecinos que te siguen y ayudan).
- 💡 **PENDIENTE** — Historia principal (pestaña «Principal» del panel de misiones `L` ya preparada).

### Tecnología anacrónica
- 💡 **PENDIENTE** — Vehículos: caballos, bicicletas, motos, automóviles, carretas, barcos.
- 💡 **PENDIENTE** — Armas de fuego.
- 💡 **PENDIENTE** — Ordenadores y hackeo.
- 🧱 **BASE** — Electricidad con sistemas lógicos que se puedan sabotear. *(Base: generador, farolas, aspersor, sabotaje de talleres y arreglador en V5e.)*

## 5. Valoración honesta (2026-11-02)

**Encajan bien y salen casi solas de las piezas** (prioridad media-alta): relaciones de un solo sentido, celos,
infidelidad, degradación, fama, higiene y enfermedades, adicciones, ladrones, clases sociales, corrupción,
secta, conspiraciones, planes de asesinato, nacimientos y crecimiento, escuelas, artesanos con estilo,
negocio propio y publicidad, apuestas y peleas organizadas.

**Lejano** (cambios grandes en el motor o en el mapa; se deciden más tarde, una a una):
- **Varios pisos / sótanos / alcantarillas**: conviene decidir pronto *si* existirán, porque afecta a cómo se montan los mapas (probablemente interiores como escenas aparte). Construirlo, más tarde.
- **Vehículos**: los caballos o carretas encajan con la época; motos y coches exigen mapas mucho más grandes.
- **Crear tu propio asentamiento y rutas de comercio**: es casi otro juego (Song of Syx). Mejor como fase final.
- **Ordenadores, hackeo, armas de fuego**: viables en lo anacrónico, pero hay que fijar antes las «leyes del mundo» (qué tecnología existe y por qué).
- **Ecosistema con árboles que influyen**: bonito, pero es una simulación propia; después de la economía.

**Tensión con la visión original**: `ROADMAP_PROYECTO.md` dice «máxima profundidad en un espacio reducido (unas 5 casas)».
Crecer el pueblo, vehículos o asentamiento propio van en otra dirección. No es malo, pero hay que decidirlo:
recomendación: **profundidad primero, tamaño después** (el pueblo crece solo cuando las piezas están sólidas, y con
simulación simplificada para quien esté lejos, por rendimiento).

**Riesgos generales**: alcance enorme (años, no meses); cada pieza multiplica los fallos posibles; el dibujo en
pixel art cuesta, así que mejor mecánicas que se expresen con texto, iconos y comportamiento.

## 6. Niveles verticales: sistema de capas (aprobado por el usuario el 2026-11-02)

Hoy los interiores están abiertos en el mismo mapa (sin techos ni cambio de escena).
Propuesta: **un solo sistema de "niveles" para sótanos y pisos**. Cada nivel (−1 sótano, 0 calle, 1 primer piso, 2...)
es una capa con las **mismas coordenadas** que el mapa principal; solo se ve y se choca con el nivel en que estás;
las escaleras y trampillas te cambian de nivel.
- Sótanos/alcantarillas: nivel −1, oscuro, con su propio trazado.
- Pisos superiores: al subir, desaparece la planta baja de ese edificio y ves la planta de arriba; la calle de alrededor
  se ve oscurecida debajo (como *Project Zomboid*). Encaja con los interiores abiertos actuales.
- Descartada: cada piso como escena aparte (estilo *Stardew Valley*). Más fácil, pero se pierde la
  sensación de mundo continuo y los vecinos de otros pisos dejan de verse.
- Consecuencias: cada vecino tendrá un nivel además de su posición; los caminos de los vecinos, los testigos, el
  sonido y el sigilo deberán comprobar «mismo nivel». **Regla desde ya**: los sistemas nuevos que miren distancias
  (testigos, oír, ver) deben pasar por una función común, para que añadir niveles sea cambiar un solo sitio.
