# Registro de cambios

Cambios del juego, del más nuevo al más antiguo. Añade una entrada al cerrar cada bloque, en lenguaje sencillo.
El detalle técnico está en `docs/HANDOFF.md` (sección 7) y el historial completo en `git log`. Lo anterior a B0.1 está en `AUDIT_LOG.md` y `SESSION_CONTEXT_LOG.md`.

## 2026-11-02

### Crónica del pueblo
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
