# Registro del editor del mapa 3D (para el usuario y cualquier agente)

Escrito por Claude Code (2026-11-10). Detalle técnico en `docs/PLAN_EDITOR_MAPA.md`.

## Qué decidió el usuario (2026-11-10)
- **Demo del Caso I en pausa.** Antigravity se quedó sin cupo y Claude Code tiene poco. Prioridad: que el usuario pueda
  **editar todo el mapa a mano en Godot**, en 3D. «Arreglar la lógica» (vecinos, rutas, pistas, objetos) va **después**.
- El mundo pasa de «generado por código» a **escenas**: mejor para el arte, para una segunda ciudad y para un mapa más
  grande (cargar por zonas). Se hace por partes, subiendo a GitHub cada una.
- Quiere mover **absolutamente todo**. Los recursos que compre van a `mis_recursos/` y se colocan en el editor.
- Ramas («branches»): objeto nuevo que dan los matorrales; el usuario decidirá su uso.

## Cómo se usa
- Abrir `mapa/Mundo3D.tscn` (carpeta «mapa», doble clic) y pulsar «3D». Volar: clic derecho + WASD. Elegir: clic.
  Mover: W y flechas roja/azul. Deshacer: Ctrl+Z. Guardar: Ctrl+S. Probar: ▶ arriba a la derecha.
- Carpetas: **Vegetacion** (Arboles talables, Rocas, Troncos, Plantas, Vetas que se pican), **Decorado** (puentes, muelle,
  vallas, corrales, caminos, bancos… por zonas), **Edificios** (se mueven enteros con su interior), **Objetos** (farolas,
  pozos, tablón y 158 «anclas»: zonas de uso, letreros, casas de animales, setas, pistas fuera de edificios),
  **Decoracion** (lo que coloque el usuario de `mis_recursos/`).
- Complemento «Godot Asset Placer»: activarlo en Project → Project Settings → Plugins.
- Si Godot tenía Mundo3D abierto cuando Claude lo cambió: cerrar la pestaña **sin guardar** y volver a abrirla.

## Cómo sigue la lógica a lo que se mueve («anclas», `mapa/anclas.gd`)
Todo lo que el juego crea en el mapa 2D (dibujos, zonas de uso, paredes invisibles, letreros, polígonos) dentro de la zona
original de un edificio, objeto-ancla u objeto de Decorado que el usuario movió, se crea desplazado lo mismo. Probado:
mover una pista del claro y el molino mueve sus zonas de uso y el interior 3D del molino.

## Lo que falta (en orden)
1. **Girar** edificios y objetos: girar en el editor todavía no gira en el juego (solo se mueve).
2. **Interiores pieza a pieza**: los muebles se mueven con su edificio, pero no uno a uno.
3. Cosas que no pasan por las funciones de creación y no siguen a nada: el campamento del jugador (oculto en la demo),
   huertos, gallinero y animales de granja, el pozo de la ronda norte si no aparece en «Objetos», alcantarillas y club
   clandestino.
4. **Lógica** (después, decisión del usuario): rutas y puestos de trabajo de los vecinos, caminos del mapa pequeño y del suelo
   aplanado (los caminos 3D se mueven pero el minimapa no), pistas del Caso I que el código busca por coordenadas fijas
   (p. ej. distancia al claro en VillageManager), recolocar el Caso I tras mover edificios.
5. Suelo, agua del río y del lago y orillas siguen en código a propósito (el río se edita con `mapa/EditorMapa.tscn`).
