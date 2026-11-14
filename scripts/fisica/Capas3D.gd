extends RefCounted

## Capas3D: las capas de choque del mundo 3D, en un solo sitio y sin depender de nada (paso a 3D, tanda 4b).
## Uso: const Capas3D = preload("res://scripts/fisica/Capas3D.gd")

const PROTA: int = 1     ## el cuerpo del protagonista
const VECINO: int = 2    ## los cuerpos que estorban (vecinos, animales grandes): no chocan entre sí; sí con el protagonista
const MUROS: int = 4     ## las paredes del mundo: frenan al protagonista y a los demás
const PEQUENO: int = 8   ## los animales pequeños: nadie choca con ellos; ellos sí con las paredes
const AGUA: int = 16     ## el agua: solo frena a los demás (el protagonista entra y nada)
const DIANAS: int = 32   ## las zonas donde se puede herir a alguien (solo las miran las búsquedas de golpes)
