# Controles del juego (lista completa)

Revisada a mano en el código el 2026-11-09; cambios aprobados por el usuario el 2026-11-10 (trucos con Ctrl, sin teclas repetidas). **Antes de asignar una tecla nueva, mira aquí que esté libre y apúntala.**
El código de las teclas está repartido en `scripts/` **y** en `scenes/` (los paneles están en `scenes/ui_root.gd`):
si buscas en el código, busca en todo el proyecto.

## Moverse y pelear
| Tecla | Qué hace |
|---|---|
| W A S D | Caminar |
| Mayús | Correr |
| Espacio | Saltar |
| V | Rodar (en combate: golpe letal) |
| C / Ctrl | Sigilo (agacharse) |
| Clic izquierdo | Atacar |
| Clic derecho | Apuntar / acción secundaria |
| Q | Bloquear / parar (en combate: golpe no letal) |
| X | Empujar |
| R | Recargar arma de fuego; si no, cambiar la semilla activa |
| 1–9, 0 | Elegir herramienta de la barra |

## Mundo y paneles
| Tecla | Qué hace |
|---|---|
| E | Acción / hablar / recoger |
| G o rueda del ratón | Cambiar a otra acción u objetivo cercano |
| B | Atrancar o abrir la puerta de un local (cerca de una puerta) |
| F | Forzar cerradura o contraventana (cerca de una puerta) |
| Tab | Rueda de herramientas |
| I | Mochila |
| H | Ayuda de teclas (y panel de salud cuando lo indica el juego) |
| U | Salud / heridas |
| M | Mapa del valle |
| J | Vecinos |
| N | Caso (detective) |
| K | Habilidades |
| L | Diario de encargos |
| O | Crónica del pueblo |
| P | Vista en primera persona |
| + / − (y RePág / AvPág) | Zoom de la cámara |
| Alt (mirando a un vecino) | Más detalles del vecino |
| Esc | Cerrar el panel abierto |

## Teclas F
| Tecla | Qué hace |
|---|---|
| F5 / F12 | Guardar / cargar partida |
| F9 | Cámara 2D / 3D (con Mayús: visor de personajes 3D) |
| F11 | Pantalla completa |

## Trucos para probar (con Ctrl, para que no salten en una partida normal)
| Tecla | Qué hace |
|---|---|
| Ctrl+T | Adelantar el tiempo (unas 2 horas) |
| Ctrl+F1–F4 | Velocidad del reloj ×1, ×2, ×4 y ×8 |
| Ctrl+F7 | Cambiar el tiempo (despejado, lluvia…) |
| Ctrl+º (a la izquierda del 1) | **Modo pruebas**: energía, salud, hambre y oro infinitos |

No salen en la ayuda del juego (H). En la taberna, F1–F4 sin Ctrl siguen eligiendo juego.

**Ojo, dentro del editor de Godot:** F5 arranca el juego, F6 arranca la escena abierta, F7 lo pausa y F8 lo
detiene. Ahí esas teclas las coge Godot, no el juego; por eso el juego ya no usa F6 ni F8.

## Solo dentro de un menú (no chocan fuera de él)
- Diálogos: 1–9, W/S o flechas, Intro/Espacio, Esc.
- Hoguera/campamento: 1–6, E, S, N, Y, Intro, Esc.
- Gallinero: 1–3, Esc. Morgue y otros paneles del pueblo: 0–5, E, Intro, Esc.
- Juegos de la taberna: 1–9, F1–F4, A/D, Q, Z/X, flechas, Tab, Espacio, Intro, Esc.
- Rueda de herramientas: W/A/S/D o flechas, Espacio/Intro.

## Teclas libres (a 2026-11-09)
Libres (2026-11-10): **T, Y, Z** (Y y Z solo se usan dentro de menús), F1–F4 y F7 sin Ctrl (salvo en la taberna),
F6, F8, F10, º sin Ctrl, las teclas de puntuación y el teclado numérico (salvo + y −).
