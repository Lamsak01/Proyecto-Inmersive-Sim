---
tipo: "sistema"
area: "economia"
estado: "implementado"
codigo: "PH.1-PH.2"
tags:
  - "economia"
  - "vivienda"
  - "sistema"
fuente: "Biblia §4.3"
---
# Cría de Animales y Apuestas

> Sección original: *Cría de Animales, Rancho y Apuestas (`PH.1–PH.2`)*

- **Etapas de Crecimiento:** `cría (chick) → joven (juvenile) → adulto (adult)`.
- **Alimentación Real (`cd18e1c`):** En el corral del jugador, cada animal registra qué día comió (`fed_day`). Sólo crece y produce carne/huevos si comió en los últimos **2 días**, y muere de hambre si pasa **5 días** sin comer.
- **Renovación Autónoma del Rancho (`Bloque PR`):** El **Rancho del Sur** vende o sacrifica un animal adulto cuando el rebaño llega al tope de 4 cabezas (ingresando **14 de oro** en la caja del rancho y repartiendo carne), dejando hueco continuo para que nazcan nuevas crías.
- **Apuestas de Feria (`PH.2`):** Carreras de caballos y peleas de gallos/perros con probabilidades según la vitalidad del animal y riesgo de intervención del comisario si hay ley seca o apuestas ilegales.

## Notas de diseño
-
