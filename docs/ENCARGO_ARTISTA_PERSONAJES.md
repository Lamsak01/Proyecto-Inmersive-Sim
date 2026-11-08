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

## 2. Época y ambiente
- Mundo propio **anacrónico**: **80 % medieval o preindustrial** (piedra, madera, entramado, gremios, jubones, capas,
  cuero, armaduras) y **20 % tecnología analógica tosca** (terminales de pantalla abombada verde o ámbar en cajas de
  hierro y latón, tarjetas perforadas, cables gruesos clavados en los muros, porras eléctricas con batería).
- La tecnología es **rara y cara**: solo la tienen el poder (ayuntamiento, guardia), los ricos y los contrabandistas.
  La gente corriente vive con velas y herramientas de mano.
- Referentes: *Thief II*, *Dishonored*, *Arcanum*, y para el acabado *Mouthwashing* y *Gloomwood*.
- **Nada moderno**: ni vaqueros, ni chalecos antibalas, ni chupas de cuero, ni zapatillas.

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
   - **A — Civil / gremios:** camisa o túnica de manga ancha, pantalón de tela gruesa metido en botas altas.
   - **B — Chaqueta:** jubón acolchado, chaleco de cuero con hebillas o chaqueta corta de paño.
   - **C — Abrigo:** gabardina larga de cuero, tabardo o capa corta (detective, guardia, noble).
   - **D — Armadura / oficio:** peto de cuero, coraza oxidada o delantal pesado (herrero, carnicero, facción).
8. Algunos **sombreros y cascos** y un par de **botas**.

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

## 9. Qué evitar (errores de las imágenes de referencia)
- Cuerpos musculosos de superhéroe en el kit base.
- Máquinas en manos de gente corriente (una criada con un ordenador portátil rompe la regla de la época).
- Ropa moderna: las imágenes `01`–`03` valen solo por el estilo, no por la ropa.

## 10. Imágenes de referencia (`docs/referencias_personajes/`)
- `04_epoca_terminal_interior` — ambiente: vela junto a terminal verde, cables en la piedra.
- `05_epoca_kit_cuerpo_ropa` — idea del kit (cuerpos, chaleco, gabardina, coraza con aparato, botas, peinados, cascos).
- `06_epoca_cuatro_vecinos` — criada, comerciante rico, guardia con porra eléctrica, saboteador con tenazas.
- `01`–`03` — solo estilo de acabado y de caras con gestos (ropa moderna: no usar).
