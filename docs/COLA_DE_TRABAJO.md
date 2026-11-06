# Cola de trabajo (la lleva el supervisor, Claude Code)

> Orden acordado con el usuario la noche del 2026-11-06. Un bloque cada vez: Antigravity lo hace, el supervisor lo revisa
> y lo prueba, y solo entonces se pasa al siguiente. **Integridad antes que cantidad.**

| # | Bloque | Estado |
|---|--------|--------|
| 1 | COMBATE-1: rodar (Espacio) y parar (Q), golpes enemigos con aviso | en marcha |
| 2 | ANIM-1: arreglar animaciones (pasos que patinan al andar; armas sujetas al revés, girar 180°) — aviso del usuario | pendiente |
| 3 | P1: tu tienda propia y su dependiente | pendiente |
| 4 | P2: la carreta física | pendiente |
| 5 | P3: caravanas comerciales y de contrabando | pendiente |
| 6 | P4: cenas, fiestas y banquete de paz | pendiente |
| 7 | P5: rentas, encargos y desfalcos en su sitio | pendiente |
| 8 | P6: peleas clandestinas en un sótano de la taberna, sabotajes nocturnos y expediciones | pendiente |
| 9 | Inventario de todo lo demás planeado, ordenado de fácil a difícil (`docs/PLAN_ORDENADO.md`) y empezar por lo fácil | pendiente |

Para mañana con el usuario: bucle jugable de la primera beta (borrador en `docs/PROPUESTA_BETA.md`).

## Detalle del bloque ANIM-1 (aviso del usuario, 2026-11-06)

1. **Pasos que patinan:** al andar, los personajes 3D (jugador y vecinos) parecen deslizarse: la velocidad a la que se
   reproduce la animación de andar/correr no cuadra con lo que avanzan por el mapa. Mide cuánto avanza un paso de la
   animación «walk» y «run» a la escala del escenario (`CharacterAvatar3D.STAGE_K`) y calcula la velocidad de
   reproducción a partir de la velocidad real (`CharacterRig3D._pick_clip` usa ahora `clampf(_speed_ratio, 0.7, 1.3)`,
   con `speed_ratio = velocidad / 110`). Que los pies no resbalen al andar ni al correr, también a caballo no aplica.
2. **Armas al revés:** las armas y herramientas en la mano se ven giradas 180°. Gíralas para que se sujeten bien (revisa
   todas: espada, hacha, pico, martillo, hoz, arco, arcabuz, caña, regadera, farol).
3. Fotos con `tools/screenshot_3d.gd` (sitio «retrato» o «cerca») de antes y después, y las pruebas de siempre.
