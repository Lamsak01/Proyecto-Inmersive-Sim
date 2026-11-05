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
9. ✅ **HECHO (escalado a 100+ vecinos)** — Crecer el pueblo (V1–V9, bloques A–K y bloque PQ: 27+ solares con tercera fila norte `u0..u6`, casas ampliables a 4 camas con altillo, panadería, sastrería, posada barata, albergue, ayuntamiento, biblioteca, escuela con maestro, mercado de los miércoles, granja, rancho, cantera, leñador, taller de reparaciones, jornaleros, llegadas y marchas hasta 100 vecinos, matrimonios con hijos que crecen y simulación simplificada para lejanos y otros pisos).
10. ✅ **HECHO** — Grandes ampliaciones técnicas (ver sección 5, grupo "Lejano", y sección 6, niveles verticales: implementados y verificados en los bloques PJ, PK, PL, PM, PN, PO y PP).

## 4. Banco de ideas por pieza

Estado: **✅ HECHO** = ya construido y funcionando en el juego. **🟡 EN PARTE** = una parte ya está hecha y otra sigue pendiente. **🧱 BASE** = existe el cimiento sobre el que construirlo. **💡 PENDIENTE** = nada construido todavía.

### Vida social y emocional (P1, P2, P3)
- ✅ **HECHO** — Relaciones de un solo sentido: amor no correspondido, amistad desigual, «le cae mal y el otro ni se entera», declaraciones con rechazo, excusas al quedar, sentimientos ocultos que descubres hablando y opiniones contadas por terceros («según X»). *(Hecho en U1–U7 y bloque E4.)*
- ✅ **HECHO** — Triángulos amorosos, celos, infidelidades, descubrir aventuras, chantaje y rupturas. *(Hecho en B3.3, S1–S6 y U3.)*
- ✅ **HECHO** — Ideas tras S y bloque P3 (2026-11-04):
  - ✅ **Hecho en V8:** venganzas del engañado y celos que acaban en violencia o asesinato pasional (en 5 días en vez de 14).
  - ✅ **Hecho en M1 / D5:** las rupturas por infidelidad y las amenazas cuentan como móvil en las investigaciones, y el asesino vecino deja rastro sin coartada.
  - ✅ **Hecho en P3 (`VillageLineage.gd`):** hijos secretos fruto de una infidelidad (con rasgo heredado del amante que despierta rumores al crecer), chantaje de paternidad, reclamar o repudiar al niño, manutención secreta semanal, expósitos dejados en la Capilla del Alba, adopción de huérfanos, rivalidad entre hermanastros por el taller, matrimonios por interés y pasado familiar fuera del valle.
- ✅ **HECHO** — Degradación de relaciones con la distancia (si llevan más de 7 días sin verse, el aprecio y la chispa se enfrían poco a poco hacia neutro). *(Hecho en U6.)*
- ✅ **HECHO** — Idolatría u obsesión por un personaje (muy rara, `VillageFame.gd`, test #85): un vecino solitario puede obsesionarse en secreto con alguien célebre o muy admirado, seguirle por el valle, dejarle regalos anónimos pagados de su propio bolsillo y sentir celos enfermizos de quienes se le acercan; puedes tantear a los vecinos para descubrir quién es (sin que el menú lo delate antes), hacerle entrar en razón o avisar al afectado a cambio de una recompensa de su bolsillo. *(Hecho en bloque PH + seguidores de Líder en G4 y amor no correspondido en U3.)*
- ✅ **HECHO** — Fama: alguien puede volverse famoso o infame por sus obras, peleas, oficio, alcaldía o escándalos (`VillageFame.gd`, puntuación individual de −100 a +100 con rangos «🌟 Célebre» / «✨ Conocido» / «😠 Mal visto» / «🌑 Infame», visible en el glosario `[J]` y en opiniones de vecinos, más elogios o rumores públicos del jugador con tirada de riesgo). *(Hecho en `VillageFame.gd`, test #83.)*
- ✅ **HECHO** — Enemigos que conspiran contra el jugador (si te odian ≤ −50 durante 7 días: hablan mal de ti, se niegan a venderte en su tienda, te denuncian al comisario —incluso con cargos falsos si son mentirosos— y difunden tus secretos). *(Hecho en D4.)*
- ✅ **HECHO** — Rencores entre familias que pasan a los hijos y clanes (`VillageClans.gd`, P1):
  - ✅ **Hecho en G4 y G5:** reputación del jugador con cada grupo/familia en el glosario `[J]`, y defensa de bando en vivo (si peleas, calumnias o chantajeas a alguien, su familia te coge manía).
  - ✅ **Hecho en P1 (`VillageClans.gd`):** al morir un vecino o marcharse, su familia hereda el 50 % de sus odios profundos y odio total hacia el asesino; feudos de sangre entre familias tras peleas o asesinatos; boicot comercial contra el jugador; romances prohibidos (Romeo y Julieta); venganza del huérfano al cumplir 16 años; cenas de paz entre clanes; desheredar a la oveja negra; deudas de honor familiares al salvar vidas; guerras por el testamento y profanación nocturna de tumbas.
- ✅ **HECHO (25 de 25 tipos)** — Misiones nuevas que salen de estas piezas: «¿Me engaña X?», «Las cuentas de X», «La última copa», «Que no me quiten la casa», «La herencia de X», «El testigo con miedo», «La tumba sin nombre», etc. *(Hecho en Q1–Q4 y bloques M y N; ver `docs/MISIONES.md`.)*

### Ciclo de vida
- ✅ **HECHO** — Nacimientos de niños con etapas de crecimiento (embarazo de 9 días, nacen en casa, crecen 1 año cada 4 días, van a la escuela desde los 6 años, juegan por las tardes y a los 16 pasan a jóvenes adultos que buscan trabajo o heredan el taller familiar). *(Hecho en V9 y bloque B; pendiente solo dibujo propio de bebé/anciano.)*
- ✅ **HECHO** — Animales con etapas de crecimiento y crianza (`VillageHousing.gd`, test #86): tanto el ganado del Rancho del Sur (`ranch_herd`) como las crías que el jugador compra y alimenta en su corral (`player_animals`) pasan por etapas (`cría` → `joven` → `adulto`), producen lana, carne o comida al madurar, crían nuevas camadas y ganan vigor para competir. *(Hecho en bloque PI + mascotas, gallinero, corral del rancho en V5d y fauna salvaje.)*
- ✅ **HECHO** — Escuelas y maestros: escuela en pie, maestro contratado cuando hay ≥ 2 niños en edad escolar, clases de 9 a 14 h entre semana, cartel con alumnos y graduación con bonificación de dominio de oficio según el número de clases asistidas al cumplir la mayoría de edad (`VillageFamily.gd`, `VillageNPC.gd`, test #84). *(Hecho en V5e, V9, bloque B y bloque PG.)*

### Salud y cuerpo (P5)
- ✅ **HECHO** — Estadística de higiene para vecinos y jugador; lavarse en pozos y en el lavadero; mal olor que molesta a los demás; si no se cuidan surgen enfermedades contagiosas (resfriado y fiebre gris, que encama y puede matar si el médico no la trata). *(Hecho en E1–E2.)*
- ✅ **HECHO** — Adicciones y drogas (alcohol, «polvo de ocaso», juego):
  - ✅ **Hecho en E5 y M14:** adicción de los vecinos a la bebida y al juego, borracheras que sueltan secretos, síndrome de abstinencia que empuja a robar y misión para ayudar a dejar la bebida.
  - ✅ **Hecho en P7 (`VillageUnderworld.gd`):** tráfico, destilación en banco de trabajo casero y venta clandestina de «polvo de ocaso» a ricos, nobles y adictos.
- ✅ **HECHO** — Amputaciones e implantes / prótesis médicas (`VillageIllness.gd`, test #87): cuando una herida en un brazo o pierna alcanza infección grave (gangrena), el médico realiza una amputación de urgencia para salvar la vida; los vecinos con al menos 25 de oro (o costeados por el jugador en la consulta del médico) encargan una prótesis articulada de hierro y cuero junto al arreglador (repartiendo el oro entre el médico y el arreglador y consumiendo 1 kit de reparación), lo que devuelve la función completa del miembro. *(Base anatómica estilo RimWorld + hecho en bloque PJ.)*

### Sociedad, crimen y poder (P4, P6)
- ✅ **HECHO** — Secta secreta en el pueblo («Hijos del Ocaso» provisional: nace sola con crisis o ricos aburridos si hay líder persuasivo, captación, reuniones de noche, bando oculto, profanaciones, rito de sangre muy raro; puedes espiarla, unirte, chantajear o denunciarla). *(Hecho en O1–O8.)*
- **El usuario ampliará el sistema de sectas más adelante** (2026-11-03): lo construido le deja sitio.
- 💡 **PENDIENTE** — Ideas tras O (2026-11-03): encargos internos de la secta para el jugador, la droga «polvo de ocaso» como cebo, que la secta capte al comisario o al alcalde a propósito, rivalidad abierta con el sacerdote, varias sectas o cultos, que el fundador huya en vez de pagar multa, un lugar de reunión propio (cripta o sótano), la secta como gancho de la historia principal. *(Nota: en M16 ya existe la misión externa «Lo que se lee de noche» para descubrir la secta desde la biblioteca.)*
- ✅ **HECHO** — Alcalde que puede ser corrupto; policías corruptos (elecciones con urna en el Ayuntamiento, impuestos de los sábados, alcalde que desfalca las arcas y puede ser destapado, comisario sobornable por ladrones y por el jugador). *(Hecho en I1–I6 y V5b.)*
- ✅ **HECHO** — Ideas tras E, I y bloques P2, P4, P5 y P7 (2026-11-04):
  - ✅ **Hecho en V6 y bloque H:** nobles y señor del valle (mansión, rentistas, cobro de rentas a granja y rancho, influencia en las elecciones y préstamos hipotecarios para casas con interés del 25 % y desahucio).
  - ✅ **Hecho en V4, V3 y J4:** obras públicas y gasto social pagados con las arcas (casas de oficio/vivienda y gachas del Albergue).
  - ✅ **Hecho en M4:** compra de votos y promesas electorales para un candidato (`vote_buying`).
  - ✅ **Hecho en P5 (`VillageMayor.gd`):** presentarte a Alcalde en el Ayuntamiento, campañas de difamación, alcalde títere bajo chantaje, impuestos bajos, normales o altos, decretos municipales (toque de queda, ley seca, subsidio del mercado), obras públicas, nombrar/destituir comisario, malversar fondos o maquillar libros y moción de censura.
  - ✅ **Hecho en P7 (`VillageUnderworld.gd`):** mercado negro nocturno tras la taberna con perista, herramientas ilegales (ganzúas, veneno lento, somnífero, papeles falsos), encargos de robo a medida, usura del jugador, extorsión de «protección» a comercios, sicarios/saboteadores a sueldo, club de pelea clandestino a medianoche, soborno de ronda nocturna y convertirte en Jefe del Hampa.
- ✅ **HECHO** — Planes de asesinato entre vecinos (muy raros, con señales previas, rumor de amenaza, opción de avisar a la víctima o denunciar al comisario, y pistas forenses). *(Hecho en D5.)*
- ✅ **HECHO** — Ideas tras D y bloque P2 (`VillageForensics.gd`, 2026-11-04):
  - ✅ **Hecho en V8:** que el vecino ambicioso se quede con un negocio vacante antes de traer a un forastero.
  - ✅ **Hecho en P1 y P2 (`VillageClans.gd`, `VillageForensics.gd`):** venganzas heredadas por la familia al morir un pariente, plantar pistas falsas para incriminar a un rival, coartadas falsas por lealtad familiar/secta, testigos intimidados, sicarios por encargo, veneno lento que simula muerte natural hasta la autopsia, mover el cadáver de noche, confesiones ebrio o con fiebre, chivo expiatorio del comisario corrupto y emboscadas nocturnas con la guardia.
- ✅ **HECHO** — Las 29 mecánicas adicionales de los bloques P1–P7 implementadas en 6 tandas y verificadas en `verify_all.gd` (2026-11-04):
  - ✅ Crimen (`VillageForensics.gd`): fregar la escena con lejía, sobornar al médico para falsear la autopsia, pólizas de seguro de vida, trucar la hora de la muerte, limpiador nocturno de cadáveres, imitar el sello de otro asesino (copycat), obligar con chantaje a un vecino a confesar por ti.
  - ✅ Clanes (`VillageClans.gd`): patriarca o matriarca a quien obedece la familia, sabotajes de noche entre negocios de familias rivales.
  - ✅ Linaje (`VillageLineage.gd`): interceptar cartas de amantes, bodas concertadas con dote, padrinos en el bautizo, enseñar un oficio a un niño, jóvenes que se escapan de noche al mirador.
  - ✅ Capilla (`VillageConfession.gd`): disfrazarte con el hábito del cura para confesar tú a los vecinos, fingir un milagro en el altar.
  - ✅ Alcaldía (`VillageMayor.gd`, `VillageSocialLife.gd`): debates públicos entre candidatos, indultar acusados, tributo de paz.
  - ✅ Casa (`VillageHousing.gd`): fiestas en casa, defender tu puerta de intrusos, revender casas cuando suben de precio, sótano secreto, hogar de leña.
  - ✅ Bajos fondos (`VillageUnderworld.gd`, `VillageHousing.gd`): caravana de contrabando de medianoche, timbas de dados, red de carteristas, falsificar escrituras o salvoconductos, retar al jefe de la «Red de las Sombras».
- ✅ **HECHO** — Personas religiosas y no creyentes (la Fe del Alba provisional, con el sacerdote Hermano Anselmo, sermones y Oficio en la capilla los domingos). *(Hecho en G1–G7.)*
- ✅ **HECHO** — Ideas tras G y bloque P4 (`VillageConfession.gd`, 2026-11-04):
  - ✅ **Hecho en V5e:** día de mercado entre semana (miércoles por la mañana en la plaza).
  - ✅ **Hecho en P4 (`VillageConfession.gd`):** confesión entre semana (martes y jueves) con el sacerdote como fuente de secretos, espiar el confesionario en sigilo, sacerdote corrupto que vende secretos o chantajea, penitencias visibles al día siguiente, excomunión, confesarte tú mismo, bulas de indulgencia compradas por ricos, sermón dominical con indirectas, crisis de fe del sacerdote y derecho de santuario en la capilla.
- ✅ **HECHO** — Ladrones (robos nocturnos a vecinos, tiendas o al jugador, testigos, denuncias y devolución con multa o soborno). *(Hecho en E4.)*
- 💡 **PENDIENTE** — Prostitución. *(Recomendación: solo implícita, fuera de cámara, como oficio y hecho social; nunca explícita. Se puede quitar sin perder nada importante.)*
- ✅ **HECHO** — Clases sociales: nobles, ricos, acomodados, humildes, pobres y mendigos (con limosna en la plaza, Albergue del Alba y raciones de gachas). *(Hecho en E3, V5b, V6 y J4.)*

### Economía, oficios y negocios (P5)
- ✅ **HECHO** — Más servicios y trabajos en el pueblo: panadería, sastrería, segunda posada («El Candil»), albergue, granja, rancho, cantera, cabaña del leñador, taller de reparaciones, biblioteca, escuela y jornaleros por horas. *(Hecho en V5a–V5e y V9.)*
- ✅ **HECHO** — Maestros artesanos con estilos propios (`VillageFame.gd`, test #83): los artesanos con experiencia e inclinación por el oficio (`craft`, `diligence`, `trade`) alcanzan el título de Maestro Artesano con un estilo de autor propio de su gremio, elaboran Obras Maestras firmadas (`masterwork_piece`) que compran los vecinos ricos y nobles con oro de su bolsillo, cobran suplemento de prestigio en el mercado y permiten al jugador patrocinar talleres o comerciar con sus piezas.
- ✅ **HECHO** — Montar tu propio negocio desde cero en un solar y hacerle publicidad en el pueblo (`VillageHousing.gd`, test #84): acondicionar mostrador en tu solar construido («Bazar del Forastero», 65 de oro al carpintero), abastecerlo con artículos reales de tu mochila, contratar a un vecino sin oficio como dependiente (cobra 4 de oro al día de la caja), pregonar y hacer publicidad por la plaza (12 de oro a las arcas, multiplica la clientela durante 3 días) y recaudar las compras que los vecinos pagan de su propio bolsillo. *(Hecho en bloque PG + propiedad híbrida y escrituras comerciales de P6.)*
- ✅ **HECHO** — Rutas de comercio con otros lugares (`VillageCulture.gd`, test #88): puedes abrir rutas comerciales regulares con asentamientos vecinos («Paso Alto», «Puerto Fluvial del Este», «Vega del Sol») pagando la carta de arancel municipal (25 de oro a las arcas); cada día las rutas activas intercambian excedentes locales de los gremios por materias primas importadas y pagan derechos de paso al artesano y al ayuntamiento con cargo al fondo comercial de la ruta, y una vez al día puedes enviar tu propia remesa de mercancía. *(Hecho en bloque PK.)*
- ✅ **HECHO** — Ingenieros que investigan nuevas tecnologías (`VillageCulture.gd`, test #89): en el Taller de Reparaciones puedes financiar un árbol de investigación con prerrequisitos («Engranajes Hidráulicos» → «Cerraduras y Empalizadas de Precisión» / «Condensadores Voltaicos»); el ingeniero avanza cada día apoyándose en las lecturas de la biblioteca o con chatarra aportada por el jugador, y cada tecnología desbloqueada da bonificaciones permanentes al valle (+1 pan diario, +2 defensa frente a incursiones, +1 kit de reparación diario). *(Hecho en bloque PL.)*

### Ocio, apuestas y peleas
- ✅ **HECHO** — Casino y apuestas: póker, blackjack, ruleta y billar en la posada para el jugador, y vecinos que van a apostar por las tardes y pueden engancharse al juego. *(Base + hecho en E5.)*
- ✅ **HECHO** — Carreras de animales y peleas de perros y gallos (`VillageUnderworld.gd`, `VillageHousing.gd`, test #86): carreras de animales (apuesta de 12 de oro contra el bolsillo del vecino, una vez al día) y peleas clandestinas de gallos/perros (apuesta de 15 de oro contra el bolsillo del vecino, con riesgo de que te oiga la guardia), donde el vigor de los animales adultos que hayas criado mejora tus probabilidades sin garantizar nunca la victoria. *(Hecho en bloque PI.)*
- ✅ **HECHO** — Club de la lucha, boxeo, peleas callejeras. *(Peleas entre vecinos en B4.1–B4.2, misión de pelea anunciada en M17 y club de pelea clandestino a medianoche con apuestas y combate a puño limpio en P7 `VillageUnderworld.gd`.)*

### Mundo, ecosistema y exploración
- (Usuario, 2026-11-05, sin decidir) **Cosas raras en la oscuridad**, quizá paranormales. La noche ya se ve inquietante (solo aspecto); esto sería el paso siguiente. Hay una animación de «caminar zombi» lista por si acaso.
- ✅ **HECHO** — Sembrar árboles y que influya en el ecosistema (`EcosystemManager.gd`, `VillageCulture.gd`, test #88): junto al leñador puedes sembrar pinos jóvenes en el bosque (con semillas de cultivo o comprando un plantón de vivero); cada pino plantado añade un árbol talable real al bosque, hace rebrotar flora silvestre agotada, atrae fauna herbívora (venados y conejos) y sube la fertilidad del suelo para aumentar las cosechas de madera y grano del valle. *(Hecho en bloque PK.)*
- ✅ **HECHO** — Ataques e incursiones organizadas contra el pueblo (`VillageCulture.gd`, test #89): cuando sube la amenaza exterior, los vigías avisan la víspera de una incursión contra el pueblo; puedes financiar barricadas y milicia vecinal ante el comisario o los guardias (15 de oro a las arcas, +2 de defensa) y encabezar la defensa para cobrar recompensa de las arcas si rechazáis el asalto, o sufrir saqueo de las arcas, sabotajes y heridos si las defensas caen. *(Hecho en bloque PL.)*
- ✅ **HECHO** — Investigación y exploración (`VillageCulture.gd`, test #90): una vez al día puedes organizar expediciones de exploración a las «Ruinas de Cobre del Oeste», las «Grutas de Cristal del Norte» y la «Atalaya Hundida del Pantano» pagando 12 de oro en víveres al guía; si la expedición triunfa, regresas con reliquias o materias primas (`copper_coil`, `iron_ore`, `herbs`) y sumas apuntes de campo a las lecturas de la biblioteca para impulsar el árbol de investigación. *(Hecho en bloque PM.)*
- ✅ **HECHO** — Alcantarillas con localizaciones nuevas (`VillageUnderworld.gd`, test #91): tras comprar la llave maestra y el plano (20 de oro al perista o al arreglador), puedes bajar al nivel `-1` y explorar una vez al día la «Cisterna Vieja bajo la Plaza», el «Pasadizo del Contrabandista» (que además rebaja en 1 tu búsqueda policial) y la «Bóveda Inundada del Antiguo Gremio», recuperando piezas de taller y monedas extraviadas por las rejillas o arriesgándote a sufrir mordeduras de ratas e infección por aguas negras. *(Hecho en bloque PN.)*
- ✅ **HECHO** — Niveles verticales: sótanos y edificios de varios pisos por capas (`VillageNPC.gd`, `VillageManager.gd`, `VillageHousing.gd`, test #91): sistema de capas en las mismas coordenadas (`elevation_level`: `-1` sótano/alcantarillas, `0` calle, `+1` altillo/primer piso encargable al carpintero por 50 de oro), con atenuación visual de los niveles distintos y filtrado automático de distancias y testigos para que los vecinos de la calle no presencien lo que ocurre en el sótano o en la planta alta. *(Hecho en bloque PN según diseño de la sección 6.)*
- ✅ **HECHO** — Housing (casa propia, mejorarla, comprar/alquilar y ser terrateniente):
  - ✅ **Hecho para los vecinos (V4, V3 y bloque H):** compra de casas en solares, hipotecas a plazos con interés, alquiler y desahucios.
  - ✅ **Hecho para el jugador en P6 (`VillageHousing.gd`):** comprar o encargar tu propia casa en un solar libre (al contado o con hipoteca), dormir/asearte gratis y usar tu cofre privado, mejoras de interior con el carpintero (estantería, banco de trabajo, cama de roble, cerradura reforzada), vivir con tu pareja, comprar más casas o embargos para cobrar alquiler como casero, huerto casero, cenas en casa, escondite secreto bajo las tablas y escrituras de locales comerciales.
- ✅ **HECHO** — Crear tu propio asentamiento (`VillageCulture.gd`, test #93): puedes fundar el asentamiento fronterizo «Puesto del Paso» pagando la carta de fundación (90 de oro: 70 a las arcas municipales y 20 como fondo inicial del puesto) y aportando 2 de madera y 2 de piedra; allí puedes reclutar hasta 3 vecinos sin empleo como colonos (15 de oro de adelanto a su bolsillo y jornal diario de 3 de oro del arca del asentamiento), levantar estructuras propias (Aserradero Fronterizo, Granero del Paso y Atalaya de Guardia, 35 de oro al artesano) y recaudar el excedente de peajes comerciales acumulado en su arca. *(Hecho en bloque PP. Ojo: por ahora el asentamiento solo existe en los menús; no tiene lugar en el mapa.)*
- 💡 **PENDIENTE** — Darle al «Puesto del Paso» un lugar físico en el mapa (casas, colonos que viven allí, caminos), en vez de gestionarlo solo desde menús.
- 💡 **PENDIENTE** — Que el jugador también pueda sufrir gangrena y amputación (hoy solo les pasa a los vecinos; la prótesis para ti ya existe en el médico, pero nunca llega a ofrecerse).

### Jugador
- ✅ **HECHO** — Acompañantes del jugador (`VillageFame.gd`, `VillageNPC.gd`, test #85): un vecino con alta afinidad (≥ 55, gratis por amistad) o contratado como escolta (15 de oro al día pagados de tu bolsa a su bolsillo) te acompaña a pie por el valle, te respalda ante otros vecinos (una vez al día con tirada de riesgo) y vuelve a sus tareas cuando lo despides o si dejas de pagarle su jornal. *(Hecho en bloque PH.)*
- ✅ **HECHO** — Historia principal en la pestaña «Principal» del panel de misiones `L` (`VillageCulture.gd`, `QuestManager.gd`, test #93): arco de 4 capítulos («I. Las Raíces del Valle», «II. El Pulso Bajo la Piedra», «III. La Máquina de Cobre» y «IV. La Placa de Petri») que conecta la integración del forastero, los hallazgos en las ruinas y alcantarillas, la investigación tecnológica del generador y el destino político del valle, con recompensas pagadas de las arcas municipales al completar cada capítulo. *(Hecho en bloque PP.)*

### Tecnología anacrónica
- ✅ **HECHO** — Vehículos de época: caballos de silla y carretas de carga (`VillageCulture.gd`, test #90): en el Rancho del Sur puedes comprar al ganadero un Caballo de Silla (45 de oro, aumenta tu velocidad y mejora un +15 % el éxito de tus expediciones) y una Carreta de Carga (55 de oro, añade +4 de oro de rendimiento por cada remesa comercial enviada por ruta). *(Hecho en bloque PM; motos/coches quedan descartados para el tamaño actual del valle.)*
- ✅ **HECHO** — Armas de fuego de chispa (`SimpleInventory.gd`, `VillageCulture.gd`, test #92): tras investigar «Cerraduras y Empalizadas de Precisión», puedes encargar en la herrería o el taller un Arcabuz de Chispa con 2 cargas de pólvora (60 de oro al artesano) y comprar paquetes de Cargas de Pólvora Negra (14 de oro); llevar el arcabuz cargado añade +3 de defensa al encabezar el rechazo de incursiones *(Hecho en bloque PO.)*
- 💡 **PENDIENTE** — Disparar el arcabuz con el control de combate (apuntar y disparar, no desde un menú de conversación). La función del disparo ya existe y hace daño; falta conectarla al combate del jugador. *(Retirado del diálogo en la revisión de PF–PQ.)*
- ✅ **HECHO** — Terminales lógicas electromecánicas y hackeo (`VillageCulture.gd`, test #92): en el taller o la comisaría puedes hackear una vez al día la consola de tarjetas perforadas y relés de cobre (con tirada de riesgo mejorada por los «Condensadores Voltaicos» o llevando una bobina de cobre) para desviar un reembolso de hasta 18 de oro desde las arcas municipales, purgar 1 nivel de búsqueda policial y 25 de recompensa del archivo o reprogramar el controlador de la red eléctrica (+2 lecturas y línea reparada); si fallas la tirada, salta una descarga y la alarma lógica (+1 búsqueda policial). *(Hecho en bloque PO.)*
- ✅ **HECHO** — Electricidad con sistemas lógicos que se puedan sabotear (`VillageCulture.gd`, `VillageManager.gd`, `FarmPlot.gd`, test #87): red eléctrica dividida en circuitos independientes (circuito de farolas, bomba eléctrica de riego/aspersor y generador general) que pueden sabotearse por separado (1 vez al día, con riesgo de chispazo y búsqueda policial) para dejar las calles a oscuras o secar el riego automático, y repararse entregando una bobina de cobre (cobrando 12 de oro de las arcas municipales) o en el ciclo diario del arreglador con cargo al ayuntamiento. *(Base en V5e + hecho en bloque PJ.)*

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
