---
tipo: sistema
area: arte
estado: parcial
codigo: "scripts/visuals/ (WorldStage3D, CharacterRig3D, CharacterAvatar3D, AssetLibrary3D, RetroPostFX), shaders/retro_post_fx.gdshader"
tags:
  - sistema
  - arte
---
# Estética Retro 3D

## Qué hace
- Da al valle en 3D un aspecto **«parece retro pero no lo es»**: texturas pequeñas y pixeladas, pocos polígonos,
  colores de 15 bits con tramado (como la PS1), pero con luz y animaciones modernas.
- **De día**, nostálgico y agradable: luz cálida, colores algo desvaídos, como una foto vieja.
- **Al atardecer**, largo y dorado, de 17:00 a 21:30.
- **De noche**, inquietante: oscuridad fría con charcos de luz cálida en farolas, ventanas encendidas y alrededor del
  jugador (más grande con farol). De momento solo es aspecto; nada paranormal.

## Cómo se ve en el mundo (sin abrir menús)
- Casas con muros de entramado, piedra o ladrillo y tejados de teja, pizarra o paja, según el tipo de edificio.
- Vecinos con animaciones reales de andar, correr, talar, segar, regar, cargar, rezar, dormir, caer, apuntar y
  golpear.
- El 3D y los personajes se dibujan a baja resolución con píxeles cuadrados, para casar con el pixel art 2D.
- Los tejados se ven en todo el pueblo; solo se abren los de los edificios cercanos al jugador.

## Referentes
- Mouthwashing, Gloomwood, Signalis, Abiotic Factor y Blood West. Ver [[Referentes]].

## Recursos usados (todos CC0)
- Quaternius Universal Animation Library 1 y 2 (Standard), Universal Base Characters y Modular Outfits.
- Kenney Retro Textures Fantasy, Fantasy Town Kit y Graveyard Kit.
- Opciones de pago: [[Assets de pago]].

## Conexiones con otros sistemas
- [[Supervivencia y Clima]] (hora y tiempo), [[Red Eléctrica]] (farolas), [[Capas Verticales y Alcantarillas]] (tejados).

## Notas de diseño
- 2026-11-05 (Claude Code): primera versión completa. El registro paso a paso está en `docs/REGISTRO_ESTETICA_3D.md`.
- Los personajes siguen siendo los de Quaternius (cuerpo algo «de superhéroe»). Es lo más mejorable; ver [[Assets de pago]].
- Idea pendiente del usuario: cosas raras o paranormales en la oscuridad (sin decidir).

## Tareas
- [x] Animaciones reales en vez de balanceos
- [x] Texturas retro coherentes en edificios, caminos y plaza
- [x] Pixelado global del 3D y de los personajes
- [x] Día nostálgico y noche inquietante con charcos de luz
- [ ] Personajes con más estilo (tipo Signalis)
- [ ] Hierba y árboles 3D a juego (ahora la hierba es el pixel art 2D)
