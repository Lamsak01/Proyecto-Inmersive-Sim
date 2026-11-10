# Editor del mapa — guía para el usuario

**Abrirlo:** en Godot, panel de archivos (abajo a la izquierda) → carpeta `mapa` → doble clic en `EditorMapa`.
Verás el valle desde arriba: verde = suelo, marrón = edificios (con su nombre), beige = caminos,
puntos verdes = árboles, gris = rocas, azul = agua.

## Mover el río
- En la lista de la izquierda (Escena), despliega **Rio**: cada **Punto** es un punto del cauce, de norte a sur.
- Pulsa **W** (herramienta mover) y arrastra la cruz de un punto. El río se redibuja al momento.
- **Más ancho o más estrecho:** selecciona el punto y, a la derecha (Inspector), cambia **Ancho**.
  Una persona mide unos 10, un camino unos 25, el río en el pueblo unos 60.
- **Añadir un punto:** selecciona uno y pulsa **Ctrl+D** (duplicar); arrastra el nuevo a su sitio.
- **Quitar un punto:** selecciónalo y pulsa **Supr**.
- **Rio → Curvas naturales:** 1 = orillas irregulares como hasta ahora; 0 = el agua pasa justo por tus puntos.

## Puentes y vados
- Despliega **Cruces**. Cada uno es un sitio por donde se cruza el río (en el resto no se puede pasar).
- Arrástralo encima del agua. En el Inspector: nombre, tipo (vado, pasarela de madera, puente de piedra), ancho y largo.
- Para uno nuevo: duplica otro (**Ctrl+D**) y cámbiale el nombre. No cambies «Id interno».

## Avisos en rojo
- **Edificio con borde rojo:** el agua lo pisa. Aparta el río.
- **Puente con borde rojo:** no llega de orilla a orilla. Hazlo más largo.

## Probarlo
Guarda con **Ctrl+S** y pulsa **F5**: el juego ya usa tu río (agua, orillas, vecinos y río 3D).
Si algo sale mal: el botón deshacer (**Ctrl+Z**) o pide a Claude que vuelva al río original.
