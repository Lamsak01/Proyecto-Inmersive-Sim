@tool
extends RefCounted

## Catálogo central de rasgos de personalidad (T1/T2). Lista aprobada por el usuario: `docs/RASGOS_BORRADOR.md`.
## Cada rasgo sube o baja unas pocas «tendencias»; la tendencia de un vecino es la suma de las de sus rasgos
## (0 = normal, positivo = más, negativo = menos). Los sistemas consultan la tendencia, no rasgos sueltos.
## Campos de cada rasgo: "axis" (eje de opuestos; "" = suelto), "tone" (k = amable, n = neutro, h = difícil),
## "rare" (opcional), "desc" y "tend". El id (masculino) es lo que se guarda en las partidas: no renombrarlo.
## Para la forma femenina usa `display(id, genero)`.

const TRAITS_PER_PERSON: int = 6
## Probabilidad de que un vecino nuevo lleve un rasgo raro (como mucho uno).
const RARE_CHANCE: float = 0.25

## Tendencias. Las marcadas «dormida» aún no las usa ningún sistema: despertarán cuando llegue el suyo.
const TENDENCIES: Dictionary = {
	"malice": "Malicia: hablar mal de otros a sus espaldas",
	"grudge": "Rencor: cuánto le dura una enemistad",
	"gossip": "Chismorreo: contar novedades",
	"aggression": "Agresividad: llegar a las manos",
	"honesty": "Honestidad: decir la verdad, rechazar sobornos",
	"trust": "Confianza: creerse lo que le cuentan",
	"diligence": "Laboriosidad",
	"generosity": "Generosidad",
	"sociability": "Sociabilidad: buscar compañía",
	"courage": "Valor: huir o plantar cara (dormida)",
	"romance": "Romance: facilidad para la chispa (dormida)",
	"fidelity": "Fidelidad a la pareja (dormida)",
	"night": "Horario: positivo trasnocha, negativo madruga (dormida)",
	"ambition": "Ambición (dormida)",
	"faith": "Fe (dormida)",
	"wit": "Ingenio: ver tus trucos (dormida)",
	"law": "Respeto a la ley (dormida)",
	"vice": "Vicio: riesgo de adicción (dormida)",
	"appetite": "Apetito (dormida)",
	"hygiene": "Higiene (dormida)",
	"health": "Aguante ante heridas y enfermedades (dormida)",
	"leadership": "Mando: arrastrar o seguir opiniones (dormida)",
	"fame": "Ganas de ser famoso",
	"nerve": "Nervios en interrogatorios (dormida)",
	"memory": "Memoria de testigo (dormida)",
	"spending": "Gasto: derrochar o ahorrar (dormida)",
	"innovation": "Gusto por lo nuevo y la tecnología (dormida)",
	"wander": "Ganas de irse del pueblo (dormida)",
	"rivalry": "Competitividad (dormida)",
	"craft": "Habilidad manual",
	"animals": "Cariño por los animales (dormida)",
	"trade": "Mano para el comercio",
}

## id del rasgo -> datos. 140 rasgos: 118 en 51 ejes de opuestos y 22 sueltos; 17 raros.
const TRAITS: Dictionary = {
	"Honrado": {"axis": "sinceridad", "tone": "k", "desc": "Dice la verdad aunque le cueste.", "tend": {"malice": -0.6, "honesty": 1.0}},
	"Mentiroso": {"axis": "sinceridad", "tone": "h", "desc": "Miente con facilidad, incluso en interrogatorios.", "tend": {"honesty": -1.0, "malice": 0.3}},
	"Manipulador": {"axis": "sinceridad", "tone": "h", "rare": true, "desc": "Mueve a los demás a su antojo; sus calumnias calan.", "tend": {"honesty": -0.8, "malice": 0.8, "trust": -0.3}},
	"Leal": {"axis": "lealtad", "tone": "k", "desc": "Defiende a los suyos y no les da la espalda.", "tend": {"malice": -0.6, "trust": 0.3, "honesty": 0.3}},
	"Traicionero": {"axis": "lealtad", "tone": "h", "rare": true, "desc": "Puede delatarte aunque te aprecie.", "tend": {"malice": 0.6, "honesty": -0.6, "trust": -0.3}},
	"Pacífico": {"axis": "temple", "tone": "k", "desc": "Evita los conflictos.", "tend": {"malice": -0.5, "aggression": -1.0, "grudge": -0.5}},
	"Pendenciero": {"axis": "temple", "tone": "h", "desc": "Busca bronca a la mínima.", "tend": {"aggression": 0.8, "grudge": 0.3}},
	"Violento": {"axis": "temple", "tone": "h", "rare": true, "desc": "Llega a las manos sin esperar a que la cosa se enquiste.", "tend": {"aggression": 1.5, "malice": 0.4}},
	"Bondadoso": {"axis": "bondad", "tone": "k", "desc": "Piensa bien de los demás y ayuda sin pedir nada.", "tend": {"malice": -1.0, "generosity": 1.0, "aggression": -0.3}},
	"Egoísta": {"axis": "bondad", "tone": "h", "desc": "Primero él, luego él.", "tend": {"generosity": -0.8, "malice": 0.2}},
	"Cruel": {"axis": "bondad", "tone": "h", "rare": true, "desc": "Disfruta del sufrimiento ajeno.", "tend": {"malice": 1.2, "aggression": 0.6, "generosity": -0.6}},
	"Alegre": {"axis": "animo", "tone": "k", "desc": "Optimista y fácil de tratar.", "tend": {"malice": -0.3, "sociability": 0.6, "grudge": -0.4}},
	"Melancólico": {"axis": "animo", "tone": "n", "desc": "Le pesa todo; los duelos le duran más.", "tend": {"sociability": -0.4, "grudge": 0.2}},
	"Amargado": {"axis": "animo", "tone": "h", "desc": "Todo le parece mal y lo dice.", "tend": {"malice": 0.5, "sociability": -0.5, "grudge": 0.4}},
	"Curioso": {"axis": "curiosidad", "tone": "n", "desc": "Quiere saberlo todo.", "tend": {"gossip": 0.6, "sociability": 0.3}},
	"Indiferente": {"axis": "curiosidad", "tone": "n", "desc": "Lo que pasa a su alrededor le da igual.", "tend": {"gossip": -0.6, "sociability": -0.2}},
	"Trabajador": {"axis": "laboriosidad", "tone": "k", "desc": "No para quieto.", "tend": {"diligence": 1.0}},
	"Holgazán": {"axis": "laboriosidad", "tone": "h", "desc": "Hace lo justo, y a veces ni eso.", "tend": {"diligence": -1.0}},
	"Paciente": {"axis": "paciencia", "tone": "k", "desc": "No pierde los nervios.", "tend": {"malice": -0.3, "aggression": -0.5, "grudge": -0.4}},
	"Impaciente": {"axis": "paciencia", "tone": "n", "desc": "Lo quiere todo para ya.", "tend": {"aggression": 0.3, "grudge": 0.2}},
	"Irascible": {"axis": "paciencia", "tone": "h", "desc": "Estalla por cualquier cosa.", "tend": {"aggression": 0.8, "grudge": 0.4, "malice": 0.2}},
	"Temerario": {"axis": "valentia", "tone": "n", "rare": true, "desc": "No mide el peligro.", "tend": {"courage": 1.5, "aggression": 0.4}},
	"Valiente": {"axis": "valentia", "tone": "k", "desc": "No se arruga ante el peligro.", "tend": {"aggression": 0.5, "courage": 1.0}},
	"Prudente": {"axis": "valentia", "tone": "n", "desc": "Se lo piensa dos veces antes de arriesgarse.", "tend": {"courage": -0.3, "aggression": -0.3}},
	"Cobarde": {"axis": "valentia", "tone": "h", "desc": "Huye a la primera.", "tend": {"courage": -1.0, "aggression": -0.5}},
	"Humilde": {"axis": "humildad", "tone": "k", "desc": "Reconoce sus errores.", "tend": {"grudge": -0.4, "malice": -0.3}},
	"Orgulloso": {"axis": "humildad", "tone": "n", "desc": "Le cuesta reconocer un error.", "tend": {"malice": 0.3, "grudge": 0.5, "aggression": 0.3}},
	"Arrogante": {"axis": "humildad", "tone": "h", "desc": "Se cree por encima y se ofende con facilidad.", "tend": {"malice": 0.5, "grudge": 0.6, "sociability": -0.2}},
	"Ingenuo": {"axis": "confianza", "tone": "n", "rare": true, "desc": "Se cree todo lo que le cuentan.", "tend": {"trust": 1.5}},
	"Confiado": {"axis": "confianza", "tone": "k", "desc": "Da a los demás el beneficio de la duda.", "tend": {"trust": 0.6}},
	"Desconfiado": {"axis": "confianza", "tone": "n", "desc": "Sospecha de todo el mundo.", "tend": {"malice": 0.2, "trust": -1.0}},
	"Paranoico": {"axis": "confianza", "tone": "h", "rare": true, "desc": "Ve conspiraciones en todas partes.", "tend": {"trust": -1.6, "malice": 0.3}},
	"Conforme": {"axis": "envidia", "tone": "k", "desc": "Está contento con lo que tiene.", "tend": {"malice": -0.3}},
	"Envidioso": {"axis": "envidia", "tone": "h", "desc": "Le corroe lo que tienen los demás.", "tend": {"malice": 0.8, "grudge": 0.4}},
	"Seguro de sí": {"axis": "celos", "tone": "k", "desc": "No siente celos de su pareja.", "tend": {"trust": 0.2, "grudge": -0.2}},
	"Celoso": {"axis": "celos", "tone": "h", "desc": "Sufre celos de su pareja.", "tend": {"malice": 0.3, "grudge": 0.4, "trust": -0.3}},
	"Indulgente": {"axis": "perdon", "tone": "k", "desc": "Perdona pronto.", "tend": {"grudge": -1.0, "malice": -0.4}},
	"Rencoroso": {"axis": "perdon", "tone": "h", "desc": "Nunca olvida una ofensa.", "tend": {"malice": 1.0, "grudge": 1.0}},
	"Vengativo": {"axis": "perdon", "tone": "h", "rare": true, "desc": "No descansa hasta devolver la ofensa.", "tend": {"grudge": 1.5, "malice": 0.8, "aggression": 0.4}},
	"Generoso": {"axis": "dinero", "tone": "k", "desc": "Comparte lo que tiene.", "tend": {"generosity": 1.0, "malice": -0.2}},
	"Codicioso": {"axis": "dinero", "tone": "h", "desc": "Todo lo mide en oro.", "tend": {"malice": 0.4, "honesty": -0.5, "generosity": -1.0}},
	"Cariñoso": {"axis": "calidez", "tone": "k", "desc": "Afectuoso con todo el mundo.", "tend": {"sociability": 0.5, "romance": 0.5, "malice": -0.3}},
	"Frío": {"axis": "calidez", "tone": "n", "desc": "Distante; los sentimientos le estorban.", "tend": {"malice": 0.3, "sociability": -0.6, "gossip": -0.4}},
	"Madrugador": {"axis": "horario", "tone": "n", "desc": "Se levanta antes que nadie.", "tend": {"night": -1.0, "diligence": 0.2}},
	"Noctámbulo": {"axis": "horario", "tone": "n", "desc": "Hace su vida de noche.", "tend": {"night": 1.0}},
	"Discreto": {"axis": "discrecion", "tone": "k", "desc": "No cuenta lo que sabe, ni siquiera a ti.", "tend": {"gossip": -1.0, "malice": -0.3}},
	"Chismoso": {"axis": "discrecion", "tone": "h", "desc": "No sabe guardar un secreto.", "tend": {"malice": 0.6, "gossip": 1.0}},
	"Amigable": {"axis": "trato", "tone": "k", "desc": "Hace amigos enseguida.", "tend": {"sociability": 0.8}},
	"Tímido": {"axis": "trato", "tone": "n", "desc": "Le cuesta abrirse.", "tend": {"sociability": -0.5}},
	"Huraño": {"axis": "trato", "tone": "h", "desc": "Prefiere que le dejen en paz.", "tend": {"sociability": -1.0, "trust": -0.3}},
	"Respetuoso": {"axis": "respeto", "tone": "k", "desc": "Nunca habla a espaldas de nadie.", "tend": {"malice": -0.6}},
	"Insolente": {"axis": "respeto", "tone": "h", "desc": "Provoca y falta al respeto.", "tend": {"malice": 0.3, "aggression": 0.3}},
	"Permisivo": {"axis": "tolerancia", "tone": "k", "desc": "Deja pasar casi todo.", "tend": {"grudge": -0.5}},
	"Estricto": {"axis": "tolerancia", "tone": "n", "desc": "Las normas son las normas.", "tend": {"law": 0.6, "grudge": 0.2}},
	"Intolerante": {"axis": "tolerancia", "tone": "h", "desc": "Choca con quien es distinto.", "tend": {"grudge": 0.6, "malice": 0.4}},
	"Ordenado": {"axis": "orden", "tone": "n", "desc": "Cada cosa en su sitio.", "tend": {"diligence": 0.3}},
	"Desordenado": {"axis": "orden", "tone": "n", "desc": "Vive en el caos.", "tend": {"diligence": -0.3}},
	"Conformista": {"axis": "ambicion", "tone": "n", "desc": "No aspira a más.", "tend": {"ambition": -0.8}},
	"Ambicioso": {"axis": "ambicion", "tone": "n", "desc": "Quiere prosperar.", "tend": {"ambition": 1.0, "diligence": 0.3}},
	"Sediento de poder": {"axis": "ambicion", "tone": "h", "rare": true, "desc": "Ansía mandar y conspira para lograrlo.", "tend": {"ambition": 1.6, "malice": 0.5, "honesty": -0.3}},
	"Escéptico": {"axis": "fe", "tone": "n", "desc": "No cree en lo que no ve.", "tend": {"faith": -1.0}},
	"Devoto": {"axis": "fe", "tone": "n", "desc": "Su fe guía su vida.", "tend": {"faith": 1.0}},
	"Fanático": {"axis": "fe", "tone": "h", "rare": true, "desc": "Su fe no admite dudas ni a quien duda.", "tend": {"faith": 1.8, "aggression": 0.3}},
	"Romántico": {"axis": "amor", "tone": "n", "desc": "Se enamora con facilidad.", "tend": {"romance": 1.0}},
	"Desapegado": {"axis": "amor", "tone": "n", "desc": "El amor no va con él.", "tend": {"romance": -1.0}},
	"Familiar": {"axis": "familia", "tone": "k", "desc": "Su familia es lo primero.", "tend": {"sociability": 0.3}},
	"Independiente": {"axis": "familia", "tone": "n", "desc": "Va por libre.", "tend": {"sociability": -0.2}},
	"Bromista": {"axis": "humor", "tone": "n", "desc": "Siempre tiene una broma a mano.", "tend": {"sociability": 0.5}},
	"Serio": {"axis": "humor", "tone": "n", "desc": "No le hacen gracia las bromas.", "tend": {"sociability": -0.2}},
	"Astuto": {"axis": "ingenio", "tone": "n", "desc": "Ve venir los trucos.", "tend": {"wit": 1.0}},
	"Despistado": {"axis": "ingenio", "tone": "n", "desc": "No se entera de nada.", "tend": {"wit": -1.0}},
	"Responsable": {"axis": "responsabilidad", "tone": "k", "desc": "Cumple con lo que le toca.", "tend": {"diligence": 0.5, "law": 0.3}},
	"Irresponsable": {"axis": "responsabilidad", "tone": "h", "desc": "Falta a sus obligaciones.", "tend": {"diligence": -0.6, "law": -0.3}},
	"Sobrio": {"axis": "bebida", "tone": "k", "desc": "Apenas prueba el alcohol.", "tend": {"vice": -0.6}},
	"Bebedor": {"axis": "bebida", "tone": "h", "desc": "Vive en la taberna y bebido habla de más.", "tend": {"vice": 1.0, "gossip": 0.3}},
	"Frugal": {"axis": "comida", "tone": "n", "desc": "Come poco.", "tend": {"appetite": -1.0}},
	"Glotón": {"axis": "comida", "tone": "n", "desc": "Siempre tiene hambre.", "tend": {"appetite": 1.0}},
	"Pulcro": {"axis": "aseo", "tone": "k", "desc": "Siempre limpio y arreglado.", "tend": {"hygiene": 1.0}},
	"Desaliñado": {"axis": "aseo", "tone": "h", "desc": "Descuida su aseo.", "tend": {"hygiene": -1.0}},
	"Cumplidor": {"axis": "ley", "tone": "k", "desc": "Respeta la ley.", "tend": {"law": 1.0, "honesty": 0.2}},
	"Rebelde": {"axis": "ley", "tone": "n", "desc": "Las normas le parecen sugerencias.", "tend": {"law": -0.6}},
	"Delincuente": {"axis": "ley", "tone": "h", "rare": true, "desc": "Roba o encubre si le conviene.", "tend": {"law": -1.6, "honesty": -0.6}},
	"Duro": {"axis": "aguante", "tone": "n", "desc": "Aguanta heridas y enfermedades.", "tend": {"health": 1.0}},
	"Quejica": {"axis": "aguante", "tone": "n", "desc": "Se queja de todo dolor.", "tend": {"health": -0.6}},
	"Hablador": {"axis": "palabra", "tone": "n", "desc": "No calla ni debajo del agua.", "tend": {"gossip": 0.5, "sociability": 0.4}},
	"Callado": {"axis": "palabra", "tone": "n", "desc": "Habla lo justo.", "tend": {"gossip": -0.4, "sociability": -0.3}},
	"Líder": {"axis": "mando", "tone": "n", "desc": "Arrastra la opinión de los demás.", "tend": {"leadership": 1.0}},
	"Sumiso": {"axis": "mando", "tone": "n", "desc": "Se deja convencer.", "tend": {"leadership": -1.0, "trust": 0.4}},
	"Fiel": {"axis": "fidelidad", "tone": "k", "desc": "Nunca engañaría a su pareja.", "tend": {"fidelity": 1.0}},
	"Infiel": {"axis": "fidelidad", "tone": "h", "desc": "Busca aventuras aunque tenga pareja.", "tend": {"fidelity": -1.2, "honesty": -0.3}},
	"Modesto": {"axis": "vanidad", "tone": "k", "desc": "No busca ser admirado.", "tend": {"fame": -0.8}},
	"Vanidoso": {"axis": "vanidad", "tone": "n", "desc": "Necesita que le admiren.", "tend": {"fame": 1.0}},
	"Empático": {"axis": "empatia", "tone": "k", "desc": "Nota cuando alguien sufre.", "tend": {"generosity": 0.4, "trust": 0.2, "malice": -0.3}},
	"Insensible": {"axis": "empatia", "tone": "h", "desc": "El dolor ajeno no le toca.", "tend": {"generosity": -0.4, "malice": 0.3}},
	"Sereno": {"axis": "nervios", "tone": "n", "desc": "Mantiene la calma; miente mejor.", "tend": {"nerve": 1.0}},
	"Nervioso": {"axis": "nervios", "tone": "n", "desc": "Parece culpable aunque no lo sea.", "tend": {"nerve": -1.0}},
	"Memorioso": {"axis": "memoria", "tone": "n", "desc": "Recuerda cada detalle.", "tend": {"memory": 1.0, "grudge": 0.2}},
	"Olvidadizo": {"axis": "memoria", "tone": "n", "desc": "Olvida favores y ofensas.", "tend": {"memory": -1.0, "grudge": -0.3}},
	"Metódico": {"axis": "impulso", "tone": "n", "desc": "Piensa antes de actuar.", "tend": {"diligence": 0.3, "aggression": -0.2}},
	"Impulsivo": {"axis": "impulso", "tone": "n", "desc": "Actúa sin pensar.", "tend": {"aggression": 0.4}},
	"Ahorrador": {"axis": "gasto", "tone": "n", "desc": "Guarda cada moneda.", "tend": {"spending": -1.0}},
	"Derrochador": {"axis": "gasto", "tone": "n", "desc": "El dinero se le escapa de las manos.", "tend": {"spending": 1.0}},
	"Íntegro": {"axis": "integridad", "tone": "k", "desc": "No se vende.", "tend": {"law": 0.4, "honesty": 0.5}},
	"Sobornable": {"axis": "integridad", "tone": "h", "desc": "Todo tiene un precio.", "tend": {"honesty": -0.8, "law": -0.4}},
	"Tradicionalista": {"axis": "tradicion", "tone": "n", "desc": "Desconfía de lo nuevo.", "tend": {"innovation": -1.0}},
	"Innovador": {"axis": "tradicion", "tone": "n", "desc": "Le fascina lo nuevo.", "tend": {"innovation": 1.0}},
	"Hogareño": {"axis": "arraigo", "tone": "n", "desc": "Nunca se iría del pueblo.", "tend": {"wander": -1.0}},
	"Aventurero": {"axis": "arraigo", "tone": "n", "desc": "Sueña con marcharse lejos.", "tend": {"wander": 1.0}},
	"Cooperativo": {"axis": "competencia", "tone": "k", "desc": "Prefiere ayudar a competir.", "tend": {"rivalry": -0.8}},
	"Competitivo": {"axis": "competencia", "tone": "n", "desc": "Odia perder.", "tend": {"rivalry": 1.0, "aggression": 0.2}},
	"Recatado": {"axis": "coqueteo", "tone": "n", "desc": "Reservado en el amor.", "tend": {"romance": -0.3}},
	"Coqueto": {"axis": "coqueteo", "tone": "n", "desc": "Coquetea con cualquiera.", "tend": {"romance": 0.8, "fidelity": -0.3}},
	"Mañoso": {"axis": "manos", "tone": "n", "desc": "Hábil con las manos.", "tend": {"craft": 1.0}},
	"Torpe": {"axis": "manos", "tone": "n", "desc": "Se le cae todo.", "tend": {"craft": -1.0}},
	"Creativo": {"axis": "creatividad", "tone": "n", "desc": "Tiene un estilo propio.", "tend": {"craft": 0.4, "fame": 0.3}},
	"Convencional": {"axis": "creatividad", "tone": "n", "desc": "Hace las cosas como siempre se han hecho.", "tend": {"innovation": -0.3}},
	"Disciplinado": {"axis": "voluntad", "tone": "k", "desc": "Tiene fuerza de voluntad.", "tend": {"vice": -0.8, "diligence": 0.3}},
	"Débil de voluntad": {"axis": "voluntad", "tone": "h", "desc": "Cae con facilidad en los vicios.", "tend": {"vice": 0.8}},
	"Tahúr": {"axis": "", "tone": "n", "desc": "Vive del juego y de las apuestas.", "tend": {"malice": 0.2, "honesty": -0.6, "vice": 0.5}},
	"Supersticioso": {"axis": "", "tone": "n", "desc": "Evita el cementerio de noche; se cree los rumores raros.", "tend": {"faith": 0.4, "trust": 0.3}},
	"Protector": {"axis": "", "tone": "k", "desc": "Defiende a familia y amigos.", "tend": {"courage": 0.5, "aggression": 0.2}},
	"Nostálgico": {"axis": "", "tone": "n", "desc": "Vive en el pasado; visita las tumbas.", "tend": {"memory": 0.3}},
	"Artista": {"axis": "", "tone": "n", "desc": "Su obra le importa; se ofende si se la critican.", "tend": {"fame": 0.5, "craft": 0.3}},
	"Estudioso": {"axis": "", "tone": "n", "desc": "Recuerda detalles; buen testigo.", "tend": {"wit": 0.5, "memory": 0.5}},
	"Amante de los animales": {"axis": "", "tone": "k", "desc": "Cuida a los animales; se enfada si los maltratas.", "tend": {"animals": 1.0}},
	"Hipocondríaco": {"axis": "", "tone": "n", "desc": "Cree estar siempre enfermo.", "tend": {"health": -0.5}},
	"Coleccionista": {"axis": "", "tone": "n", "desc": "Persigue objetos raros.", "tend": {"spending": 0.3}},
	"Sanguinario": {"axis": "", "tone": "h", "rare": true, "desc": "La violencia no le asusta, le atrae.", "tend": {"aggression": 1.2, "malice": 1.0}},
	"Cleptómano": {"axis": "", "tone": "h", "rare": true, "desc": "Roba pequeñas cosas sin poder evitarlo.", "tend": {"law": -0.8, "honesty": -0.4}},
	"Insomne": {"axis": "", "tone": "n", "desc": "Duerme poco y deambula de noche.", "tend": {"night": 0.8}},
	"Obsesivo": {"axis": "", "tone": "h", "rare": true, "desc": "Puede obsesionarse con una persona.", "tend": {"romance": 0.8, "grudge": 0.5}},
	"Místico": {"axis": "", "tone": "n", "desc": "Le atrae lo oculto.", "tend": {"faith": 0.6}},
	"Celestino": {"axis": "", "tone": "n", "desc": "Intenta emparejar a los demás.", "tend": {"sociability": 0.4, "gossip": 0.3}},
	"Negociante": {"axis": "", "tone": "n", "desc": "Regatea como nadie.", "tend": {"trade": 1.0, "generosity": -0.2}},
	"Mentor": {"axis": "", "tone": "k", "desc": "Le gusta enseñar.", "tend": {"generosity": 0.3, "sociability": 0.2}},
	"Fanfarrón": {"axis": "", "tone": "n", "desc": "Presume y reta a los demás.", "tend": {"fame": 0.6, "aggression": 0.3}},
	"Justiciero": {"axis": "", "tone": "n", "desc": "Investiga por su cuenta y puede tomarse la justicia por su mano.", "tend": {"law": 0.6, "aggression": 0.3, "courage": 0.4}},
	"Sonámbulo": {"axis": "", "tone": "n", "rare": true, "desc": "Camina dormido de noche.", "tend": {"night": 0.5}},
	"Ermitaño": {"axis": "", "tone": "n", "rare": true, "desc": "Vive apartado de todos.", "tend": {"sociability": -1.5}},
	"Chantajista": {"axis": "", "tone": "h", "rare": true, "desc": "Usa los secretos ajenos para sacar provecho.", "tend": {"malice": 0.8, "honesty": -0.6}},
}

## U2: manías de un solo lado. Al vecino con el rasgo de la izquierda le irritan quienes tienen alguno de la derecha
## (al otro no tiene por qué molestarle él).
const IRRITATES: Dictionary = {
	"Honrado": ["Mentiroso", "Manipulador", "Chismoso"], "Íntegro": ["Sobornable"], "Serio": ["Bromista"],
	"Pulcro": ["Desaliñado"], "Ordenado": ["Desordenado"], "Trabajador": ["Holgazán"], "Responsable": ["Irresponsable"],
	"Sobrio": ["Bebedor"], "Respetuoso": ["Insolente"], "Callado": ["Hablador"], "Huraño": ["Hablador", "Amigable", "Bromista"],
	"Discreto": ["Chismoso"], "Estricto": ["Rebelde", "Irresponsable"], "Cumplidor": ["Delincuente", "Rebelde"],
	"Modesto": ["Vanidoso", "Fanfarrón"], "Humilde": ["Arrogante", "Fanfarrón"], "Pacífico": ["Pendenciero", "Violento"],
	"Fanático": ["Escéptico"], "Tradicionalista": ["Innovador"], "Fiel": ["Infiel"], "Metódico": ["Impulsivo"],
	"Impaciente": ["Despistado"], "Intolerante": ["Rebelde", "Escéptico", "Devoto"], "Arrogante": ["Torpe", "Despistado"],
	"Envidioso": ["Vanidoso", "Ambicioso"], "Amante de los animales": ["Cruel", "Sanguinario"],
}

## Cuántos rasgos de `other_traits` irritan a quien tiene `self_traits`.
static func irritation_count(self_traits: Array, other_traits: Array) -> int:
	var n: int = 0
	for st in self_traits:
		for ot in IRRITATES.get(str(st), []):
			if ot in other_traits:
				n += 1
	return n

static func axis_of(trait_id: String) -> String:
	return str((TRAITS.get(trait_id, {}) as Dictionary).get("axis", ""))

static func is_rare(trait_id: String) -> bool:
	return bool((TRAITS.get(trait_id, {}) as Dictionary).get("rare", false))

static func tone_of(trait_id: String) -> String:
	return str((TRAITS.get(trait_id, {}) as Dictionary).get("tone", "n"))

static func conflicts(a: String, b: String) -> bool:
	if a == b:
		return true
	var ax: String = axis_of(a)
	return ax != "" and ax == axis_of(b)

## Dos rasgos distintos del mismo eje (restan compatibilidad entre dos personas).
static func are_opposed(a: String, b: String) -> bool:
	return a != b and conflicts(a, b)

static func conflicts_with_any(trait_id: String, traits: Array) -> bool:
	for t in traits:
		if conflicts(trait_id, str(t)):
			return true
	return false

## Reparte hasta `count` rasgos sin choques de eje y con como mucho `max_rare` raros.
## `keep`: rasgos que ya tiene y se conservan (para completar partidas guardadas). `pool`: candidatos (todos por defecto).
## Con la misma semilla en `rng` el resultado es siempre el mismo.
static func roll_traits(rng: RandomNumberGenerator, count: int, keep: Array = [], pool: Array = [], max_rare: int = 1) -> Array[String]:
	var res: Array[String] = []
	var rare_n: int = 0
	for t in keep:
		var ts: String = str(t)
		if res.size() < count and not conflicts_with_any(ts, res):
			res.append(ts)
			if is_rare(ts):
				rare_n += 1
	var cands: Array = (pool if not pool.is_empty() else TRAITS.keys()).duplicate()
	cands.sort() # Orden fijo antes de barajar con la semilla
	for i in range(cands.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = cands[i]
		cands[i] = cands[j]
		cands[j] = tmp
	for c in cands:
		if res.size() >= count:
			break
		var cs: String = str(c)
		if conflicts_with_any(cs, res) or (is_rare(cs) and rare_n >= max_rare):
			continue
		res.append(cs)
		if is_rare(cs):
			rare_n += 1
	return res

static func traits_with_tone(tone: String) -> Array:
	var out: Array = []
	for k in TRAITS.keys():
		if tone_of(str(k)) == tone:
			out.append(k)
	return out

## T2: reparto equilibrado de `count` rasgos (por defecto 6). Número de rasgos difíciles al azar
## (0: 15 %, 1: 50 %, 2: 30 %, 3: 5 %); los amables compensan (3 + (1 − difíciles), entre 1 y 4) y el resto, neutros.
## Conserva `keep` (rasgos que ya tenía) y lo cuenta en el reparto. Reproducible con la misma semilla.
static func roll_balanced(rng: RandomNumberGenerator, keep: Array = [], count: int = TRAITS_PER_PERSON) -> Array[String]:
	var max_rare: int = 1 if rng.randf() < RARE_CHANCE else 0
	for t in keep:
		if is_rare(str(t)):
			max_rare = 1
	var r: float = rng.randf()
	var hard_n: int = 0 if r < 0.15 else (1 if r < 0.65 else (2 if r < 0.95 else 3))
	var kind_n: int = clampi(3 + (1 - hard_n), 1, 4)
	var quotas: Dictionary = {"h": hard_n, "k": kind_n, "n": maxi(0, count - hard_n - kind_n)}
	var res: Array[String] = []
	for t in keep:
		if res.size() < count and not conflicts_with_any(str(t), res):
			res.append(str(t))
	for tone in ["h", "k", "n"]:
		var have: int = 0
		for t in res:
			if tone_of(t) == tone:
				have += 1
		var need: int = maxi(0, int(quotas[tone]) - have)
		if need > 0:
			res = roll_traits(rng, mini(count, res.size() + need), res, traits_with_tone(tone), max_rare)
	if res.size() < count: # Si algún montón se quedó corto, se completa con cualquiera
		res = roll_traits(rng, count, res, [], max_rare)
	return res

static func has_trait_id(trait_id: String) -> bool:
	return TRAITS.has(trait_id)

static func describe(trait_id: String) -> String:
	return str((TRAITS.get(trait_id, {}) as Dictionary).get("desc", ""))

## Nombre para mostrar según el género ("F" = femenino). Cambia la primera palabra:
## -o → -a (Celoso → Celosa, Frío → Fría), -or → -ora, -ón → -ona, -án → -ana. El resto se queda igual (Leal, Tahúr).
static func display(trait_id: String, gender: String = "M") -> String:
	if gender != "F" or trait_id == "":
		return trait_id
	var sp: int = trait_id.find(" ")
	var w: String = trait_id if sp < 0 else trait_id.substr(0, sp)
	var rest: String = "" if sp < 0 else trait_id.substr(sp)
	if w.ends_with("o"):
		w = w.substr(0, w.length() - 1) + "a"
	elif w.ends_with("or"):
		w += "a"
	elif w.ends_with("ón"):
		w = w.substr(0, w.length() - 2) + "ona"
	elif w.ends_with("án"):
		w = w.substr(0, w.length() - 2) + "ana"
	return w + rest

## Nombre para mostrar de un rasgo de un vecino concreto.
static func npc_display(npc: Object, trait_id: String) -> String:
	var g: String = "M"
	if npc != null and ("person_profile" in npc) and npc.person_profile != null:
		g = str(npc.person_profile.gender)
	return display(trait_id, g)

## Suma de una tendencia para una lista de rasgos (los rasgos desconocidos no cuentan).
static func tendency(traits: Array, key: String) -> float:
	var total: float = 0.0
	for t in traits:
		total += float(((TRAITS.get(str(t), {}) as Dictionary).get("tend", {}) as Dictionary).get(key, 0.0))
	return total

## Tendencia de un vecino (0 si no tiene perfil).
static func npc_tendency(npc: Object, key: String) -> float:
	if npc == null or not ("person_profile" in npc) or npc.person_profile == null:
		return 0.0
	return tendency(npc.person_profile.personality, key)
