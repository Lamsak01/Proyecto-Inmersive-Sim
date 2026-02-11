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

# Registro de Cambios - 10/02/2026

Hoy se ha implementado el **Sistema de Misiones** y se ha integrado el **Sistema de Energía (PowerGrid)**, añadiendo mecánicas sistémicas al juego.

## 📜 Sistema de Misiones y Objetivos
- **HUD de Objetivos:** Se creó una interfaz visual (`ObjectiveHUD`) que muestra las misiones activas en pantalla.
- **Gestor de Objetivos:** Implementación de `ObjectiveManager` (Autoload) para gestionar el estado de las misiones globalmente.
- **Misión de Prueba:** "Find the Iron Sword" - Una misión funcional que se completa automáticamente al recoger el ítem específico.

## ⚡ Sistema de Energía (PowerGrid)
- **Integración del Addon:** Se incorporó el sistema de redes de energía.
- **Nuevos Componentes Interactivos:**
    - **Generador (`Generator.tscn`):**
        - Textura procedural metálica con efecto de brillo al activarse.
        - Área de interacción y colisión ajustadas a su tamaño visual (64x64).
        - Interactuable por el jugador (ON/OFF).
    - **Puerta Electrónica (`PoweredDoor.tscn`):**
        - Se abre automáticamente cuando recibe energía.
        - **Indicador de Estado:** Luz roja (sin energía) / Luz verde (con energía).
        - **Ajuste de Escala:** Redimensionada para coincidir con las puertas estándar del juego.
    - **Cable (`Cable.tscn`):**
        - Conexión visual entre componentes.
        - Efecto de pulso de energía (cyan) animado mediante shader/código.

## 🔧 Correcciones Técnicas
- **Autoloads:** Se solucionaron conflictos de nombres de clases globales (`ObjectiveManager`).
- **Escenas:** Se corrigieron errores de sintaxis y dependencias en `World.tscn` y `PoweredDoor.tscn`.
- **Validación:** Se actualizó `InventoryTestHelper` para verificar automáticamente el estado del sistema de energía al inicio.

---
*Cambios aplicados por Antigravity (Assistant).*
