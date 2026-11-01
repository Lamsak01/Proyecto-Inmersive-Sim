extends RefCounted

## Nombres y apellidos para el generador de aldeanos (200 femeninos, 200 masculinos, 200 apellidos).
## Estilo variado: latino, europeo y americano. Excluye los nombres de los vecinos actuales y de los viajeros iniciales.
## Género: "F" (femenino) o "M" (masculino). Todas las funciones aceptan un RandomNumberGenerator para que sea reproducible con semilla.

const FEMALE_NAMES: Array = [
	"Abril", "Adela", "Aitana", "Alba", "Alicia", "Alma", "Ana", "Andrea",
	"Ángela", "Araceli", "Ariadna", "Aurora", "Beatriz", "Berta", "Blanca", "Camila",
	"Candela", "Carmen", "Carolina", "Catalina", "Celia", "Clara", "Claudia", "Concha",
	"Cristina", "Daniela", "Dolores", "Elisa", "Emilia", "Esperanza", "Estela", "Eva",
	"Fabiola", "Fátima", "Federica", "Fernanda", "Flora", "Francisca", "Gabriela", "Graciela",
	"Guadalupe", "Helena", "Inés", "Isabel", "Isidora", "Jimena", "Juana", "Julia",
	"Julieta", "Laura", "Leticia", "Lidia", "Liliana", "Lola", "Lucrecia", "Luisa",
	"Luna", "Manuela", "Marcela", "Margarita", "Mariana", "Matilde", "Mercedes", "Mireia",
	"Mónica", "Noelia", "Octavia", "Olivia", "Paloma", "Patricia", "Paulina", "Pilar",
	"Regina", "Renata", "Rocío", "Rosa", "Sabina", "Salma", "Samanta", "Sandra",
	"Selena", "Serena", "Silvia", "Susana", "Tamara", "Teresa", "Valentina", "Victoria",
	"Violeta", "Ximena", "Yolanda", "Astrid", "Brigitte", "Camille", "Clémence", "Colette",
	"Dagmar", "Edith", "Eloise", "Freya", "Gisela", "Greta", "Hanna", "Heidi",
	"Helga", "Henrietta", "Isolde", "Johanna", "Karin", "Lena", "Liesel", "Lotte",
	"Louisa", "Marguerite", "Mathilde", "Mirabel", "Nadia", "Ottilie", "Petra", "Rosalind",
	"Sofie", "Svetlana", "Thea", "Ursula", "Wilhelmina", "Yvonne", "Agnes", "Beatrix",
	"Daphne", "Eleanor", "Fiona", "Hazel", "Imogen", "Jocelyn", "Lavinia", "Nell",
	"Ophelia", "Philippa", "Rowena", "Winifred", "Abigail", "Annabel", "Brooke", "Dakota",
	"Delilah", "Ellie", "Harper", "Jolene", "Kendra", "Loretta", "Naomi", "Opal",
	"Pearl", "Ruby", "Scarlett", "Willa", "Zelda", "Anahí", "Citlali", "Dulce",
	"Itzel", "Xóchitl", "Yaretzi", "Bianca", "Carlota", "Débora", "Edurne", "Frida",
	"Idoia", "Leire", "Maite", "Nuria", "Sonsoles", "Trinidad", "Zaida", "Amelia",
	"Elodie", "Giselle", "Isabela", "Joaquina", "Luciana", "Maia", "Nieves", "Penélope",
	"Quiteria", "Raquel", "Soraya", "Uxía", "Vanesa", "Wanda", "Yasmín", "Anselma",
	"Brunilda", "Casandra", "Eulalia", "Fidela", "Gertrudis", "Hortensia", "Jacinta", "Lisandra"
]

const MALE_NAMES: Array = [
	"Abel", "Adolfo", "Adrián", "Alberto", "Alejandro", "Alfonso", "Alfredo", "Álvaro",
	"Andrés", "Ángel", "Aníbal", "Antonio", "Arturo", "Baltasar", "Benito", "Bernardo",
	"Bruno", "Camilo", "Carlos", "Cristóbal", "Damián", "Diego", "Domingo", "Eduardo",
	"Enrique", "Ernesto", "Esteban", "Eugenio", "Ezequiel", "Fabián", "Felipe", "Félix",
	"Fermín", "Fernando", "Francisco", "Gaspar", "Gerardo", "Gonzalo", "Gregorio", "Guillermo",
	"Gustavo", "Hernán", "Hugo", "Ignacio", "Iván", "Jaime", "Jerónimo", "Joaquín",
	"Jorge", "José", "Josué", "Julián", "Lautaro", "Leandro", "Leonardo", "Lorenzo",
	"Lucas", "Manuel", "Marcelo", "Marcos", "Mariano", "Mateo", "Mauricio", "Maximiliano",
	"Miguel", "Nicolás", "Octavio", "Óscar", "Pascual", "Patricio", "Pedro", "Rafael",
	"Ramiro", "Raúl", "Ricardo", "Roberto", "Rodolfo", "Rodrigo", "Salvador", "Samuel",
	"Santiago", "Sebastián", "Sergio", "Teodoro", "Valentín", "Vicente", "Víctor", "Xavier",
	"Albrecht", "Augustin", "Benedikt", "Bertrand", "Casper", "Conrad", "Dietrich", "Emil",
	"Erik", "Fabrice", "Florian", "Frederic", "Gustaf", "Hans", "Heinrich", "Henrik",
	"Ivo", "Jens", "Johan", "Klaus", "Konrad", "Lars", "Leopold", "Magnus",
	"Marcel", "Matthias", "Maurice", "Niklas", "Otto", "Pascal", "Philippe", "Rainer",
	"Reinhard", "Rolf", "Stefan", "Sven", "Theo", "Ulrich", "Viktor", "Wilhelm",
	"Wolfgang", "Alaric", "Cedric", "Edmund", "Gareth", "Godfrey", "Harold", "Ivor",
	"Leofric", "Osmund", "Reginald", "Roderick", "Wystan", "Abe", "Amos", "Clayton",
	"Colt", "Dwight", "Elijah", "Ezra", "Gideon", "Jedediah", "Jesse", "Jonah",
	"Levi", "Linus", "Nathaniel", "Otis", "Silas", "Tucker", "Wyatt", "Clint",
	"Wade", "Boone", "Rhett", "Cal", "Dean", "Abelardo", "Atilio", "Bonifacio",
	"Cipriano", "Dagoberto", "Faustino", "Genaro", "Hilario", "Isidro", "Jacobo", "Leopoldo",
	"Nazario", "Orlando", "Prudencio", "Quirino", "Remigio", "Telmo", "Ulises", "Venancio",
	"Wenceslao", "Zacarías", "Baudilio", "Cleofás", "Demetrio", "Eladio", "Fulgencio", "Gumersindo",
	"Ildefonso", "Lisandro", "Melchor", "Nemesio", "Plácido", "Sinesio", "Tadeo", "Urbano"
]

const SURNAMES: Array = [
	"Alcázar", "Almeida", "Aranda", "Arroyo", "Bautista", "Benavides", "Bermúdez", "Bustamante",
	"Caballero", "Cabrera", "Calderón", "Camacho", "Cardenal", "Carrasco", "Castañeda", "Castellanos",
	"Cisneros", "Cordero", "Cortés", "Domínguez", "Espinosa", "Figueroa", "Fonseca", "Galindo",
	"Garrido", "Guerrero", "Gutiérrez", "Hidalgo", "Ibarra", "Lozano", "Maldonado", "Marín",
	"Mendoza", "Montenegro", "Montoya", "Navarro", "Olmedo", "Ortega", "Palacios", "Peralta",
	"Quintero", "Ramírez", "Rivas", "Robledo", "Salazar", "Sandoval", "Segovia", "Solano",
	"Tapia", "Urrutia", "Valdés", "Vargas", "Vega", "Zamora", "Zúñiga", "Ashford",
	"Bergmann", "Blackwood", "Brandt", "Carrow", "Eastwick", "Falkner", "Fenwick", "Graves",
	"Hartmann", "Holloway", "Kessler", "Lindqvist", "Marchand", "Moreau", "Nordhaus", "Pemberton",
	"Rousseau", "Schneider", "Vandermeer", "Wexford", "Ainsworth", "Baumann", "Calloway", "Draper",
	"Ellsworth", "Fairchild", "Gallagher", "Hawthorne", "Iverson", "Jorgensen", "Kingsley", "Lockhart",
	"Mercer", "Northcott", "Oakley", "Prescott", "Quincy", "Redfield", "Sinclair", "Thackeray",
	"Underhill", "Whitlock", "Yarrow", "Ziegler", "Bellamy", "Cavanaugh", "Dumont", "Esterházy",
	"Fontaine", "Gauthier", "Hargrove", "Isakson", "Janssen", "Keller", "Laurent", "Montague",
	"Nygaard", "Olsen", "Petrov", "Reinholt", "Sorensen", "Tolliver", "Voss", "Winterbourne",
	"Rocavieja", "Pinoalto", "Valleoscuro", "Rocafuerte", "Tierrafirme", "Aguaclara", "Peñanegra", "Montealto",
	"Riosecos", "Campoverde", "Fuenteblanca", "Lomaverde", "Cerrillo", "Piedrabuena", "Sierraclara", "Torrealba",
	"Vallehondo", "Alamedo", "Cañaveral", "Hontanar", "Quebrada", "Salinas", "Umbría", "Zarzal",
	"Barrientos", "Cuadrado", "Delgado", "Esquivel", "Fajardo", "Gamboa", "Heredia", "Jaramillo",
	"Lagos", "Machado", "Nieto", "Ocampo", "Pacheco", "Quesada", "Rangel", "Sosa",
	"Trejo", "Uribe", "Villegas", "Yáñez", "Acosta", "Barrios", "Cervantes", "Duarte",
	"Estrada", "Fuentes", "Granados", "Hurtado", "Iglesias", "Jiménez", "Lara", "Medina",
	"Núñez", "Orozco", "Pineda", "Ríos", "Toledo", "Ugarte", "Velasco", "Zapata",
	"Alarcón", "Briones", "Cuevas", "Dávila", "Ferrer", "Gallardo", "Heras", "Ledesma",
	"Mora", "Naranjo", "Ochoa", "Pardo", "Rueda", "Sepúlveda", "Tovar", "Varela"
]

static func names_for(gender: String) -> Array:
	return FEMALE_NAMES if gender == "F" else MALE_NAMES

## Elige un nombre de pila que no esté en `used_names` (comparación sin distinguir mayúsculas).
## Si todos estuvieran usados, añade un numeral romano ("Elisa II") para no repetir nunca.
static func pick_first_name(gender: String, rng: RandomNumberGenerator, used_names: Array = []) -> String:
	var used: Dictionary = {}
	for u in used_names:
		used[str(u).to_lower()] = true
	var pool: Array = names_for(gender)
	var candidates: Array = []
	for n in pool:
		if not used.has(str(n).to_lower()):
			candidates.append(n)
	if not candidates.is_empty():
		return str(candidates[rng.randi_range(0, candidates.size() - 1)])
	var base: String = str(pool[rng.randi_range(0, pool.size() - 1)])
	var numerals: Array = ["II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
	for num in numerals:
		var cand: String = "%s %s" % [base, num]
		if not used.has(cand.to_lower()):
			return cand
	return "%s %d" % [base, used.size() + 1]

static func pick_surname(rng: RandomNumberGenerator) -> String:
	return str(SURNAMES[rng.randi_range(0, SURNAMES.size() - 1)])

## Devuelve {"gender", "first", "last", "full"} con nombre de pila único respecto a `used_names`.
static func make_person_name(gender: String, rng: RandomNumberGenerator, used_names: Array = []) -> Dictionary:
	var first: String = pick_first_name(gender, rng, used_names)
	var last: String = pick_surname(rng)
	return {"gender": gender, "first": first, "last": last, "full": "%s %s" % [first, last]}
