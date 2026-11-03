# Registro de cambios

Cambios del juego, del más nuevo al más antiguo. Añade una entrada al cerrar cada bloque, en lenguaje sencillo.
El detalle técnico está en `docs/HANDOFF.md` (sección 7) y el historial completo en `git log`. Lo anterior a B0.1 está en `AUDIT_LOG.md` y `SESSION_CONTEXT_LOG.md`.

## 2026-11-03

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
