# Controles del juego (lista completa)

Revisada a mano en el código el 2026-11-09. **Antes de asignar una tecla nueva, mira aquí que esté libre y apúntala.**
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
| P / F6 | Vista en primera persona |
| T | Adelantar el tiempo (unas 2 horas) |
| + / − (y RePág / AvPág) | Zoom de la cámara **y** velocidad del reloj a la vez (se pisan, fallo conocido) |
| Alt (mirando a un vecino) | Más detalles del vecino |
| Esc | Cerrar el panel abierto |

## Teclas F
| Tecla | Qué hace |
|---|---|
| F1–F4 | Velocidad del reloj ×1, ×2, ×4 y ×8 (en la taberna: elegir juego) |
| F5 / F12 | Guardar / cargar partida |
| F7 | Cambiar el tiempo (despejado, lluvia…) |
| F9 | Cámara 2D / 3D (con Mayús: visor de personajes 3D) |
| F10 | Igual que F9 |
| F11 | Pantalla completa |
| **º** (a la izquierda del 1) o F8 | **Modo pruebas**: energía, salud, hambre y oro infinitos |

**Ojo, dentro del editor de Godot:** F5 arranca el juego, F6 arranca la escena abierta, F7 lo pausa y F8 lo
detiene. Ahí esas teclas las coge Godot, no el juego: para el modo pruebas usa **º**, y para la primera persona, **P**.

## Solo dentro de un menú (no chocan fuera de él)
- Diálogos: 1–9, W/S o flechas, Intro/Espacio, Esc.
- Hoguera/campamento: 1–6, E, S, N, Y, Intro, Esc.
- Gallinero: 1–3, Esc. Morgue y otros paneles del pueblo: 0–5, E, Intro, Esc.
- Juegos de la taberna: 1–9, F1–F4, A/D, Q, Z/X, flechas, Tab, Espacio, Intro, Esc.
- Rueda de herramientas: W/A/S/D o flechas, Espacio/Intro.

## Teclas libres (a 2026-11-09)
Ninguna letra queda libre del todo. Libres: **Y, Z** (solo se usan dentro de menús), F10 (repite F9), las teclas de
puntuación y el teclado numérico (salvo + y −).
