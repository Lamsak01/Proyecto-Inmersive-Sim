---
tipo: "sistema"
area: "mundo"
estado: "implementado"
codigo: "PL.1-PL.2"
tags:
  - "mecanica"
  - "mundo"
  - "sistema"
fuente: "Biblia §9.4"
---
# Incursiones y Defensa

> Sección original: *Incursiones con Motivo Real y Defensa Física del Pueblo (`PL.1–PL.2`, `c456869`)*

```mermaid
flowchart LR
    Atraccion["💰 Atracción (Arcas > 300, Rutas activas, Asentamiento)"] --> Amenaza["🔥 Amenaza Diaria (0..100)"]
    Defensa["🛡️ Defensa (Guardias + Milicia + Atalaya + Arcabuz)"] -. "Frena amenaza (-Defensa/3)" .-> Amenaza
    Amenaza -- "Amenaza >= 40" --> Aviso["📯 Aviso Matutino con Motivo Real"]
    Aviso -- "16:00 h" --> Puerta["⚔️ Guardia y Voluntarios van al Camino del Este"]
    Puerta -- "18:00 h" --> Choque["🏁 Resolución: Victoria o Saqueo + Heridos"]
```
- **Nada de Temporizadores Fijos:** Los asaltantes sólo se fijan en el valle si hay botín que robar (`raid_lure`: arcas municipales por encima de **300 de oro**, rutas comerciales activas o el asentamiento fronterizo).
- **Aviso Matutino:** Cuando la amenaza supera `40`, una mañana los exploradores avisan del ataque inminente explicando el **motivo real** (*«atraídos por el oro de las arcas»*, *«por las caravanas de Paso Alto»*, etc.).
- **Defensa Física a las 16:00 y Choque a las 18:00:** A las `16:00`, los guardias y hasta **3 vecinos voluntarios** con coraje/agresividad caminan físicamente hacia el **Camino del Este (`RAID_GATE_POS`)** con el encargo `raid_defend`. A las `18:00` se resuelve el combate: si el pueblo gana, la amenaza cae y sube el orgullo cívico; si pierde, los asaltantes saquean parte de las arcas y los defensores quedan heridos de verdad.

## Notas de diseño
-
