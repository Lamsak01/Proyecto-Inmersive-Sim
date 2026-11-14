# Plan «todo en 3D, nada de 2D» (mandato del usuario, 2026-11-14)

> **Mandato:** absolutamente todo el juego pasa a 3D. Nada de 2D en el mundo ni en su lógica. El usuario lo ha pedido
> muchas veces; el estado híbrido («cuerpo en 3D, cerebro en el mapa») **no** cuenta como terminado.
> Detalle de lo que queda: `docs/specs/AUDITORIA_2D_A_3D.md`. Piezas del editor: `docs/specs/PLAN_LO_QUE_SE_VE.md`.

## Qué significa «terminado» (se mide, no se opina)
`bash tools/contar_2d.sh` cuenta los restos 2D (cuerpos, áreas, dibujos, cámara, navegación, píxeles, pisos de mentira,
estirón ×5…). **Punto de partida el 2026-11-14: 2.495. Terminado = 0.** Lo único plano que queda es la interfaz
(menús, HUD, paneles), como en cualquier juego 3D; la vista desde arriba se mantiene como **cámara 3D**.

## Reglas de honestidad (obligatorias para cualquier agente)
1. Nadie escribe «migrado», «terminado» o «3D de verdad» sin dar el número del contador antes y después.
2. Cada cierre de tarea de este plan dice **qué sigue siendo 2D** tras el cambio, sin que el usuario lo pregunte.
3. Prohibido añadir nada nuevo en 2D o en píxeles (ni «de momento»). Si un arreglo urgente lo necesitara, se avisa antes.
4. Los atajos (colocar a un vecino, copiar choques, niveles de piso) se nombran como atajos y se apuntan aquí para quitarlos.

## Tandas (cada una deja el juego jugable y la partida automática del Caso I en verde)
0. **Limpieza:** fuera de la escena principal lo muerto del 2D (baldosas, cajas, enemigos y vecino de prueba, caja de
   diálogo vieja) y las escenas que nadie usa. Poco.
1. **Sistemas dormidos** (>10.000 líneas tras el modo demo): decidir con el usuario si se archivan hasta después del
   Caso I (se migrarían al despertarlos) o se migran ahora. Sin esta decisión no se puede medir el final.
2. **Un solo espacio, en metros:** las posiciones del juego pasan a ser las de las piezas 3D; fuera el estirón ×5, el
   «mapa original» y las alturas en píxeles.
3. **Paredes, suelos y pisos reales:** choques 3D fijos sacados de las propias escenas (no copias por paso); pisos =
   altura real. Se borran `ChoquesCercanos3D`, `Suelo`/`PisosCasas` como reglas y los niveles de piso.
4. **Personajes 3D siempre:** jugador, vecinos, animales y bandidos son cuerpos 3D todo el tiempo (los lejanos, con
   simulación barata pero en 3D). Se borran `CuerposDelPueblo3D`, `CuerposCercanos3D` y los dibujos planos.
5. **Rutas con navegación 3D** (malla de navegación del mundo y de cada edificio). Se borran las rutas y listas de
   puertas a mano y los atajos de «colocar» vecinos (guardia mensajero, custodia).
6. **Piezas que dicen para qué sirven** (`PLAN_LO_QUE_SE_VE.md`, fases 1–4), ya en 3D: sillas, camas, puestos, la E.
7. **Ver, oír, golpear y la E con rayos y áreas 3D.** Se borran `Vista.gd` como reglas planas y el selector por ángulos.
8. **Escena raíz 3D:** el mundo deja de pintarse como imagen dentro de una escena 2D; cámara, luz de día y noche,
   lluvia y sonido en 3D.
9. **Datos fuera del código y objetos gigantes partidos**, según se toque cada sistema (auditoría B y C).

## Atajos vivos que hay que quitar (apuntar aquí los nuevos)
- Guardia mensajero y de custodia «colocados» cerca del jugador o en su puesto (`Case1Aviso.gd`, 2026-11-14) → tanda 5.
- Cuerpos 3D solo para 24 vecinos a ~8 m; se les quita si se atascan (`CuerposDelPueblo3D.gd`) → tanda 4.
- Dibujos 2D escondidos con capas en 1.ª persona (`WorldStage3D._ocultar_2d_tapado`) → tandas 4 y 8.
- Cama `cama_2` de la comisaría puesta a mano; zapato del caso como «Caja_383» con etiqueta → tanda 6.

## Coste honesto
Mucho: son los cimientos (vecino y pueblo suman ~12.000 líneas pensadas en píxeles). Semanas de trabajo por tandas, no
días. Cada tanda se cierra con el número del contador, sus pruebas y lo que queda.
