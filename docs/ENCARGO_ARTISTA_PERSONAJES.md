# Encargo para el artista — Kit de personajes de «La Placa de Petri»

> Preparado el 2026-11-07. Imágenes de referencia en `docs/referencias_personajes/`. Las imágenes están hechas con IA:
> sirven para el ambiente y la época, **no para copiarlas al detalle**; tienen errores (ver «Qué evitar»).

## 1. El juego en pocas líneas
- Simulador inmersivo en 3D, en primera persona, hecho con **Godot 4**. Un pueblo vivo de hasta **100 vecinos** con
  oficios, rutinas y relaciones. El jugador investiga crímenes, se infiltra, roba y se disfraza.
- **No queremos un modelo único por personaje.** Queremos un **kit modular** con el que se arman todos los vecinos y el
  jugador, como el creador de personajes de *Skyrim*. Solo algunos personajes principales tendrán piezas hechas a mano.
- **Cualquier prenda vale para cualquier personaje**, jugador incluido: robar el uniforme de un guardia y ponérselo
  tiene que funcionar y verse.

## 2. Época y ambiente (definitiva, 2026-11-08)
- Mundo propio **tecnofeudal / medieval-balístico**: sociedad y arquitectura **feudales** (piedra, entramado de madera,
  gremios, señores) con **tecnología analógica de los años 70/80 y armas de fuego militares**: fusiles de asalto,
  radios de baquelita, focos de vigilancia, tractores y generadores diésel, terminales de pantalla verde o ámbar,
  cables gruesos clavados en los muros, alambre de espino y sacos terreros.
- Todo **tosco y gastado**: hierro forjado, piedra, madera, hormigón, baquelita, lona.
- Referentes: *Trench Crusade*, *Thief*, *Kenshi*; para el acabado *Mouthwashing* y *Gloomwood*.
- **Nada de**: pantallas planas, móviles, coches modernos ni engranajes dorados de estilo victoriano (*steampunk*).
- Las armas, inventadas «tipo» fusil de asalto, no copias de modelos reales con nombre.

## 3. Estilo visual
- **Retro tipo PlayStation 1**: pocos polígonos, texturas pequeñas pixeladas, todo el detalle pintado en la textura.
- Tono **oscuro y sucio**: ropa gastada, manchas, óxido, remiendos.
- Debe verse bien **de noche con niebla y de día con luz clara**: gran parte del juego pasa de día.

## 4. Especificaciones técnicas
- Formato **.glb**. Motor: Godot 4.
- Personaje completo vestido: unos **500–800 triángulos** (orientativo; dinos si necesitas más).
- Texturas de **128×128 o 256×256 px**, pensadas para verse con filtrado *nearest* (píxel duro). Sin *normal maps*:
  todo en el color base.
- **Un único esqueleto humanoide compartido** por todos (hombre y mujer, jugador y vecinos). Que sea compatible con el
  perfil humanoide de Godot para poder reutilizar animaciones (andar, sentarse, trabajar, pelear, caer).
- Cada prenda va **pesada sobre ese mismo esqueleto**, como malla aparte, para ponerla y quitarla.

## 4b. Huecos de la armadura (importante para el combate)
El juego comprobará los impactos por zonas del cuerpo pegadas a los huesos: cabeza, cara, cuello, axilas, codos,
manos, ingles, rodillas, pecho, vientre, espalda y piernas. Cada armadura debe dejar **huecos creíbles** (visera
que se abre, axilas, ingles, corvas, juntas de codo y rodilla) y conviene que el esqueleto tenga huesos claros para
esas zonas. Indica en cada pieza de armadura qué zonas cubre.

## 5. Ranuras del cuerpo
Cabeza · Pelo o sombrero · Torso · Capa exterior (abrigo, armadura) · Piernas · Pies.
Una prenda de capa exterior debe poder ir **encima** de cualquier prenda de torso sin atravesarla. Si hace falta,
indica qué partes del cuerpo o de la prenda de debajo se ocultan.

## 6. Qué incluye el kit
1. **Cuerpos base**: hombre y mujer, con *shape keys* de complexión (delgado, corpulento, ancho) y que permitan gente
   mayor. **Cuerpos normales, no musculosos de superhéroe.**
2. **Cabeza común**: una sola malla para todos, con unas **10 *shape keys*** de rasgos (nariz, mandíbula, pómulos,
   mentón) combinables.
3. **Capas de cara** en PNG transparente que se superponen por código: arrugas, ojeras, cicatrices, barbas.
4. **Ojos** en mallas separadas, con hueso cada uno, para que la mirada se pueda dirigir.
5. **Expresiones** (*shape keys* que se suman): parpadeo, cejas abajo, cejas arriba, cejas tristes, boca abierta,
   sonrisa, boca hacia abajo, boca apretada. Son para los **interrogatorios**: la cara delata al que miente.
6. **Peinados** en escala de grises (se tiñen por código). Empezar con pocos.
7. **Ropa** en 4 plantillas de volumen, en tonos neutros que se puedan teñir o cambiar de textura por oficio o bando:
   - **A — Civil / gremios:** túnica o camisa de lino, pantalón grueso, delantal de cuero pesado, botas militares.
   - **B — Chaqueta:** gambesón acolchado, chaleco de cuero con hebillas o chaqueta corta de paño.
   - **C — Abrigo:** gabardina larga gastada o tabardo, con hombreras metálicas opcionales (detective, mercenario).
   - **D — Armadura / guardia:** cota de malla, coraza de acero (hace de chaleco antibalas) y correas de lona para
     cargadores y radio; también delantal pesado de herrero o carnicero.
8. Algunos **sombreros y cascos** (de estilo medieval, algunos con auriculares de radio), una **máscara antigás** y un par
   de **botas**.

## 7. Ropa hecha por el dueño del juego
El dueño del juego quiere **crear él mismo ropa nueva** más adelante (uniformes de policía, de bandas, de cada facción).
Entrega también:
- El **cuerpo base de referencia** (maniquí) y el archivo de origen (por ejemplo, de Blender) de cada prenda.
- Una **guía corta**: cómo se hace una prenda nueva para que encaje en el cuerpo, se pese al esqueleto y no atraviese
  la piel ni otras prendas al moverse.

## 8. Primera entrega (prueba antes de encargar el resto)
- Esqueleto, cuerpos base de hombre y mujer, cabeza común con algunos rasgos y 2–3 expresiones, 2 peinados y **3–4
  prendas** (al menos una de capa exterior encima de una de torso).
- Con eso montaremos **dos vecinos distintos dentro del pueblo** para ver cómo quedan de día y de noche. Si funciona,
  se encarga el resto.

## 9. Qué evitar
- Cuerpos musculosos de superhéroe en el kit base.
- Ropa moderna de ciudad (vaqueros, chupas de cuero, zapatillas) y uniformes de policía actuales. Lo militar sí, pero
  siempre mezclado con lo medieval (coraza en vez de chaleco táctico moderno).
- Las imágenes `01`–`06` son de una época descartada: valen solo por el acabado de caras y el kit, no por la época.

## 10. Imágenes de referencia (`docs/referencias_personajes/`)
- **`07_DEFINITIVA_comisaria`**, **`08_DEFINITIVA_granja_noche`**, **`09_DEFINITIVA_herreria`** — la época y el ambiente
  buenos. Fíjate en el guardia: casco medieval, cota de malla, coraza, correas y fusil.
- `05_epoca_kit_cuerpo_ropa` — idea de cómo presentar el kit (piezas sueltas).
- `03_expresiones` — idea de los gestos de la cara.
- Todas están hechas con IA y tienen errores: son ideas, no planos.
