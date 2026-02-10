# Registro de Cambios - 09/02/2026

Hoy se han realizado mejoras críticas en el sistema de Inventario y en la IA de los enemigos para el prototipo de Inmerisve Sim.

## 📦 Sistema de Inventario
- **Corrección de Visibilidad:** Se eliminó un contenedor intermedio que limitaba el tamaño del inventario a 40x40 píxeles. Ahora el `InventoryUI` se expande a pantalla completa, permitiendo la interacción en toda el área de la rejilla.
- **Teclas de Acceso:** Se configuraron las teclas **"I"** y **"Tab"** para alternar la visibilidad del inventario.
- **Mejoras en Arrastrar y Soltar (Drag & Drop):**
    - Se cambió el cálculo de coordenadas de `round()` a `floor()` para evitar que los ítems se desplacen incorrectamente.
    - Se implementó un parámetro `ignore_instance` en la detección de colisiones de la rejilla para que el ítem que se está arrastrando no bloquee su propio movimiento.
- **Ranuras Rápidas (Quick Slots):** Se implementó la asignación de ítems a las teclas 1-9 y su uso directo (ej. pociones) desde el teclado.

## ⚔️ Combate e IA de Enemigos
- **Navegación Robusta:** Se añadió un sistema de "fallback" que permite al enemigo perseguir al jugador en línea recta si no se detecta un `NavigationMesh` configurado en la escena.
- **Dirección de Ataque:**
    - El enemigo ahora rota visualmente para mirar al jugador antes de atacar.
    - Se añadió una comprobación lógica para que el ataque solo ocurra si el enemigo está realmente frente al jugador.
- **Alineación Visual (Bat/Cono):** 
    - Se ajustó el "offset" del sprite del murciélago para alinearlo con su base.
    - El cono de visión ahora rota 360 grados siguiendo la dirección real de la IA, eliminando la sensación de ataques "de lado".

## 🛠️ Infraestructura
- **Integración con GitHub:** Se inicializó el repositorio Git, se configuraron las credenciales de usuario (**lamsak01**) y se subió la versión actual del proyecto.

---
*Cambios aplicados por Antigravity (Assistant).*
