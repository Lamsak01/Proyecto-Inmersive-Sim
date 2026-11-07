extends RefCounted

## Tablas de datos puros de los habitantes del valle (alias, perfiles de personaje y relaciones iniciales).
## Separadas de VillageNPC.gd para mantener ese script más corto. VillageNPC las re-expone como constantes con el mismo nombre.

const NPC_NAME_ALIASES: Dictionary = {
	"Dra. Valeria": "Dr. Valen", "Dr. Silvano": "Dr. Valen",
	"Comisario Thorne": "Comisario Vane", "Inspectora Lyra": "Comisario Vane",
	"Guardia Kaelen": "Guardia Rodric", "Centinela Bastian": "Guardia Rodric",
	"Aldeano Guía": "Vigía del Oeste", "Guarda Fronterizo": "Vigía del Oeste",
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
	"Hermano Anselmo": ["guia", "Sacerdote de la Fe del Alba; llegó al valle con un carro de libros y se quedó cuando vio que nadie cuidaba de los muertos.", "«Antes de venir aquí recorrí aldeas donde la capilla estaba cerrada y el cementerio comido por la hierba. Aquí al menos hay gente que todavía se saluda al cruzarse.\n\nNo pido que todos crean. Pido que el domingo, quien quiera, venga a compartir un rato y un pedazo de pan.»", "«Escucho mucho, ¿sabes? La gente viene a la capilla a contar lo que no se atreve a decir en la taberna.»"],
	"Comisario Vane": ["vane", "Veterano inspector de frontera que perdió el ojo izquierdo en el motín de Cima Quebrada; aplica la ley con pragmatismo implacable.", "«Dejé los tribunales del norte porque me cansé de colgar a hambrientos mientras los intendentes robaban a manos llenas. En mi comisaría la ley no distingue cunas: si cometes un delito a la vista de un vecino o las pruebas de la Morgue te señalan, te doy la oportunidad de rendirte o pagar tu deuda.\n\nSi entregas las manos, te escolto vivo a la celda y al cantar el gallo sales libre. Pero si desenfundas contra mis hombres, mi revólver habla primero.»", "«Cuando sube el número de robos o aparecen cadáveres sin resolver, ordeno a todas las familias que echen la llave temprano y cierren los postigos. Un pueblo asustado es un pueblo cerrado a cal y canto.»"],
	"Guardia Rodric": ["rodric", "Joven centinela cuya granja familiar en la Llanura Oeste fue arrasada por los bandidos; patrulla las calles para que la historia no se repita.", "«¿Ves las ruinas de piedra al noroeste de la ciénaga? Ese era el granero de mis padres antes de que llegara la banda del oeste. Yo tenía doce años cuando escapamos hacia este valle.\n\nEl Comisario Vane me dio un yelmo y una porra reglamentaria, y me enseñó a mirar los callejones antes de doblar cada esquina. Mientras yo haga la ronda, nadie volverá a quemar una casa en esta aldea.»", "«Los muros de piedra y las puertas cerradas nos impiden ver lo que ocurre dentro de los locales desde la calle. Por eso cuando la niebla baja del bosque, redoblamos la atención en las entradas.»"],
	"Vigía del Oeste": ["guia", "Guarda fronterizo veterano apostado en el linde de la Llanura Salvaje; conoce cada rastro de bandidos y bestias del paso occidental.", "«Llevo siete inviernos guardando esta empalizada entre las granjas y la Llanura Salvaje. Los que viven plaza adentro duermen tranquilos porque alguien se queda aquí fuera escuchando cómo crujen las cañas de la ciénaga.\n\nSé distinguir la pisada de un ciervo herido de la bota claveteada de un salteador antes de que asome entre la niebla.»", "«No todos los que cruzan hacia las ruinas del noroeste son bandidos forasteros. Más de una noche he visto linternas tapadas con trapo saliendo desde las casas del propio pueblo.»"],
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
	"Elena|Dr. Valen": [78, "Pareja y estrechos colaboradores entre la Botica y el Hospital"],
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
	"Hermano Anselmo|Elena": [54, "Cuidado mutuo de enfermos y necesitados del valle"],
	"Hermano Anselmo|Tomás": [48, "Reparto dominical de pan y hortalizas en la capilla"],
	"Hermano Anselmo|Marlo": [42, "Charlas tranquilas sobre viejos naufragios y redención"],
	"Hermano Anselmo|Aldric": [-44, "Anselmo recela de sus sermones nocturnos y reliquias prohibidas"],
	"Hermano Anselmo|Inquisidor Real Alistair": [-38, "Choque entre la misericordia parroquial y el patíbulo de la Corona"],
	"Vigía del Oeste|Guardia Rodric": [62, "Compañeros de guardia en el linde occidental"],
	"Vigía del Oeste|Comisario Vane": [54, "Informes diarios de rastros en la Llanura Salvaje"],
	"Vigía del Oeste|Lina": [46, "Intercambio de mapas de sendas y avisos de manadas"],
	"Vigía del Oeste|Aldric": [-48, "Lo ha visto volver de las ruinas con farol tapado de madrugada"],
	"Vigía del Oeste|Kael": [-32, "Le ha confiscado chatarra sacada de la zona prohibida"],
	"Maese Casimir|Thoran": [52, "Respeto por su acero templado, pese a viejas sospechas imperiales"],
	"Maese Casimir|Bram": [48, "Compra semanal de vigas y cajas de roble curado"],
	"Maese Casimir|Darío": [-52, "Casimir representa a la Liga Minera que despidió a Darío en Peñanegra"],
	"Maese Casimir|Sora": [-36, "Teme sus manos largas cerca de los cofres de la caravana"],
	"Valeria la Tratante|Garrick": [56, "Su mejor proveedor de pieles limpias y piezas de caza mayor"],
	"Valeria la Tratante|Lina": [50, "Admiración por sus jubones curtidos y mapas del bosque"],
	"Valeria la Tratante|Elena": [-34, "Desprecia los escrúpulos de la boticaria contra la caza intensiva"],
	"Valeria la Tratante|Marlo": [-28, "Se niega a transportar pescado fresco en sus carros de pieles"],
	"Inquisidor Real Alistair|Comisario Vane": [-42, "Desprecia la blandura fronteriza de Vane con los desertores"],
	"Inquisidor Real Alistair|Dr. Valen": [-48, "Recuerda su expulsión del anfiteatro médico de la capital"],
	"Inquisidor Real Alistair|Bram": [-50, "Conoce el expediente judicial del derrumbe del Gran Teatro"],
	"Inquisidor Real Alistair|Maese Casimir": [58, "Protección oficial de la Cancillería a los intendentes reales"],
}

## Variantes de relaciones y rencores que se sortean al arrancar cada partida para que el Día 1 nunca sea idéntico.
const FOUNDER_RELATION_VARIANTS: Array = [
	{"pair": "Thoran|Kael", "delta": -18, "note": "Tensión paterna por encender la fragua a escondidas de madrugada"},
	{"pair": "Garrick|Comisario Vane", "delta": -24, "note": "Vane investiga trampas ilegales halladas cerca del camino real"},
	{"pair": "Marta|Aldric", "delta": -28, "note": "Deuda pendiente de naipes y sospecha de dados cargados en el salón", "debt_from": "aldric", "debt_to": "marta"},
	{"pair": "Bram|Thoran", "delta": -22, "note": "Disputa gremial por el precio del carbón y los herrajes de obra"},
	{"pair": "Nora|Kael", "delta": 18, "note": "Cómplices nocturnos: Nora cubre sus salidas hacia las ruinas"},
	{"pair": "Sora|Guardia Rodric", "delta": -26, "note": "Rodric vigila de cerca sus partidas de póker con forasteros"},
	{"pair": "Dr. Valen|Hermano Anselmo", "delta": -24, "note": "Roces entre las autopsias de la Morgue y el descanso cristiano del cementerio"},
	{"pair": "Darío|Thoran", "delta": 22, "note": "Alianza de antiguos mineros contra los abusos de la Corona", "debt_from": "dario", "debt_to": "thoran"},
	{"pair": "Lina|Nora", "delta": 24, "note": "Intercambio secreto de mapas del bosque y bitácoras de nudos"},
	{"pair": "Elena|Marta", "delta": -20, "note": "Discusión por vender licor fuerte a vecinos recién cosidos en el hospital"},
]

## Piscina de secretos personales (3–4 por fundador). Al empezar cada partida se eligen 2 o 3 al azar por vecino.
const FOUNDER_SECRETS_POOL: Dictionary = {
	"Thoran": [
		{"id": "thoran_deserter", "title": "Desertor de Vaelgard", "text": "Deserto de la Fundición Imperial tras sabotear un crisol militar; si el Inquisidor Alistair confirma su verdadero nombre, pesa sobre él una orden de horca.", "rumor": "Dicen que el herrero Thoran no se llamaba así en el norte y que huyó de un consejo de guerra imperial.", "witness": "vane"},
		{"id": "thoran_weapons_cache", "title": "Alijo de hojas sin marca", "text": "Guarda bajo el carbón de la fragua tres hojas de acero militar sin punzón real, listas por si la Corona intenta tomar el valle por la fuerza.", "rumor": "Cuentan que Thoran esconde espadas de guerra sin sello real bajo el piso de la herrería.", "witness": "bram"},
		{"id": "thoran_crippled_hand", "title": "Temblor en el pulso", "text": "El humo de plomo de su juventud le adormece dos dedos al amanecer; teme que el pueblo lo note y lo jubilen antes de que Kael domine el oficio.", "rumor": "Se comenta en voz baja que a Thoran le falla el pulso por las mañanas y que Elena le prepara friegas en secreto.", "witness": "elena"},
	],
	"Kael": [
		{"id": "kael_ancient_coils", "title": "Contrabando de bobinas antiguas", "text": "Compra reliquias y bobinas prohibidas del viejo mundo a Aldric usando carbón y lingotes sustraídos del taller de su padre.", "rumor": "Dicen que Kael saca lingotes de la herrería de noche para pagarle reliquias raras a Aldric.", "witness": "aldric"},
		{"id": "kael_ruins_tunnels", "title": "Entrada sellada en la cantera", "text": "Encontró una galería metálica sellada detrás de la Cantera del Noroeste y acude de madrugada con ganzúas para intentar abrir su compuerta.", "rumor": "Alguien vio a Kael volver de la cantera antes del alba con las manos manchadas de aceite antiguo.", "witness": "nora"},
		{"id": "kael_forged_seal", "title": "Molde de sello gremial", "text": "Ensayó en arcilla una copia del punzón gremial de su padre para vender herramientas por su cuenta a las caravanas.", "rumor": "Corren voces de que Kael ha estado vendiendo piezas forjadas a espaldas de Thoran.", "witness": "sora"},
	],
	"Garrick": [
		{"id": "garrick_howling_pass", "title": "La ración del Paso del Aullido", "text": "En los últimos días del alud en el Paso del Aullido ocultó la última tira de cecina bajo la nieve para sobrevivir cuando el guía los abandonó.", "rumor": "Susurran que Garrick no cuenta toda la verdad sobre cómo sobrevivió solo al alud del Paso del Aullido.", "witness": "lina"},
		{"id": "garrick_morgue_bones", "title": "Huesos para el anfiteatro", "text": "Entrega de madrugada piezas óseas y articulaciones limpias al Dr. Valen por la puerta trasera a cambio de suturas y silencio sobre sus cacerías furtivas.", "rumor": "Dicen que Garrick entra de noche por la puerta trasera de la Morgue con sacos que no son de venta.", "witness": "valen"},
		{"id": "garrick_poison_bait", "title": "Cebos en el linde del río", "text": "Echó despojos amargos río arriba para ahuyentar los bancos de truchas del muelle de Marlo tras una bronca por los precios de la plaza.", "rumor": "En la pescadería sospechan que Garrick ensució las aguas del muelle para hundir la pesca de Marlo.", "witness": "marlo"},
	],
	"Lina": [
		{"id": "lina_smuggler_maps", "title": "Sendas ocultas en cuero", "text": "En el reverso de ciertos jubones de encargo cose mapas detallados de los pasos de montaña que permiten cruzar la frontera sin pasar por el control real.", "rumor": "Dicen que los forros de cuero de Lina llevan cosidos mapas de pasos clandestinos hacia el norte.", "witness": "mila"},
		{"id": "lina_aldric_regiment", "title": "El broche del batidor", "text": "Reconoció el broche militar que Aldric esconde bajo la capa: pertenece al mismo destacamento de exploradores que dejó tirada a la cuadrilla de Garrick.", "rumor": "Lina calla lo que descubrió sobre el pasado militar de Aldric para evitar que Garrick cometa una locura.", "witness": "nora"},
		{"id": "lina_royal_poaching", "title": "Pieles de las Tierras Reales", "text": "Algunas de las mejores pieles de zorro plateado que curte proceden de incursiones más allá del mojón real, donde cazar se paga con la soga.", "rumor": "Comentan que las pieles más finas del Colmillo vienen cazadas de tierras prohibidas de la Corona.", "witness": "valeria"},
	],
	"Bram": [
		{"id": "bram_secret_latches", "title": "Postigos y dobles fondos de obra", "text": "Instaló un resorte oculto en las vigas de varias casas y edificios municipales que permite abrir sus postigos desde fuera sin romper la tranca.", "rumor": "Se dice que Bram dejó pasos secretos en los planos de más de un edificio del pueblo.", "witness": "mila"},
		{"id": "bram_arson_testimony", "title": "El plano quemado de la capital", "text": "Conserva escondido en una viga hueca el albarán original firmado por el intendente real que robó el roble del Gran Teatro, por el cual la corte aún manda sicarios.", "rumor": "Dicen que Bram guarda un documento de la capital por el que ciertos nobles pagarían oro o sangre.", "witness": "thoran"},
		{"id": "bram_timber_tax", "title": "Tratos de madera sin declarar", "text": "Desvía uno de cada cinco tablones de roble viejo hacia obras privadas sin anotarlo en el libro gremial para rehacer el fondo familiar que perdieron en su juicio.", "rumor": "Rumorean que en el aserradero de Bram salen más tablones de noche de los que figuran en el libro.", "witness": "dario"},
	],
	"Mila": [
		{"id": "mila_master_keys", "title": "El molde de cera de las cerraduras", "text": "Guarda en una caja de música sin cuerda los moldes de cera de casi todos los cofres domésticos y municipales que fabricó para el valle.", "rumor": "Dicen que Mila conserva copia o molde de todas las cerraduras que han salido de su banco de ebanista.", "witness": "bram"},
		{"id": "mila_pawned_silver", "title": "Deuda con los usureros del sur", "text": "El prestamista que le adelantó el oro para la fianza de Bram en la capital ha enviado recado con las caravanas reclamando intereses atrasados.", "rumor": "Cuentan que a Mila le llegan cartas selladas en las caravanas reclamándole una vieja deuda de la ciudad.", "witness": "sora"},
		{"id": "mila_church_chalice_lock", "title": "El doble fondo del altar", "text": "Talló a petición del Hermano Anselmo un compartimento secreto bajo el altar de la capilla para esconder reliquias y limosnas en caso de saqueo.", "rumor": "Se comenta que Mila trabajó a puerta cerrada en la capilla haciendo un escondite que pocos conocen.", "witness": "anselmo"},
	],
	"Marlo": [
		{"id": "marlo_sunken_chest", "title": "El cofre hundido del juncal", "text": "Antes de llegar al valle lastró en el fondo fangoso del lago una caja embreada con doblones y cartas de corso de 'La Estrella Hundida'.", "rumor": "Dicen que Marlo no pesca solo truchas al amanecer: vigila algo que hundió en lo hondo del lago.", "witness": "nora"},
		{"id": "marlo_smuggler_lantern", "title": "Señales de farol en la niebla", "text": "En noches cerradas aún hace guiños de farol desde el muelle para avisar a los viejos arrieros contrabandistas si la guardia ronda el camino del este.", "rumor": "Alguien vio el farol del molino parpadear hacia el bosque las noches en que pasa contrabando.", "witness": "marta"},
		{"id": "marlo_mill_weights", "title": "La pesa limada del molino", "text": "Tiene una pesa de bronce ligeramente rebajada que usa solo cuando muele grano para mercaderes reales o nobles que regatean el jornal.", "rumor": "Murmuran que la báscula del molino de Marlo no pesa igual para los de fuera que para los vecinos.", "witness": "tomas"},
	],
	"Nora": [
		{"id": "nora_knot_ledger", "title": "El cordel negro de las rondas", "text": "Su bitácora de nudos marineros registra con hora exacta qué vecinos salen a las alcantarillas, quién visita el reservado y quién entra en casas ajenas de noche.", "rumor": "Dicen que las redes colgadas de Nora son en realidad un registro en clave de todo lo que pasa de noche en la plaza.", "witness": "marlo"},
		{"id": "nora_stolen_letters", "title": "Pliegos rescatados del correo", "text": "Pesca del desagüe y de las alforjas descuidadas borradores de cartas antes de que salgan con la caravana, guardando secretos de media aldea.", "rumor": "Sospechan que Nora sabe lo que escriben los viajeros de la posada antes de que las cartas crucen el paso.", "witness": "kael"},
		{"id": "nora_sora_watch", "title": "El escondite del puente", "text": "Descubrió dónde esconde Sora sus mazos marcados y ganzúas bajo las tablas del muelle, y le dejó un nudo de aviso sin delatarla a Vane.", "rumor": "Entre Nora y Sora hay una guerra muda de miradas desde que Nora encontró algo bajo el muelle.", "witness": "sora"},
	],
	"Elena": [
		{"id": "elena_blue_spore", "title": "El bulbo de espora azul", "text": "No quemó todas sus muestras del Colegio de Ámbar: oculta en una maceta de doble barro el bulbo madre del alcaloide que borra los recuerdos recientes.", "rumor": "Cuentan que Elena guarda bajo llave una planta prohibida de su antigua cátedra en la capital.", "witness": "tomas"},
		{"id": "elena_faked_death_draught", "title": "El brebaje del pulso muerto", "text": "Conoce la dosis exacta de raíz de sueño para enfriar el cuerpo y fingir la muerte durante seis horas, como hizo para sacar a un desertor de Ámbar.", "rumor": "Dicen que en la botica de Elena hay frascos capaces de hacer pasar a un vivo por difunto ante un juez.", "witness": "valen"},
		{"id": "elena_blackmail_silence", "title": "Recetas sin nombre", "text": "Atiende de noche y sin apuntar en el libro a vecinos heridos en peleas clandestinas o trabajos turbios para que el Comisario no los fiche.", "rumor": "Se sabe que más de un vecino con heridas raras acude de noche a la ventana trasera de Elena en vez del hospital.", "witness": "anselmo"},
	],
	"Tomás": [
		{"id": "tomas_marsh_mushrooms", "title": "Cultivo oculto en la ciénaga", "text": "Mantiene en un rincón húmedo tras la Ciénaga de las Ranas una cepa de hongos luminiscentes que vende en secreto para financiar semillas del huerto común.", "rumor": "Dicen que Tomás no solo recoge hierbas en la pradera: tiene un criadero escondido hacia la ciénaga.", "witness": "elena"},
		{"id": "tomas_sabotaged_survey", "title": "Los mojones movidos del valle", "text": "Hace dos otoños desenterró y movió tres mojones de piedra de la Corona durante una tormenta para que las tierras fértiles del sur quedaran fuera del coto real.", "rumor": "Cuentan los viejos que Tomás cambió de sitio los mojones reales una noche de aguacero para salvar las huertas.", "witness": "thoran"},
		{"id": "tomas_well_filter", "title": "Ceniza en el pozo viejo", "text": "Detectó filtraciones de mineral extraño en las vetas profundas bajo el valle y las neutraliza cada semana echando carbón activado en los pozos sin alarmar al pueblo.", "rumor": "Alguien ha visto a Tomás echar polvos oscuros en los pozos al amanecer, aunque él jura que es para limpiar el agua.", "witness": "marlo"},
	],
	"Marta": [
		{"id": "marta_marked_deck", "title": "El quinto as de aquella noche", "text": "El full de ases con el que le ganó la escritura de 'El Jabalí Dorado' al barón minero salió de una baraja marcada al humo que aún guarda bajo la tarima de la barra.", "rumor": "Dicen los tahúres que la mano legendaria con la que Marta ganó la posada tenía truco en el lomo de los ases.", "witness": "sora"},
		{"id": "marta_debt_ledger", "title": "El libro negro de las rondas", "text": "Debajo de la caja lleva una libreta con las deudas de juego y las confesiones de borrachera de media aldea, que usa para que nadie arme bronca en su salón.", "rumor": "En la taberna aseguran que Marta apunta en un cuaderno oculto lo que cada vecino suelta cuando bebe de más.", "witness": "marlo"},
		{"id": "marta_cellar_hatch", "title": "Vista gorda con el sótano", "text": "Sabe perfectamente lo que se organiza en las noches pares bajo las tablas de su taberna y cobra en silencio el desgaste de las velas y el piso.", "rumor": "Nadie cree que Marta no oiga los golpes que suben del sótano de la posada a medianoche.", "witness": "aldric"},
	],
	"Dr. Valen": [
		{"id": "valen_noble_autopsy", "title": "El expediente del duque de Ámbar", "text": "Fue expulsado de la capital porque su autopsia probó que el sobrino del Canciller murió envenenado por su propia familia; guarda las muestras lacradas en la Morgue.", "rumor": "Dicen que el Dr. Valen guarda en formol la prueba de un crimen de la alta nobleza por el que tuvo que huir.", "witness": "elena"},
		{"id": "valen_forbidden_grafts", "title": "Ensayos de articulaciones mecánicas", "text": "De madrugada ensaya en la Morgue engranajes de cobre antiguo con huesos suministrados por Garrick para diseñar prótesis articuladas que la academia declaró heréticas.", "rumor": "Se comenta que en la Morgue del Dr. Valen suenan herramientas de relojero a altas horas de la noche.", "witness": "garrick"},
		{"id": "valen_altered_certificate", "title": "Actas de defunción piadosas", "text": "Firmó como 'muerte natural por fiebre' el acta de dos fugitivos políticos hace años para librar a sus familias de la confiscación real.", "rumor": "Rumorean que el Dr. Valen ha cubierto algún secreto en sus actas forenses cuando la ley imperial apretaba demasiado.", "witness": "vane"},
	],
	"Hermano Anselmo": [
		{"id": "anselmo_unnamed_graves", "title": "Las tres tumbas sin nombre", "text": "En la esquina trasera del cementerio dio sepultura nocturna a tres desertores y proscritos cuyos nombres reales están anotados solo en el lomo interior de su breviario.", "rumor": "Dicen que en el Cementerio del Alba hay losas sin nombre cuyo verdadero dueño solo figura en el libro oculto de Anselmo.", "witness": "vane"},
		{"id": "anselmo_inquisition_past", "title": "La sotana quemada del norte", "text": "En su juventud fue escribano de un tribunal eclesiástico antes de aborrecer las hogueras y huir con un carro de libros prohibidos que esconde bajo la capilla.", "rumor": "Cuentan que el Hermano Anselmo sirvió hace décadas en los tribunales del norte antes de renegar de ellos.", "witness": "elena"},
		{"id": "anselmo_alms_diversion", "title": "Limosnas para los endeudados", "text": "Saca monedas del cepillo de los ricos antes de que pase el recaudador para dejarlas de noche en el alféizar de las familias que no llegan a pagar el pan.", "rumor": "Hay quien dice haber visto al Hermano Anselmo dejar monedas envueltas en trapo en las ventanas de los más pobres.", "witness": "tomas"},
	],
	"Comisario Vane": [
		{"id": "vane_burned_warrant", "title": "La requisitoria quemada de Thoran", "text": "Guarda en el fondo de su cajón la hebilla del cartel de búsqueda imperial de Thoran; quemó el pergamino al llegar al valle porque le debía la vida desde Cima Quebrada.", "rumor": "Susurran que el Comisario Vane rompió una orden de arresto real contra uno de los maestros fundadores del pueblo.", "witness": "thoran"},
		{"id": "vane_mutiny_command", "title": "La orden que no dio en Cima Quebrada", "text": "No perdió el ojo por un rebelde: se lo vació su propio capitán cuando Vane se negó a disparar la metralla contra las mujeres de los mineros amotinados.", "rumor": "Dicen que la cicatriz del Comisario Vane no se la hicieron los amotinados, sino sus propios oficiales en el norte.", "witness": "valen"},
		{"id": "vane_informant_deal", "title": "Soplones sin ficha", "text": "Hace la vista gorda con pequeños hurtos de comida o partidas de cartas si quien los comete le avisa cuando asoman bandidos o sicarios de la capital.", "rumor": "En la calle se dice que Vane perdona faltas menores a cambio de soplos sobre quién entra y sale del valle.", "witness": "rodric"},
	],
	"Guardia Rodric": [
		{"id": "rodric_bandit_brother", "title": "El apellido entre los bandidos", "text": "Su hermano mayor no murió cuando quemaron su granja en la Llanura Oeste: fue reclutado a la fuerza por los bandidos de las ruinas, y Rodric teme encontrárselo en una redada.", "rumor": "Dicen que Rodric tiembla cada vez que hay asalto porque entre los bandidos del oeste podría estar alguien de su propia sangre.", "witness": "vane"},
		{"id": "rodric_sleeping_watch", "title": "Cabezadas en la ronda del alba", "text": "Cuando dobla turno de madrugada tras patrullar la niebla, se sienta diez minutos a cubierto detrás de la panadería y le compra café de hierbas a Elena para no dormirse.", "rumor": "Cuentan que en la ronda de las cuatro de la mañana Rodric busca un rincón abrigado para vencer el sueño.", "witness": "nora"},
		{"id": "rodric_lost_evidence", "title": "El puñal del granero", "text": "Conserva sin registrar en la armería un puñal grabado que recogió de niño entre las cenizas de su granja, esperando reconocer algún día al cabecilla que lo empuñaba.", "rumor": "Se dice que Rodric guarda bajo su jergón el arma de quien quemó la granja de sus padres.", "witness": "dario"},
	],
	"Vigía del Oeste": [
		{"id": "vigia_bandit_toll", "title": "La tregua de la hoguera apagada", "text": "Hace dos inviernos dejó escapar a un explorador herido de las ruinas a cambio de que su banda no cruzara nunca el arroyo hacia los huertos del pueblo.", "rumor": "Dicen que el Vigía del Oeste pactó una vez en silencio con un herido de las ruinas para evitar una matanza en la linde.", "witness": "lina"},
		{"id": "vigia_hidden_pelt_stash", "title": "Trampas propias en el juncal", "text": "Caza por su cuenta alguna pieza menor en la linde de la ciénaga durante las guardias largas y la cambia por leña y vendajes sin pasar por el arca municipal.", "rumor": "Comentan que el Vigía del Oeste saca pieles y carne por su cuenta en los turnos tranquilos de la frontera.", "witness": "garrick"},
		{"id": "vigia_deserted_post", "title": "La torre que cayó en el norte", "text": "Antes de servir en esta aldea fue centinela en un paso real que cayó por culpa de un relevo borracho; cargó con la deshonra para salvar a su joven compañero.", "rumor": "Cuentan que el Vigía del Oeste fue degradado en otra frontera por cubrir el fallo de un compañero más joven.", "witness": "vane"},
	],
	"Aldric": [
		{"id": "aldric_howling_pass_scout", "title": "El batidor que cortó la cuerda", "text": "Fue el explorador contratado que guio a la expedición del Paso del Aullido y se marchó con los mapas del yacimiento cuando cayó el primer alud, dejando atrás a Garrick.", "rumor": "En voz muy baja se dice que Aldric estuvo en la montaña del Paso del Aullido el invierno en que se perdió la cuadrilla de Garrick.", "witness": "lina"},
		{"id": "aldric_loaded_dice", "title": "Plomo en los dados de hueso", "text": "Guarda en el forro de la bota un par de dados lastrados con mercurio y naipes marcados con resina que saca en la posada cuando los viajeros llevan demasiado oro.", "rumor": "En la mesa del Jabalí Dorado sospechan que la buena racha de Aldric sale del forro de sus botas.", "witness": "sora"},
		{"id": "aldric_forbidden_codex", "title": "El cuaderno del Sol Negro", "text": "En sus incursiones a las ruinas desenterró un códice de liturgias antiguas sobre un eclipse perpetuo y lo estudia a la luz de una vela en su cuarto de la posada.", "rumor": "Dicen que Aldric lee de noche unos pergaminos oscuros sacados de las bóvedas hundidas del oeste.", "witness": "kael"},
	],
	"Sora": [
		{"id": "sora_magistrate_ring", "title": "El anillo del magistrado de Puerto Real", "text": "Lleva cosido en el dobladillo del corsé el sello de rubí que le ganó —y hurtó al huir— al magistrado de Puerto Real, por el que aún hay cazarrecompensas preguntando en los caminos.", "rumor": "Cuentan que Sora esconde una joya con sello judicial por la que la buscan desde los puertos del sur.", "witness": "mila"},
		{"id": "sora_fake_passports", "title": "Firmas imitadas a la luz del candil", "text": "Tiene mano de calígrafa para imitar sellos de paso y albaranes de caravana; ha sacado de más de un apuro a deudores a cambio de una tajada.", "rumor": "Se dice que Sora sabe imitar la letra y las rúbricas de los escribanos reales con una pluma fina.", "witness": "aldric"},
		{"id": "sora_cased_shops", "title": "El croquis de los cerrojos", "text": "Anote en el reverso de una baraja vieja los horarios de ronda de Rodric y qué tiendas dejan la ventana sin tranca al ir a cenar a la taberna.", "rumor": "Nora asegura que Sora tiene medidos los pasos y horarios de cierre de media calle comercial.", "witness": "nora"},
	],
	"Darío": [
		{"id": "dario_mine_flood", "title": "El barreno que salvó a treinta", "text": "En la mina de Peñanegra no solo tocó la campana: voló él mismo la galería de carga de la Liga Minera para desviar el torrente de agua y que no ahogara a su cuadrilla.", "rumor": "Dicen que Darío hundió a propósito la galería rica de Peñanegra para que el agua no matara a sus mineros.", "witness": "bram"},
		{"id": "dario_widow_remittance", "title": "El sobre para las viudas del pozo", "text": "Vive con lo puesto en la posada porque envía la mitad de cada jornal que gana en el valle a las familias de los dos mineros que no lograron salir de Peñanegra.", "rumor": "Marta sabe que Darío apenas gasta en sí mismo porque manda casi todo su oro fuera del valle en secreto.", "witness": "marta"},
		{"id": "dario_casimir_grudge", "title": "La firma de Casimir en el despido", "text": "Reconoció a Maese Casimir como el intendente que firmó la orden de cerrar las compuertas con los obreros dentro; se contiene cada miércoles para no volcarle el carro.", "rumor": "Cuentan que Darío aprieta los puños cada vez que la caravana de Maese Casimir entra en la plaza.", "witness": "thoran"},
	],
	"Maese Casimir": [
		{"id": "casimir_skimmed_ingots", "title": "El doble fondo del carromato", "text": "Declara a la Liga Minera del Norte un veinte por ciento menos del hierro y bobinas que compra en el valle y revende el resto en el mercado libre de la frontera.", "rumor": "Susurran que Maese Casimir sisa lingotes y bobinas a su propio gremio antes de cruzar el Paso del Sur.", "witness": "thoran"},
		{"id": "casimir_bribed_seal", "title": "El Salvoconducto renovado con oro", "text": "Su Salvoconducto Real lleva el sello de un secretario sobornado de la Cancillería que le avisa con antelación de qué aranceles o embargos planea la corte.", "rumor": "Dicen que Casimir paga mordidas en la capital para enterarse antes que nadie de los decretos reales.", "witness": "valeria"},
		{"id": "casimir_mine_coverup", "title": "El informe oculto de Peñanegra", "text": "Ocultó el informe técnico que advertía de la bolsa de agua en la mina de Peñanegra para cobrar la prima de extracción antes del derrumbe.", "rumor": "Entre los antiguos mineros se dice que Casimir sabía que el pozo de Peñanegra iba a reventar y calló por la prima.", "witness": "dario"},
	],
	"Valeria la Tratante": [
		{"id": "valeria_royal_poachers", "title": "Cazadores furtivos a sueldo", "text": "Paga en secreto a tramperos de frontera para que abatan ciervos blancos dentro del coto vedado del Rey y los marquen como cazados en este valle libre.", "rumor": "Dicen que Valeria blanquea con su Salvoconducto pieles cazadas ilegalmente en los bosques privados del Rey.", "witness": "garrick"},
		{"id": "valeria_smuggled_toxins", "title": "Frascos entre las conservas", "text": "Debajo de las Conservas Reales de su alforja transporta por encargo venenos paralizantes y hojas de sombra que están prohibidos en las aduanas del norte.", "rumor": "Se comenta que entre las cajas de pieles y conservas de Valeria viajan frascos que ningún guardia debería ver.", "witness": "lina"},
		{"id": "valeria_noble_debt", "title": "El pagaré del conde", "text": "Un noble de extramuros le debe una fortuna en pieles de armiño y, como no puede pagarle en oro, le filtra nombres de fugitivos buscados por la Corona.", "rumor": "Cuentan que Valeria trae de la capital algo más que mercancía: sabe a quién buscan los jueces de extramuros.", "witness": "casimir"},
	],
	"Inquisidor Real Alistair": [
		{"id": "alistair_innocent_hanged", "title": "El inocente de Vado Gris", "text": "Hace tres años ahorcó a un molinero sin coartada en Vado Gris para cerrar un caso real a tiempo; dos meses después apareció el verdadero asesino y Alistair quemó la confesión.", "rumor": "Corre el rumor de que el Inquisidor Alistair mandó a la horca a un inocente en otro valle y ocultó la prueba para salvar su carrera.", "witness": "vane"},
		{"id": "alistair_laudanum_vial", "title": "El frasco de láudano en el jubón", "text": "Sufre migrañas y pesadillas desde los juicios del norte y depende de un tónico fuerte de adormidera para mantener su porte implacable durante los interrogatorios.", "rumor": "Dicen que el Inquisidor Alistair esconde en su equipaje de la posada frascos de sedante fuerte para poder dormir.", "witness": "valen"},
		{"id": "alistair_secret_quota", "title": "Pliego sellado de confiscación", "text": "Trae instrucciones reservadas de la Cancillería: si el valle acumula demasiados crímenes sin resolver, tiene orden de embargar los talleres para la Corona.", "rumor": "Susurran que Alistair guarda un pliego real para confiscar los gremios del valle si la ley local fracasa.", "witness": "casimir"},
	],
}

## Tabla de fichas de persona (PersonProfile) para los 21 personajes fundadores (18 residentes + Vigía + 3 visitantes reales).
## Cada fundador tiene 6 rasgos coherentes con su historia (sin choques de eje) + `trait_variants` para dar variedad entre partidas.
const INITIAL_PERSON_PROFILES: Dictionary = {
	"Thoran": {
		"person_id": "thoran", "gender": "M", "orientation": "H", "age": 52,
		"personality": ["Trabajador", "Orgulloso", "Honrado", "Mañoso", "Protector", "Duro"],
		"trait_variants": ["Tradicionalista", "Serio", "Disciplinado"],
		"likes": ["forja", "carne_asada"], "dislikes": ["cartas"],
		"favorite_item": "iron_ore", "romance_status": "single", "partner_id": ""
	},
	"Kael": {
		"person_id": "kael", "gender": "M", "orientation": "H", "age": 22,
		"personality": ["Curioso", "Noctámbulo", "Paciente", "Innovador", "Coleccionista", "Estudioso"],
		"trait_variants": ["Aventurero", "Creativo", "Discreto"],
		"likes": ["reliquias", "forja"], "dislikes": ["silencio"],
		"favorite_item": "bread", "romance_status": "single", "partner_id": ""
	},
	"Garrick": {
		"person_id": "garrick", "gender": "M", "orientation": "H", "age": 38,
		"personality": ["Valiente", "Desconfiado", "Rencoroso", "Duro", "Callado", "Ahorrador"],
		"trait_variants": ["Huraño", "Frugal", "Nostálgico"],
		"likes": ["caza", "carne_asada"], "dislikes": ["historias"],
		"favorite_item": "fox_pelt", "romance_status": "single", "partner_id": ""
	},
	"Lina": {
		"person_id": "lina", "gender": "F", "orientation": "H", "age": 34,
		"personality": ["Leal", "Paciente", "Curioso", "Mañoso", "Prudente", "Memorioso"],
		"trait_variants": ["Amante de los animales", "Aventurero", "Metódico"],
		"likes": ["caza", "animales"], "dislikes": ["cartas"],
		"favorite_item": "roasted_chicken", "romance_status": "single", "partner_id": ""
	},
	"Bram": {
		"person_id": "bram", "gender": "M", "orientation": "H", "age": 41,
		"personality": ["Trabajador", "Honrado", "Desconfiado", "Metódico", "Mañoso", "Ordenado"],
		"trait_variants": ["Íntegro", "Hogareño", "Protector"],
		"likes": ["carpinteria", "estofado"], "dislikes": ["reliquias"],
		"favorite_item": "wood", "romance_status": "single", "partner_id": ""
	},
	"Mila": {
		"person_id": "mila", "gender": "F", "orientation": "H", "age": 33,
		"personality": ["Paciente", "Leal", "Curioso", "Creativo", "Discreto", "Familiar"],
		"trait_variants": ["Artista", "Mañoso", "Generoso"],
		"likes": ["carpinteria", "musica"], "dislikes": ["caza"],
		"favorite_item": "country_stew", "romance_status": "single", "partner_id": ""
	},
	"Marlo": {
		"person_id": "marlo", "gender": "M", "orientation": "H", "age": 54,
		"personality": ["Paciente", "Alegre", "Bondadoso", "Madrugador", "Nostálgico", "Conforme"],
		"trait_variants": ["Amigable", "Hablador", "Hogareño"],
		"likes": ["pesca", "historias"], "dislikes": ["forja"],
		"favorite_item": "night_catfish", "romance_status": "single", "partner_id": ""
	},
	"Nora": {
		"person_id": "nora", "gender": "F", "orientation": "H", "age": 23,
		"personality": ["Paciente", "Desconfiado", "Noctámbulo", "Memorioso", "Discreto", "Callado"],
		"trait_variants": ["Curioso", "Estudioso", "Metódico"],
		"likes": ["pescado", "silencio"], "dislikes": ["cartas"],
		"favorite_item": "cooked_fish", "romance_status": "single", "partner_id": ""
	},
	"Elena": {
		"person_id": "elena", "gender": "F", "orientation": "H", "age": 36,
		"personality": ["Pacífico", "Bondadoso", "Curioso", "Empático", "Estudioso", "Fiel"],
		"trait_variants": ["Pulcro", "Discreto", "Responsable"],
		"likes": ["hierbas", "lluvia"], "dislikes": ["caza"],
		"favorite_item": "herbs", "romance_status": "partnered", "partner_id": "valen"
	},
	"Tomás": {
		"person_id": "tomas", "gender": "M", "orientation": "H", "age": 39,
		"personality": ["Paciente", "Trabajador", "Pacífico", "Cooperativo", "Hogareño", "Humilde"],
		"trait_variants": ["Amante de los animales", "Madrugador", "Conforme"],
		"likes": ["lluvia", "hierbas"], "dislikes": ["cartas"],
		"favorite_item": "bread", "romance_status": "single", "partner_id": ""
	},
	"Marta": {
		"person_id": "marta", "gender": "F", "orientation": "H", "age": 44,
		"personality": ["Alegre", "Orgulloso", "Chismoso", "Astuto", "Negociante", "Líder"],
		"trait_variants": ["Hablador", "Ambicioso", "Sereno"],
		"likes": ["estofado", "cartas"], "dislikes": ["silencio"],
		"favorite_item": "roasted_chicken", "romance_status": "single", "partner_id": ""
	},
	"Dr. Valen": {
		"person_id": "valen", "gender": "M", "orientation": "H", "age": 40,
		"personality": ["Curioso", "Paciente", "Honrado", "Metódico", "Pulcro", "Estudioso"],
		"trait_variants": ["Frío", "Sereno", "Fiel"],
		"likes": ["hierbas", "silencio"], "dislikes": ["cartas"],
		"favorite_item": "surgical_kit", "romance_status": "partnered", "partner_id": "elena"
	},
	"Hermano Anselmo": {
		"person_id": "anselmo", "gender": "M", "orientation": "H", "age": 61,
		"personality": ["Devoto", "Bondadoso", "Líder", "Indulgente", "Discreto", "Empático"],
		"trait_variants": ["Pacífico", "Mentor", "Humilde"],
		"likes": ["silencio", "pan_caliente"], "dislikes": ["cartas"],
		"favorite_item": "bread", "romance_status": "single", "partner_id": ""
	},
	"Comisario Vane": {
		"person_id": "vane", "gender": "M", "orientation": "H", "age": 55,
		"personality": ["Honrado", "Valiente", "Frío", "Estricto", "Cumplidor", "Íntegro"],
		"trait_variants": ["Justiciero", "Sereno", "Desconfiado"],
		"likes": ["carne_asada", "silencio"], "dislikes": ["cartas"],
		"favorite_item": "cooked_meat", "romance_status": "single", "partner_id": ""
	},
	"Guardia Rodric": {
		"person_id": "rodric", "gender": "M", "orientation": "H", "age": 24,
		"personality": ["Leal", "Valiente", "Honrado", "Responsable", "Protector", "Disciplinado"],
		"trait_variants": ["Cumplidor", "Duro", "Madrugador"],
		"likes": ["pan_caliente", "animales"], "dislikes": ["reliquias"],
		"favorite_item": "bread", "romance_status": "single", "partner_id": ""
	},
	"Vigía del Oeste": {
		"person_id": "vigia", "gender": "M", "orientation": "H", "age": 49,
		"personality": ["Valiente", "Duro", "Desconfiado", "Callado", "Protector", "Madrugador"],
		"trait_variants": ["Leal", "Frugal", "Memorioso"],
		"likes": ["caza", "silencio"], "dislikes": ["cartas"],
		"favorite_item": "cooked_meat", "romance_status": "single", "partner_id": ""
	},
	"Aldric": {
		"person_id": "aldric", "gender": "M", "orientation": "H", "age": 35,
		"personality": ["Tahúr", "Codicioso", "Noctámbulo", "Manipulador", "Ambicioso", "Astuto"],
		"trait_variants": ["Místico", "Coleccionista", "Rebelde"],
		"likes": ["reliquias", "cartas"], "dislikes": ["silencio"],
		"favorite_item": "cooked_meat", "romance_status": "single", "partner_id": ""
	},
	"Sora": {
		"person_id": "sora", "gender": "F", "orientation": "H", "age": 28,
		"personality": ["Tahúr", "Alegre", "Curioso", "Astuto", "Aventurero", "Negociante"],
		"trait_variants": ["Coqueto", "Sereno", "Independiente"],
		"likes": ["cartas", "musica"], "dislikes": ["lluvia"],
		"favorite_item": "roasted_chicken", "romance_status": "single", "partner_id": ""
	},
	"Darío": {
		"person_id": "dario", "gender": "M", "orientation": "H", "age": 42,
		"personality": ["Honrado", "Trabajador", "Bondadoso", "Protector", "Duro", "Valiente"],
		"trait_variants": ["Responsable", "Humilde", "Leal"],
		"likes": ["estofado", "forja"], "dislikes": ["cartas"],
		"favorite_item": "country_stew", "romance_status": "single", "partner_id": ""
	},
	"Maese Casimir": {
		"person_id": "casimir", "gender": "M", "orientation": "H", "age": 48,
		"personality": ["Orgulloso", "Trabajador", "Desconfiado", "Negociante", "Ahorrador", "Metódico"],
		"trait_variants": ["Estricto", "Ordenado", "Prudente"],
		"likes": ["forja", "carpinteria"], "dislikes": ["lluvia"],
		"favorite_item": "royal_ration", "romance_status": "single", "partner_id": ""
	},
	"Valeria la Tratante": {
		"person_id": "valeria", "gender": "F", "orientation": "H", "age": 37,
		"personality": ["Orgulloso", "Curioso", "Valiente", "Negociante", "Aventurero", "Independiente"],
		"trait_variants": ["Astuto", "Duro", "Competitivo"],
		"likes": ["caza", "carne_asada"], "dislikes": ["pescado"],
		"favorite_item": "royal_ration", "romance_status": "single", "partner_id": ""
	},
	"Inquisidor Real Alistair": {
		"person_id": "alistair", "gender": "M", "orientation": "H", "age": 51,
		"personality": ["Frío", "Orgulloso", "Rencoroso", "Estricto", "Insensible", "Metódico"],
		"trait_variants": ["Sereno", "Memorioso", "Desconfiado"],
		"likes": ["silencio", "historias"], "dislikes": ["cartas"],
		"favorite_item": "royal_ration", "romance_status": "single", "partner_id": ""
	},
}


