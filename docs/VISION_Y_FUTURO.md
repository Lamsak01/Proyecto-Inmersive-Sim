# Visión a largo plazo y banco de ideas

Documento permanente con la aspiración del juego y la lluvia de ideas del usuario.
**Cualquier asistente (sea el modelo que sea) debe leerlo antes de proponer sistemas nuevos.**
Nada de esta lista está aprobado para construir: cada idea necesita su plan corto y la aprobación del usuario
(ver reglas en `docs/HANDOFF.md`). No se borra ninguna idea sin que el usuario lo pida; se pueden marcar como
descartadas o aplazadas con el motivo.

Última actualización: 2026-11-02.

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
| P1 Persona | Rasgos (100, con opuestos), relaciones de un solo sentido, recuerdos que se degradan con el tiempo |
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

1. Los 100 rasgos (T2) → relaciones de un solo sentido → recuerdos que se degradan.
2. **Crónica del pueblo** (registro histórico, como las "leyendas" de Dwarf Fortress): hace visible lo que pasa y ayuda a detectar fallos.
3. Secretos (infidelidad, chantaje).
4. Deseos propios (planes de asesinato, ambición, conspiraciones contra el jugador).
5. Grupos y fe (creyentes y no creyentes, iglesia).
6. Economía y necesidades ampliadas (higiene y enfermedades, ladrones, adicciones, ricos y mendigos).
7. Instituciones y corrupción (alcalde, policía corrupta, nobles).
8. La secta secreta (usa todo lo anterior; posible gancho de la historia principal).
9. Crecer el pueblo (más gente, servicios, oficios) con simulación simplificada para quien esté lejos.
10. Grandes ampliaciones técnicas (ver sección 5, grupo "Lejano").

## 4. Banco de ideas por pieza

Estado: **Base** = ya existe algo en el juego sobre lo que construir. **Idea** = nada todavía.

### Vida social y emocional (P1, P2, P3)
- Relaciones de un solo sentido: amor no correspondido, amistad desigual, «le cae mal y el otro ni se entera». *(Base: cada vecino ya guarda su propio número; hoy se mueven a la vez. Propuesta detallada en la conversación del 2026-11-02: aprecio, chispa y molestia de cada uno; cuánto se conocen y la etapa, compartidos.)*
- Triángulos amorosos, celos, infidelidades. *(Base: aventuras, descubrimiento, chantaje y rupturas por infidelidad, bloques S.)*
- Ideas tras S (2026-11-02): hijos fuera de la pareja, venganzas del engañado, celos que acaben en violencia, la infidelidad como móvil de asesinato en las investigaciones, otros secretos (deudas, crímenes del pasado, vicios), olvidar también los rasgos que se rumorean.
- Degradación de relaciones con la distancia (si llevan tiempo sin verse).
- Idolatría u obsesión por un personaje (muy rara).
- Fama: alguien puede volverse famoso (por sus obras, peleas, oficio, escándalos).
- Enemigos que conspiran contra el jugador.
- Rencores entre familias que pasan a los hijos; reputación del jugador por grupo.
- Misiones nuevas que salen de estas piezas: «descubre si mi pareja me engaña», «ayúdame a olvidarle», «¿por qué me evita?», «consígueme pruebas contra el alcalde», «ayúdame a dejar la bebida». *(Base: sistema de misiones con plantilla, `docs/MISIONES.md`; objetivo: 25+ tipos diseñados con el usuario.)*

### Ciclo de vida
- Nacimientos de niños con etapas de crecimiento (bebé, niño, adolescente, adulto, anciano).
- Animales con etapas de crecimiento y crianza. *(Base: mascotas, gallinero.)*
- Escuelas y maestros (los niños aprenden, eso influye en su futuro oficio).

### Salud y cuerpo (P5)
- Estadística de higiene; si un vecino no se cuida, surgen enfermedades (y contagios).
- Adicciones (alcohol, drogas, juego).
- Amputaciones e implantes / prótesis. *(Base: medicina anatómica estilo RimWorld.)*

### Sociedad, crimen y poder (P4, P6)
- Secta secreta en el pueblo.
- Alcalde que puede ser corrupto; policías corruptos. *(Base: hecho en I: alcalde elegido, impuestos, desfalco, comisario sobornable.)*
- Ideas tras E e I (2026-11-03): nobles y señor del valle (aplazado al paso 9), que el jugador pueda presentarse a alcalde, campañas y promesas electorales, obras públicas pagadas con las arcas, adicción del jugador, más enfermedades (epidemias, cuarentena), mercado negro de lo robado, una casa de baños.
- Planes de asesinato entre vecinos. *(Base: hecho en D5, muy raros, con señales previas y pistas para el comisario.)*
- Ideas tras D (2026-11-03): que el ambicioso se quede un negocio vacante (hoy la sucesión ya existe, sin ambición), venganzas heredadas por la familia, que el asesino intente culpar a otro, que el jugador pueda ser víctima de un plan.
- Personas religiosas y no creyentes. *(Base: hecho en G, la Fe del Alba provisional, con sacerdote y Oficio los domingos.)*
- Ideas tras G (2026-11-03): confesión con el sacerdote como fuente de secretos (y un sacerdote que los use), fiestas del Alba al año, día de mercado entre semana, bodas y entierros en la capilla, un sacerdote corrupto o la secta nacida de los fanáticos (pasos 7 y 8), un aspecto propio para el sacerdote, rivalidad entre bandos que crece con el tiempo.
- Ladrones.
- Prostitución. *(Recomendación: solo implícita, fuera de cámara, como oficio y hecho social; nunca explícita. Se puede quitar sin perder nada importante.)*
- Clases sociales: nobles, gente adinerada, mendigos.

### Economía, oficios y negocios (P5)
- Más servicios y trabajos en el pueblo. *(Base: economía de oferta y demanda, tiendas, sucesión de oficios.)*
- Maestros artesanos con estilos propios (su obra se reconoce y tiene valor).
- Montar tu propio negocio y hacerle publicidad en el pueblo. *(Base: propiedad híbrida de negocios, fase 8.)*
- Rutas de comercio con otros lugares.
- Ingenieros que investigan nuevas tecnologías (árbol de investigación).

### Ocio, apuestas y peleas
- Casino, apuestas. *(Base: póker y billar en la taberna.)*
- Carreras de animales; peleas de perros y gallos.
- Club de la lucha, boxeo, peleas callejeras. *(Base: peleas entre vecinos.)*

### Mundo, ecosistema y exploración
- Sembrar árboles y que influya en el ecosistema (fauna, suelo, recursos).
- Ataques al pueblo (bandidos, fauna, otros asentamientos).
- Investigación y exploración.
- Alcantarillas con localizaciones nuevas.
- Niveles verticales: sótanos, edificios de varios pisos.
- Housing (casa propia, decorarla, comprar/alquilar).
- Crear tu propio asentamiento.

### Jugador
- Acompañantes del jugador (vecinos que te siguen y ayudan).
- Historia principal (pestaña «Principal» del panel de misiones ya preparada).

### Tecnología anacrónica
- Vehículos: caballos, bicicletas, motos, automóviles, carretas, barcos.
- Armas de fuego.
- Ordenadores y hackeo.
- Electricidad con sistemas lógicos que se puedan sabotear. *(Base: generador, farolas, aspersor, sabotaje de talleres.)*

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
