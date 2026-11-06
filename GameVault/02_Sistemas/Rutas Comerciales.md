---
tipo: "sistema"
area: "economia"
estado: "implementado"
codigo: "PK.1-PK.2"
tags:
  - "mecanica"
  - "mundo"
  - "sistema"
fuente: "Biblia §9.3"
---
# Rutas Comerciales

> Sección original: *Rutas Comerciales Exteriores e Investigación Tecnológica (`PK.1–PK.2`)*

- **3 Rutas Comerciales (`PK.1`):**
  1. **Paso Alto** (hierro, carbón y herramientas pesadas).
  2. **Puerto Fluvial** (pescado salado, telas finas y especias).
  3. **Vega del Sol** (grano, ganado y semillas).
  - Abrirlas cuesta oro de las arcas o de los gremios, trae caravanas periódicas y **aumenta el atractivo del valle (y también la codicia de los asaltantes exteriores)**.
- **Árbol de Investigación en el Taller (`PK.2`):**
  1. **Engranajes Hidráulicos** (aumenta la producción de molino y talleres).
  2. **Cerraduras de Precisión** (refuerza la seguridad de puertas y cofres del pueblo).
  3. **Condensadores Voltaicos** (estabiliza la red eléctrica y reduce fallos del generador).

## Notas de diseño
- 2026-11-05 (Claude Code): cada intercambio deja 4 de arancel a las arcas; el comprador paga 1 por unidad importada; el fondo de cada pueblo de fuera se repone +20 cada lunes (hasta 90). Es la vía de entrada de oro desde fuera del valle.
- 2026-11-06 (Antigravity, Bloque P3): las caravanas comerciales son ahora físicas: una vez por semana por ruta activa (Paso Alto los lunes, Puerto Fluvial los martes y Vega del Sol los jueves, con 30 % de retraso de +1 día por barro) aparecen el caravanero y su mula de carga a las 9:00 por el camino del este (`RAID_GATE_POS`), acampan en la plaza (`CARAVAN_PLAZA_POS`) de 10:00 a 16:00 y regresan a las 16:00. El intercambio entre talleres ocurre al llegar a la plaza (no a medianoche), tus remesas se cargan con `[E]` en la mula (con +4 de oro si llevas tu carreta cerca) y matar al caravanero suspende la ruta 7 días.
