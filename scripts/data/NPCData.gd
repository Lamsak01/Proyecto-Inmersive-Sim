extends RefCounted

## Tablas de datos puros de los habitantes del valle (alias, perfiles de personaje y relaciones iniciales).
## Separadas de VillageNPC.gd para mantener ese script más corto. VillageNPC las re-expone como constantes con el mismo nombre.

const NPC_NAME_ALIASES: Dictionary = {
	"Dra. Valeria": "Dr. Valen", "Dr. Silvano": "Dr. Valen",
	"Comisario Thorne": "Comisario Vane", "Inspectora Lyra": "Comisario Vane",
	"Guardia Kaelen": "Guardia Rodric", "Centinela Bastian": "Guardia Rodric",
}

const NPC_LORE_PROFILES: Dictionary = {
	"Thoran": ["thoran", "Antiguo maestro armero de la Fundición Imperial de Vaelgard; desertó tras negarse a forjar grilletes de plomo para las cuencas mineras.", "«No siempre forjé herraduras y azadas, forastero. Durante veinte años dirigí los altos hornos de la guarnición de Vaelgard. La cicatriz que me cruza el pómulo me la dejó un crisol de bronce cuando saboteé mis propios moldes la noche antes de que marcharan contra los mineros de Cima Quebrada.\n\nHuí al sur con mi hijo Kael entre la ceniza, jurando no volver a templar una hoja que sirviera a un tirano... aunque en este valle el hierro vuelve a pedir sangre.»", "«El Comisario Vane y yo nos conocemos de aquella guerra, aunque ambos fingimos que no cuando nos cruzamos en la plaza. Él perdió el ojo en el mismo asedio donde yo deserté. Quemó mi cartel de búsqueda porque sabe que este valle necesita mi yunque más que otra soga en el patíbulo.»"],
	"Kael": ["kael", "Aprendiz de forja obsesionado con descifrar las bobinas y conductos de tecnología antigua enterrados bajo las ruinas del oeste.", "«Mi padre cree que el acero solo sirve para protegerse o arar la tierra, pero bajo este valle hay conductos de cobre y generadores que no forjó ningún herrero común.\n\nCuando cae la noche y Thoran duerme, estudio los fragmentos que los viajeros traen de la Llanura Salvaje. No quiero pasar mi vida reparando rejas; quiero entender qué civilización levantó las máquinas que aún laten bajo la roca.»", "«Le he estado comprando reliquias y bobinas en secreto a Aldric en la posada. Si mi padre descubre que enciendo la fragua de madrugada para ensayar aleaciones antiguas, me quitará las llaves del taller.»"],
	"Garrick": ["garrick", "Único superviviente de una expedición de tramperos sepultada en el Paso del Aullido; conoce la anatomía de cada bestia del bosque.", "«La gente del pueblo me mira las manos manchadas y piensa que disfruto con el cuchillo. No saben lo que es pasar cuarenta días atrapado por un alud en las cumbres del norte, viendo apagarse a tu cuadrilla uno tras otro.\n\nAprendí a desollar y aprovechar hasta el último hueso y tendón porque el desperdicio en la frontera se paga con la muerte. Aquí cada corte mío mantiene vivo al valle.»", "«El Dr. Valen acude a veces por la puerta trasera cuando cierro la carnicería. No busca carne para cenar: me pide huesos limpios y articulaciones para sus estudios anatómicos en la Morgue. Yo no hago preguntas, y él me cose cuando un jabalí me embiste en el bosque.»"],
	"Lina": ["lina", "Cartógrafa autodidacta y maestra curtidora llegada de las estepas de sal; traza mapas de las sendas de caza en el reverso del cuero.", "«Antes de instalarme en el valle con mi hermano Garrick, viajaba con las caravanas que cruzaban los pantanos orientales. Allí aprendí que un buen jubón de cuero curado con corteza de roble salva más vidas que una coraza pesada que te hunde en el barro.\n\nEn los recortes de piel que descarto llevo el mapa de las manadas del bosque sur: sé cuándo escasean los ciervos y cuándo bajan los zorros hambrientos hacia los corrales.»", "«Todavía oigo a Garrick hablar entre sueños sobre el invierno en que perdió a su antigua cuadrilla en la montaña. Nunca pronuncia el nombre del explorador que los dejó atrás... pero siempre aprieta el cuchillo cuando Aldric entra en la taberna.»"],
	"Bram": ["bram", "Arquitecto gremial exiliado de la capital tras el derrumbe del Gran Teatro, donde un intendente corrupto sustituyó su roble por madera podrida.", "«Cada viga, cada puerta y cada umbral que ves en esta aldea pasó por mis manos. En la capital me cargaron la culpa cuando cedió la cúpula del teatro real: el intendente se embolsó el oro del roble curado y compró pino húmedo, pero fui yo quien pagó con su nombre.\n\nPor eso aquí levanto casas con muros de piedra y maderas que ni un vendaval ni una patrulla puedan derribar sin sudar sangre.»", "«Le diseñé a cada edificio del pueblo un postigo lateral con bisagras ocultas. Llámalo manía de un constructor que conoció los calabozos de la corte: nunca me gustó levantar cuatro paredes de las que un hombre acorralado no pudiera escapar.»"],
	"Mila": ["mila", "Ebanista de precisión y maestra cerrajera; vendió sus herramientas de plata en la ciudad para pagar la fianza de su hermano Bram.", "«Bram levanta paredes; yo me ocupo de lo que guarda secretos: cerraduras de muelle, cofres de doble fondo y muebles ensamblados sin un solo clavo.\n\nEn la capital tallaba clavicordios para la nobleza, pero cuando hundieron a mi hermano en aquel juicio amañado, malvendí mi taller para sacarlo de la celda y vinimos a empezar de cero entre los pinos.»", "«Todos los cofres domésticos de las casas del pueblo llevan mi sello. Tienen un fiador interno que cede en silencio si te acercas agachado y con pulso firme... pero si alguien intenta abrirlos a plena vista, el trinquete suena como una campana.»"],
	"Marlo": ["marlo", "Antiguo timonel del bergantín contrabandista 'La Estrella Hundida'; cambió el mar abierto por el sosiego del lago y la rueda del molino.", "«Este aro de oro en mi oreja es lo único que saqué a flote cuando *La Estrella Hundida* se partió contra los escollos del Cabo Gris. Navegué quince años burlando bloqueos navales con sacos de trigo y barriles de pólvora.\n\nCuando la resaca me escupió en la playa, juré que no volvería a echar el ancla en aguas donde no pudiera ver la otra orilla. Ahora el rumor del molino y las truchas del lago me bastan.»", "«En las mañanas de niebla cerrada, cuando bajo al muelle antes de las siete, he visto fogatas apagándose hacia la Ciénaga de las Ranas. Esos bandidos de las ruinas no acampan ahí por azar: desentierran conductos del viejo mundo.»"],
	"Nora": ["nora", "Redera y cronista silenciosa del valle; registra en nudos marineros de cáñamo los movimientos y ausencias de cada habitante.", "«Mi padre Marlo me enseñó el código de cuerdas que usaban los contrabandistas del sur para llevar bitácoras sin escribir una sola letra que pudiera incriminarlos.\n\nMientras remiendo las redes frente a la pescadería, mis dedos atan nudos por cada persona que cruza la plaza. La gente cree que solo miro secarse el lino, pero sé quién duerme en su cama y quién camina de noche.»", "«Hace tres noches vi a Sora, la forastera de la posada, medir los pasos entre la parte trasera de la herrería y el camino del este. Juega a parecer una simple apostadora, pero calcula las rutas de salida mejor que el propio guardia.»"],
	"Elena": ["elena", "Ex-catedrática del Colegio Botánico de Ámbar; quemó sus tratados y huyó cuando el consejo militar quiso convertir sus sedantes en venenos.", "«La diferencia entre un bálsamo que devuelve el aliento y un alcaloide que apaga la memoria es apenas media gota en el alambique. En la academia de Ámbar pretendían que mis destilados de espora azul se usaran en los interrogatorios de Estado.\n\nQuemé mis notas esa misma madrugada, recogí mis semillas madre y vine con Tomás a este valle, donde mis cataplasmas solo sirven para cerrar heridas.»", "«Mi Somnífero Nocturno está destilado con raíz de sueño y hongos de los claros del sur. Si algún día necesitas silenciar a un testigo o dormir a un centinela sin mancharte las manos de sangre, cuarenta segundos de mi frasco bastan para cruzar cualquier puerta.»"],
	"Tomás": ["tomas", "Agrónomo paciente y estudioso del microclima del valle; logró fertilizar las tierras ácidas de la frontera mezclando ceniza de forja y compost.", "«Cuando Elena y yo llegamos, esta tierra era grava fría donde ni el cardo agarraba. Tardé tres años mezclando escoria mineral de la fragua de Thoran con mantillo de hojas del bosque hasta lograr que las coles y el trigo dieran cosechas dobles.\n\nLa tierra es como la gente del pueblo: si la fuerzas con hierro se cierra, pero si entiendes su ciclo te alimenta toda la vida.»", "«He estudiado las lluvias de este valle durante años: cuando cae el aguacero, no solo riega cada surco sin esfuerzo, sino que el golpeteo del agua sobre los tejados apaga el sonido de las pisadas en toda la aldea.»"],
	"Marta": ["marta", "Dama de hierro de 'El Jabalí Dorado'; ganó la escritura de la Posada hace diez años en una mano legendaria de póker contra un barón minero.", "«Muchos entran por mi estofado campesino o por el pollo recién asado, pero el verdadero corazón de esta casa late sobre el paño verde del salón. Antes de que llegaran el médico y el comisario, esta posada era una posta sin ley donde se apostaban minas enteras.\n\nLe gané la propiedad de este edificio a su antiguo dueño con un full de ases a medianoche. Desde entonces puse dos reglas sagradas: aquí dentro nadie pasa hambre si tiene moneda, y mientras las cartas están en la mesa hasta el tiempo parece detenerse.»", "«Desde la barra veo cómo respira cada jugador en el casino: hay quien parpadea de más por puro nervio aunque lleve escalera, y quien mantiene rostro de piedra con un dos y un siete. Aprende a leer a la persona, no solo sus cartas.»"],
	"Dr. Valen": ["valen", "Cirujano de mente analítica expulsado del anfiteatro médico de la capital por practicar autopsias forenses prohibidas por la nobleza.", "«En los salones de la capital, la medicina consistía en adular a duques hipocondríacos mientras prohibían abrir un cuerpo para investigar un asesinato. Yo vine a la frontera porque aquí la verdad no se esconde tras cortinas de seda.\n\nHe dividido mi hospital en dos mundos: en la sala norte salvo a todo aquel que aún conserve un hilo de pulso; en las losas de la Morgue del sur, dejo que las heridas y el rigor mortis dicten sentencia.»", "«Mis bisturíes pueden determinar el arma exacta y cuántas horas o días lleva un cuerpo descomponiéndose, pero la ciencia forense tiene un límite: sin un testigo que te haya visto entrar o salir del edificio, el expediente quedará como un crimen perfecto sin autor.»"],
	"Comisario Vane": ["vane", "Veterano inspector de frontera que perdió el ojo izquierdo en el motín de Cima Quebrada; aplica la ley con pragmatismo implacable.", "«Dejé los tribunales del norte porque me cansé de colgar a hambrientos mientras los intendentes robaban a manos llenas. En mi comisaría la ley no distingue cunas: si cometes un delito a la vista de un vecino o las pruebas de la Morgue te señalan, te doy la oportunidad de rendirte o pagar tu deuda.\n\nSi entregas las manos, te escolto vivo a la celda y al cantar el gallo sales libre. Pero si desenfundas contra mis hombres, mi revólver habla primero.»", "«Cuando sube el número de robos o aparecen cadáveres sin resolver, ordeno a todas las familias que echen la llave temprano y cierren los postigos. Un pueblo asustado es un pueblo cerrado a cal y canto.»"],
	"Guardia Rodric": ["rodric", "Joven centinela cuya granja familiar en la Llanura Oeste fue arrasada por los bandidos; patrulla las calles para que la historia no se repita.", "«¿Ves las ruinas de piedra al noroeste de la ciénaga? Ese era el granero de mis padres antes de que llegara la banda del oeste. Yo tenía doce años cuando escapamos hacia este valle.\n\nEl Comisario Vane me dio un yelmo y una porra reglamentaria, y me enseñó a mirar los callejones antes de doblar cada esquina. Mientras yo haga la ronda, nadie volverá a quemar una casa en esta aldea.»", "«Los muros de piedra y las puertas cerradas nos impiden ver lo que ocurre dentro de los locales desde la calle. Por eso cuando la niebla baja del bosque, redoblamos la atención en las entradas.»"],
	"Aldric": ["aldric", "Ex-batidor militar reconvertido en buscador de reliquias y jugador de ventaja; espera la ocasión de hacerse con un taller propio.", "«Llevo el broche de mi antiguo regimiento escondido bajo la capa porque en las fronteras hacer demasiadas preguntas sobre el pasado acorta la vida. Oficialmente soy un huésped más de la posada que vive de sus ahorros y de alguna buena racha al blackjack.\n\nEn realidad, exploro las ruinas del oeste buscando piezas del viejo mundo... aunque si algún gremio del pueblo queda vacante, tengo manos de sobra para tomar el relevo.»", "«He visto cómo funcionan los negocios aquí: cuando un taller sufre un 'accidente' en su maquinaria y se queda sin género, los precios se disparan al doble y el dueño está tan desesperado que vendería la escritura por un puñado de monedas.»"],
	"Sora": ["sora", "Tahúr de los barcos fluviales del sur y tasadora de arte; se refugió en el valle tras vaciarle los bolsillos al magistrado de Puerto Real.", "«En los salones flotantes del río Grande aprendí dos cosas: nunca apuestes contra quien reparte si no has contado las cartas que ya salieron, y nunca te quedes en la misma ciudad después de ganarle el carruaje a un juez.\n\nEste valle parecía un escondite aburrido al principio, pero entre las intrigas de las cinco familias y la mesa de Marta, te aseguro que aquí se mueve más oro del que aparentan sus calles de tierra.»", "«Si te conviertes en socio o dueño de una tienda del pueblo y abasteces tú mismo el mostrador, cada vez que los vecinos vayan a cenar estarás llenando tu propia caja registradora sin mover un dedo.»"],
	"Darío": ["dario", "Antiguo capataz de cantera despedido por priorizar la vida de sus mineros sobre la cuota de extracción; busca un oficio digno en el pueblo.", "«Treinta hombres salieron vivos del pozo de Peñanegra gracias a que di la campana de evacuación diez minutos antes de que reventara la bóveda de agua. La compañía minera me agradeció el gesto poniéndome en la calle por 'pérdida de herramientas'.\n\nAhora alquilo una cama en el ala norte de la posada. No me asusta el trabajo duro: el día que falte un maestro en cualquier taller de la aldea, yo mismo levantaré el oficio.»", "«Los maestros artesanos salen al bosque cada mañana a las 06:30 en punto a talar, picar o cazar su materia prima. Pero si la fauna o los árboles bajan del límite de equilibrio del bosque, regresan con las manos vacías y sus tiendas entran en escasez.»"],
	"Maese Casimir": ["casimir", "Intendente de la Liga Minera del Norte; porta un Salvoconducto Real para cruzar la frontera una vez por semana y comprar herramientas manufacturadas.", "«Este valle parece el fin del mundo, pero el hierro y la madera curada que trabajan Thoran y Bram superan con creces lo que sale de las fundiciones reales. Cada semana cruzo el Paso del Sur con escolta en la frontera y mi Salvoconducto Real lacrado en el pecho.\n\nSolo compro lo que realmente necesito: herramientas, lingotes, bobinas y tablones para las minas del norte. Sin el oro que inyecto en vuestros talleres, esta aldea acabaría devorándose a sí misma.»", "«Nadie sale de esta región sin un Salvoconducto Real firmado por la Cancillería. Pero cuidado con codiciar mi sello: si un intendente de la Corona desaparece en este valle, la capital suspenderá las rutas durante un mes entero y enviará al Inquisidor Real.»"],
	"Valeria la Tratante": ["valeria", "Tratante de Caza y Pieles de las Tierras Reales; acude una vez por semana con Salvoconducto Real a comprar legalmente pieles y carne del valle.", "«En las Tierras Reales del norte cazar un ciervo o un zorro se paga con la horca: todos los bosques pertenecen a la Corona. Pero como esta región está tan apartada y a la capital le cuesta demasiado enviar suministros, el Rey hace la vista gorda y os permite cazar para sobrevivir.\n\nPor eso vengo cada semana con mi Salvoconducto Real: aquí compro legalmente vuestras pieles, astas, cueros y piezas de caza para revenderlas a precio de oro en los salones de extramuros.»", "«Traigo conmigo Conservas Reales de Extramuros que no se pudren jamás. Nunca gasto todo mi oro de golpe: compro solo las pieles y carnes que están bien cortadas; los despieces torpes de aficionados no valen ni el barro que pisan.»"],
	"Inquisidor Real Alistair": ["alistair", "Alto Magistrado e Inquisidor de la Corona; enviado desde la capital para hallar y condenar a un culpable tras el asesinato de un mercader real.", "«No soy un comisario rural como Vane. Cuando un portador de Salvoconducto Real cae asesinado en la frontera, la Cancillería me envía con plenos poderes de vida y muerte.\n\nInterrogo a cada vecino, cruzo coartadas hora por hora, examino las heridas forenses y registro quién merodeaba la escena. Y ten algo muy claro, forastero: un Inquisidor Real jamás regresa a la capital con las manos vacías. Cuando termine mi expediente, alguien pagará con su cuello.»", "«Mi filosofía es el orden absoluto de la Corona: si las pruebas señalan sin duda al asesino, lo ejecutaré yo mismo; pero si el verdadero criminal ocultó sus rastros, condenaré al aldeano sin coartada que acumule mayor probabilidad. La Corona exige un culpable, no excusas.»"],
}

const INITIAL_NPC_RELATIONS: Dictionary = {
	"Thoran|Bram": [58, "Socios gremiales de forja y aserradero"],
	"Thoran|Comisario Vane": [52, "Veteranos del asedio de Cima Quebrada"],
	"Thoran|Tomás": [45, "Intercambio de ceniza de forja para la huerta"],
	"Thoran|Garrick": [-34, "Discusiones por el humo de la fragua y el precio de los cuchillos"],
	"Kael|Aldric": [48, "Trato secreto de reliquias y bobinas antiguas"],
	"Kael|Nora": [42, "Amigos de juventud en la plaza"],
	"Kael|Guardia Rodric": [-28, "Rodric sospecha de sus incursiones nocturnas"],
	"Garrick|Dr. Valen": [55, "Suministro discreto de huesos para estudios anatómicos"],
	"Garrick|Marlo": [-46, "Rivalidad comercial entre Carnicería y Pescadería"],
	"Garrick|Aldric": [-56, "Rencor del Paso del Aullido: sospecha de su pasado"],
	"Garrick|Elena": [-30, "Choque entre cazador implacable y botánica pacífica"],
	"Lina|Mila": [46, "Artesanas aliadas (Cuero curtido y ebanistería)"],
	"Lina|Aldric": [-38, "Desconfía de él por el trauma de Garrick"],
	"Bram|Darío": [48, "Respeto mutuo entre constructores y mineros"],
	"Bram|Comisario Vane": [-26, "Recelo hacia los tribunales por su antiguo exilio"],
	"Mila|Sora": [44, "Confidencias sobre cerraduras y nobles de la capital"],
	"Marlo|Marta": [50, "Viejos amigos de taberna y suministro de pescado"],
	"Nora|Sora": [-36, "Nora vigila sus pasos nocturnos en su bitácora de nudos"],
	"Elena|Dr. Valen": [62, "Colaboración médica entre la Botica y el Hospital"],
	"Tomás|Marlo": [44, "Intercambio de grano y abono en el molino"],
	"Marta|Darío": [42, "Huésped honrado de la Posada El Jabalí"],
	"Marta|Sora": [-32, "Tensión en el casino por contar cartas en el Blackjack"],
	"Comisario Vane|Guardia Rodric": [74, "Mentor y centinela leal de la Guardia del Valle"],
	"Comisario Vane|Dr. Valen": [56, "Cooperación forense en autopsias e investigaciones"],
	"Comisario Vane|Aldric": [-35, "Bajo vigilancia policial por contrabando de ruinas"],
	"Comisario Vane|Sora": [-30, "Sospechosa de desplumar viajeros en el río Grande"],
	"Guardia Rodric|Darío": [38, "Compañeros de patrulla y guardia vecinal"],
	"Aldric|Sora": [52, "Cómplices de apuestas en la mesa de la posada"],
	"Aldric|Darío": [-40, "Choque entre buscavidas oportunista y capataz honrado"],
}

## Tabla de fichas de persona (PersonProfile) para los 17 residentes iniciales (+ 3 visitantes reales).
## Reparto residente: 6 mujeres (Lina, Mila, Nora, Elena, Marta, Sora) y 11 hombres.
## Todos empiezan solteros en B0.2; la pareja inicial Elena + Dr. Valen se activa en B0.8.
const INITIAL_PERSON_PROFILES: Dictionary = {
	"Thoran": {
		"person_id": "thoran", "gender": "M", "orientation": "H", "age": 52,
		"personality": ["Trabajador", "Orgulloso", "Honrado"],
		"likes": ["forja", "carne_asada"], "dislikes": ["cartas"],
		"favorite_item": "iron_ore", "romance_status": "single", "partner_id": ""
	},
	"Kael": {
		"person_id": "kael", "gender": "M", "orientation": "H", "age": 22,
		"personality": ["Curioso", "Noctámbulo", "Paciente"],
		"likes": ["reliquias", "forja"], "dislikes": ["silencio"],
		"favorite_item": "bread", "romance_status": "single", "partner_id": ""
	},
	"Garrick": {
		"person_id": "garrick", "gender": "M", "orientation": "H", "age": 38,
		"personality": ["Valiente", "Desconfiado", "Rencoroso"],
		"likes": ["caza", "carne_asada"], "dislikes": ["historias"],
		"favorite_item": "fox_pelt", "romance_status": "single", "partner_id": ""
	},
	"Lina": {
		"person_id": "lina", "gender": "F", "orientation": "H", "age": 34,
		"personality": ["Leal", "Paciente", "Curioso"],
		"likes": ["caza", "animales"], "dislikes": ["cartas"],
		"favorite_item": "roasted_chicken", "romance_status": "single", "partner_id": ""
	},
	"Bram": {
		"person_id": "bram", "gender": "M", "orientation": "H", "age": 41,
		"personality": ["Trabajador", "Honrado", "Desconfiado"],
		"likes": ["carpinteria", "estofado"], "dislikes": ["reliquias"],
		"favorite_item": "wood", "romance_status": "single", "partner_id": ""
	},
	"Mila": {
		"person_id": "mila", "gender": "F", "orientation": "H", "age": 33,
		"personality": ["Paciente", "Leal", "Curioso"],
		"likes": ["carpinteria", "musica"], "dislikes": ["caza"],
		"favorite_item": "country_stew", "romance_status": "single", "partner_id": ""
	},
	"Marlo": {
		"person_id": "marlo", "gender": "M", "orientation": "H", "age": 54,
		"personality": ["Paciente", "Alegre", "Bondadoso"],
		"likes": ["pesca", "historias"], "dislikes": ["forja"],
		"favorite_item": "night_catfish", "romance_status": "single", "partner_id": ""
	},
	"Nora": {
		"person_id": "nora", "gender": "F", "orientation": "H", "age": 23,
		"personality": ["Paciente", "Desconfiado", "Noctámbulo"],
		"likes": ["pescado", "silencio"], "dislikes": ["cartas"],
		"favorite_item": "cooked_fish", "romance_status": "single", "partner_id": ""
	},
	"Elena": {
		"person_id": "elena", "gender": "F", "orientation": "H", "age": 36,
		"personality": ["Pacífico", "Bondadoso", "Curioso"],
		"likes": ["hierbas", "lluvia"], "dislikes": ["caza"],
		"favorite_item": "herbs", "romance_status": "single", "partner_id": ""
	},
	"Tomás": {
		"person_id": "tomas", "gender": "M", "orientation": "H", "age": 39,
		"personality": ["Paciente", "Trabajador", "Pacífico"],
		"likes": ["lluvia", "hierbas"], "dislikes": ["cartas"],
		"favorite_item": "bread", "romance_status": "single", "partner_id": ""
	},
	"Marta": {
		"person_id": "marta", "gender": "F", "orientation": "H", "age": 44,
		"personality": ["Alegre", "Orgulloso", "Chismoso"],
		"likes": ["estofado", "cartas"], "dislikes": ["silencio"],
		"favorite_item": "roasted_chicken", "romance_status": "single", "partner_id": ""
	},
	"Dr. Valen": {
		"person_id": "valen", "gender": "M", "orientation": "H", "age": 40,
		"personality": ["Curioso", "Paciente", "Honrado"],
		"likes": ["hierbas", "silencio"], "dislikes": ["cartas"],
		"favorite_item": "surgical_kit", "romance_status": "single", "partner_id": ""
	},
	"Comisario Vane": {
		"person_id": "vane", "gender": "M", "orientation": "H", "age": 55,
		"personality": ["Honrado", "Valiente", "Frío"],
		"likes": ["carne_asada", "silencio"], "dislikes": ["cartas"],
		"favorite_item": "cooked_meat", "romance_status": "single", "partner_id": ""
	},
	"Guardia Rodric": {
		"person_id": "rodric", "gender": "M", "orientation": "H", "age": 24,
		"personality": ["Leal", "Valiente", "Honrado"],
		"likes": ["pan_caliente", "animales"], "dislikes": ["reliquias"],
		"favorite_item": "bread", "romance_status": "single", "partner_id": ""
	},
	"Aldric": {
		"person_id": "aldric", "gender": "M", "orientation": "H", "age": 35,
		"personality": ["Tahúr", "Codicioso", "Noctámbulo"],
		"likes": ["reliquias", "cartas"], "dislikes": ["silencio"],
		"favorite_item": "cooked_meat", "romance_status": "single", "partner_id": ""
	},
	"Sora": {
		"person_id": "sora", "gender": "F", "orientation": "H", "age": 28,
		"personality": ["Tahúr", "Alegre", "Curioso"],
		"likes": ["cartas", "musica"], "dislikes": ["lluvia"],
		"favorite_item": "roasted_chicken", "romance_status": "single", "partner_id": ""
	},
	"Darío": {
		"person_id": "dario", "gender": "M", "orientation": "H", "age": 42,
		"personality": ["Honrado", "Trabajador", "Bondadoso"],
		"likes": ["estofado", "forja"], "dislikes": ["cartas"],
		"favorite_item": "country_stew", "romance_status": "single", "partner_id": ""
	},
	"Maese Casimir": {
		"person_id": "casimir", "gender": "M", "orientation": "H", "age": 48,
		"personality": ["Orgulloso", "Trabajador", "Desconfiado"],
		"likes": ["forja", "carpinteria"], "dislikes": ["lluvia"],
		"favorite_item": "royal_ration", "romance_status": "single", "partner_id": ""
	},
	"Valeria la Tratante": {
		"person_id": "valeria", "gender": "F", "orientation": "H", "age": 37,
		"personality": ["Orgulloso", "Curioso", "Valiente"],
		"likes": ["caza", "carne_asada"], "dislikes": ["pescado"],
		"favorite_item": "royal_ration", "romance_status": "single", "partner_id": ""
	},
	"Inquisidor Real Alistair": {
		"person_id": "alistair", "gender": "M", "orientation": "H", "age": 51,
		"personality": ["Frío", "Orgulloso", "Rencoroso"],
		"likes": ["silencio", "historias"], "dislikes": ["cartas"],
		"favorite_item": "royal_ration", "romance_status": "single", "partner_id": ""
	},
}


