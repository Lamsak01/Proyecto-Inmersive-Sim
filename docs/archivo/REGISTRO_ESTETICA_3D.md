# Registro: nueva estética 3D (noche del 2026-11-05)

> Trabajo autónomo de Claude Code mientras el usuario duerme. Se escribe **a medida que avanza**, no al final.
> Objetivo: «parece retro pero no lo es». Referencias: Mouthwashing, Gloomwood, Signalis, Abiotic Factor y Blood West
> (texturas pequeñas y pixeladas, pocos polígonos, niebla, luz moderna).
> Día nostálgico y agradable; noche inquietante (solo el aspecto, nada paranormal).
> Permisos de esta noche: descargar recursos, hacer cambios, pasar pruebas y subir a `main` sin preguntar.
> La vista 2D (F9) no se toca.

## Progreso (más reciente abajo)

1. **Estado inicial revisado.** Último commit: `cd05c7d`. Gemini dejó sin guardar:
   - el borrado de `assests/curated_3d/village/` (92 archivos del Medieval Village MegaKit);
   - las carpetas nuevas `assests/curated_3d/fantasy_town/` y `assests/curated_3d/town_textures/`;
   - cambios en `AssetLibrary3D.gd` (+134 líneas) y `WorldStage3D.gd`;
   - unos 260 `.import` que genera Godot.

   En `assests/Assets 3d/` (ignorada por git) están los zips originales: Quaternius (Universal Base Characters, Modular
   Character Outfits Fantasy, Medieval Village MegaKit, Fantasy Props MegaKit), packs de Kenney (incluidos
   retro-textures-fantasy y retro-fantasy-kit) y descargas de Drive. Hay tres descargas `.crdownload` incompletas.

2. **Diagnóstico visual (capturas en `.godot/capturas/antes/`).** Con la cámara cenital (vista desde arriba) actual, el
   3D se ve como cajas de colores planos (naranja, turquesa, morado), sin texturas coherentes. Los personajes son
   pequeños, oscuros y casi iguales entre sí. La noche solo oscurece la pantalla. Lo que dejó Gemini **sin terminar**:
   - borró los modelos de pueblo (`curated_3d/village/`), pero el código sigue pidiendo de ahí puertas, ventanas,
     chimeneas, vallas y el carro. Ahora no aparecen;
   - extrajo Kenney Retro Textures Fantasy (`town_textures/`, texturas de 64 px pintadas a mano) y Kenney Fantasy Town
     (`fantasy_town/`), pero **no las usa en ningún sitio**.

   Las animaciones eran senos (balanceos matemáticos hechos a mano sobre los huesos), por eso parecían de muñeco.
3. **Herramienta de capturas** `tools/screenshot_3d.gd`: abre el juego con ventana, coloca al jugador en
   plaza, iglesia, lago, cementerio o de cerca, cambia la hora y guarda PNG. Ojo: Flatpak no ve `/tmp`; guarda dentro del
   proyecto (por ejemplo en `.godot/capturas/`).
4. **Animaciones reales descargadas** (CC0): Quaternius Universal Animation Library 1 y 2 Standard, desde OpenGameArt.
   Están en `assests/Assets 3d/descargas_claude/` (ignorado por git). Usan el mismo esqueleto que los personajes.
   `tools/bake_character_animations.gd` las adapta (retargeting: copiar el movimiento corrigiendo la postura de reposo
   de cada hueso) y guarda 28 animaciones en `assests/curated_3d/animations/ual_male.res` y `ual_female.res`.
5. **Animaciones conectadas** en `CharacterRig3D.gd`: con el pack cargado se usa un AnimationPlayer (reproductor de
   animaciones) en vez de los balanceos. Estados: quieto, andar, correr, trabajar (talar o golpear, segar, regar,
   arrodillarse), cargar, rezar (agachado), dormir (tumbado), KO (muerte), apuntar o disparar, golpe con arma o puño,
   y farol. Si faltara el archivo, vuelve solo al sistema anterior. Comprobado en captura: postura natural y brazos
   abajo.
6. **Texturas retro coherentes** (Kenney Retro Textures Fantasy, CC0, 64 px) en muros, tejados, suelos, caminos y plaza.
   Cada tipo de edificio tiene las suyas:
   - **muros:** entramado de madera (tabernas y tiendas), piedra (herrería y comisaría), ladrillo claro (iglesia,
     ayuntamiento y mansiones) y ladrillo pequeño (hospital);
   - **tejados:** teja roja, pizarra gris o paja.

   Gemini había borrado los modelos de puertas, ventanas, chimeneas, vallas y carro sin sustituirlos. Ahora:
   - las puertas y ventanas son paneles con textura pixelada;
   - las chimeneas vienen de Kenney Fantasy Town, la valla de hierro de Kenney Graveyard y el carro de los props de
     Quaternius.
7. **Pixelado global:** el 3D se dibuja a 640×360 en vez de 960×540 y los personajes a 64 px en vez de 96. Ambos van sin
   suavizado y con filtrado «nearest» (cada píxel se ve cuadrado, como en el pixel art). Todas las texturas se dibujan
   pixeladas y sin mapas de relieve (`AssetLibrary3D.make_retro`). Las de más de 256 px se reducen, salvo las de
   personajes y las paletas «colormap».
8. **Tejados visibles:** antes, cualquier vecino dentro abría el tejado, y con 100 vecinos casi ningún tejado se veía.
   Ahora un vecino dentro solo lo abre si el jugador está a menos de unos 150 px; el jugador y el ratón lo abren
   como siempre. **Es un cambio de comportamiento visible**, avisado aquí; se deshace en `_update_roof_cutaways_and_lighting`.
9. **Día y noche (etalonaje retro)** con `scripts/visuals/RetroPostFX.gd` y `shaders/retro_post_fx.gdshader`, solo con
   ventana; en las pruebas no se crea:
   - **día:** cálido y algo desvaído;
   - **atardecer:** largo y dorado, de 17:00 a 21:30;
   - **noche:** fría y oscura, con charcos de luz cálida en farolas encendidas, ventanas sin postigo (de 18:00 a 23:30)
     y un halo alrededor del jugador, más grande con farol;
   - **siempre:** viñeta (bordes oscurecidos), grano y color de 15 bits con tramado ordenado, como la PS1.

   La interfaz no se ve afectada. El tinte antiguo de `WorldClock.get_ambient_color` se suavizó con ventana para no
   oscurecer dos veces; en modo headless sigue igual.
10. **Bloque 1 cerrado y subido** (`f53f52a`). Pasan las cuatro pruebas: nombres, cobertura de diálogos (0 errores),
    simulador social y la batería completa. Notas de la bóveda: «Estética Retro 3D», «Assets de pago», diario del día y
    tablero. Sin tocar: `ideas sueltas.md` en la raíz, que no es mío.
11. **Bloque 2, personajes:**
    - contorno oscuro de 1 píxel alrededor de cada personaje 3D (`shaders/pixel_outline.gdshader`, respeta los
      destellos de daño y la transparencia), para separar la figura del suelo, como en Signalis;
    - luz de los personajes un poco más fuerte.

    Capturas de antes y después en `docs/capturas/`. Pasan las cuatro pruebas.

## Para el usuario, al despertar
- Mira `docs/capturas/estetica_antes_despues.jpg` (arriba día, abajo noche; izquierda antes, derecha ahora) y
  `docs/capturas/estetica_dia_atardecer_noche.jpg`.
- Lo más mejorable sigue siendo **la cara y el cuerpo de los personajes**. Son los de Quaternius, algo «de superhéroe».
  En la bóveda, «Assets de pago», hay una recomendación concreta (Villager NPC Pack, 4,99 $).
- Si la noche te parece demasiado oscura o el tramado demasiado visible, son dos números del shader; se ajustan en
  minutos.

---

# Segunda noche (2026-11-05 → 06): «que parezca 3D de verdad»

Lo que pidió el usuario tras probarlo:
- los animales no tienen texturas, y hay animales en una esquina del camino donde nunca hubo nada;
- los edificios parecen pixel art, no 3D; quiere algo que se vea en 3D;
- hay demasiadas cosas amontonadas donde aparece el jugador;
- al pasar de 2D a 3D (F9) se paran las animaciones del jugador;
- pensar cómo ampliar la aldea: más casas, algunas más separadas y con formas y tamaños distintos, no cuadrados
  clónicos;
- un lago más grande;
- muchas capturas de todo el pueblo.

## Progreso (más reciente abajo)
1. **Capturas de todo el valle** (`docs/capturas/noche2_valle_antes.jpg`; la herramienta tiene ahora el modo «rejilla»).
   Diagnóstico:
   - **No parece 3D por cuatro razones:**
     - el suelo (hierba) y los pinos del bosque son dibujos 2D;
     - los personajes se dibujan en una capa aparte, por encima del pueblo: no los tapan los edificios ni
       proyectan sombra;
     - no hay sombras;
     - los tejados son cajas planas apiladas.
   - **Los animales** del «rancho» eran adornos 3D que puso Gemini (vaca, caballo, burro) sin textura y en un cruce de
     caminos. No eran animales del juego.
   - **Amontonamiento en el inicio:** encima de la granja del jugador, Gemini puso un carro, dos cajas de fruta y un
     compostador 3D duplicando el de 2D. Además, el pozo y el compostador se ven dos veces (2D + 3D).
   - **Dos lagos:** el lago de verdad (donde se pesca) está en (-65, 105). El 3D que hizo Gemini está en (-250, -140),
     en otro sitio.
   - **Todos los edificios** son del mismo tamaño y van en fila a lo largo de calles rectas.

   Plan:
   - **Bloque A, limpieza:** quitar los adornos falsos, quitar los duplicados 2D/3D y arreglar la animación tras F9.
   - **Bloque B, 3D de verdad:** personajes dentro del escenario 3D, sombras del sol, suelo y árboles 3D, tejados a dos
     aguas y edificios distintos entre sí, y menos pixelado.
   - **Bloque C:** lago más grande, en su sitio.
   - **Bloque D:** plan escrito para ampliar la aldea. Mueve casas y caminos, así que espera la aprobación del
     usuario.
2. **Bloque A, limpieza:**
   - quitados los adornos falsos (vaca, caballo, burro y heno en el cruce; carro, cajas de fruta y compostador 3D
     encima de la granja del jugador);
   - los muebles 2D de dentro de los edificios se ocultan en 3D, porque el interior 3D ya los tiene;
   - el pozo 2D queda debajo del 3D.
3. **Fallo de F9 encontrado:** al volver de 2D a 3D, la imagen del jugador se quedaba congelada. Su «ventanita» de
   render quedaba desactivada y nada la volvía a activar; los vecinos sí se reactivaban. Arreglado en el modo antiguo,
   y además ya no hace falta (punto 4).
4. **Personajes dentro del escenario 3D** (`CharacterAvatar3D._attach_to_stage`): cada muñeco vive en el mismo mundo
   que los edificios. Las paredes los tapan, proyectan sombra, el sol y las farolas los iluminan, y desaparecen las 100
   ventanitas de render.
   - La escala vertical se estira igual que la del escenario, para que se vean con sus proporciones.
   - Al recibir daño parpadean (antes se teñían de rojo); en sigilo se vuelven semitransparentes.
   - Si el escenario se reconstruye al cargar partida, el muñeco se vuelve a crear solo.
   - Medido: 90–136 fps (imágenes por segundo) en la plaza.
5. **3D de verdad:**
   - sombras del sol, que cae desde arriba a la izquierda;
   - suelo 3D de hierba bajo todo el valle, más oscuro en el bosque, seco en la llanura oeste y con barro y agua en la
     ciénaga;
   - pinos talables, pinos decorativos y vetas de mineral con modelo 3D (tocón o roca pequeña al agotarse);
   - resolución interna 1280×720;
   - tejados a dos aguas, con ala más baja en los edificios anchos, porche, chimenea y campanario en la iglesia;
   - muros de altura distinta en cada edificio;
   - los vecinos ya no abren el tejado: solo el jugador al acercarse y el ratón.
6. **Lago:** unas tres veces más grande, hacia el oeste y el sur. Sigue en su sitio de verdad, con el muelle en la
   orilla este, el Lavadero en la norte y el Mirador en la sur. Tiene orilla de arena, agua pixelada y sauces. Se quitó
   el lago 3D falso que Gemini había puesto en otro sitio, y el lavadero 3D se movió a su posición real.
   El polígono está en `FishingSpot.LAKE_WATER_WORLD` y lo comparten el 2D y el 3D.
7. **Noche** un poco más clara: luz de luna y etalonaje.
8. **Plan para ampliar la aldea** en `docs/PLAN_AMPLIAR_ALDEA.md`, pendiente de aprobación.
9. Pasan las cuatro pruebas. Capturas: `docs/capturas/noche2_valle_antes.jpg`, `noche2_valle_despues.jpg` y
   `noche2_plaza_dia_noche.jpg`.
