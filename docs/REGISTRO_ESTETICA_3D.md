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
