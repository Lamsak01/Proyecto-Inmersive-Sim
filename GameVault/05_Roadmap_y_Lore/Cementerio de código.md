---
tipo: "historia-desarrollo"
estado: "archivado"
tags:
  - "archivado"
  - "historia-desarrollo"
fuente: "Biblia §13"
---
# Cementerio de código

En `archived_systems/` (con `.gdignore` para que Godot no los cargue) se conservan como referencia 4 subsistemas del prototipo de febrero de 2026 (`commit dbfffdd`):

| Carpeta en `archived_systems/` | Qué hacía originalmente | Por qué se archivó y cómo se resolvió después |
|---|---|---|
| `combat_armor/` | Primer prototipo de piezas de armadura acopladas al combate temprano. | Reemplazado en la Fase 6 por el sistema limpio de **4 ranuras de armadura (`Casco, Pecho, Piernas, Botas`) en 3 Tiers** integrado directamente en `SimpleInventory` y `HealthComponent`. |
| `power_system/` (`addons/powergrid/`) | Cables físicos nodo a nodo, transformadores y charcos de agua electrificados (`ConductiveArea`) para electrocutar guardias en sigilo. | Era costoso por fotograma y demasiado centrado en puzles de infiltración. Se sustituyó en el Bloque `PJ.1` por la **Red Eléctrica Lógica de 3 Circuitos** (`farolas, riego, generador`) conectada a la vida del pueblo y a las terminales. *(Los charcos conductivos pueden rescatarse cuando se diseñe el combate con armas de chispa/voltaicas).* |
| `grid_inventory/` | Inventario por cuadrícula matricial (`GridInventory`) con rotación de objetos estilo *Resident Evil 4 / Tarkov*. | Añadía fricción innecesaria de microgestión de casillas frente al ritmo de simulación social y de gremios. Se sustituyó por `SimpleInventory` + la **Rueda Radial de 8 Herramientas (`[Tab]`)**. |
| `interiors_and_teleporters/` | Escenas separadas (`House1Interior.tscn`) conectadas mediante `SceneTeleporter.gd`. | Cambiar de escena rompía o congelaba la simulación física en tiempo real del resto del pueblo. Se descartó en favor de **interiores abiertos en el mismo mapa continuo** y **capas verticales (`-1/0/+1`)** estilo *Project Zomboid*. |
