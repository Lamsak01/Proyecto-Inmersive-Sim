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
- **Ganado Vivo en el Rancho y Corral Propio (`Bloque FIS4`, `LivestockAnimal.gd`):** Cada ejemplar de `ranch_herd` camina en vivo dentro del corral del Rancho del Sur (`x = 310..397`, `y = 400..540`, grupo `"ranch_livestock"`, sin los 4 dibujos estáticos antiguos), y cada ejemplar de `player_animals` camina dentro del corral del gallinero del jugador (`ChickenCoop`, grupo `"player_livestock"`), cambiando de tamaño según su etapa (`"chick"`, `"juvenile"`, `"adult"`). En 3D usa `animals/animated/Alpaca.glb` (CC0 Quaternius) para `"sheep"` y una gallina 3D procedural (`"procedural:chicken"` en `AnimalModel3D.gd`) para `"rooster"`.
- **Alimentación y Recogida en Persona con `[E]` (`Bloque FIS4`):** Te acercas a un animal tuyo y pulsas `[E]` (`Dar de comer a la oveja` / `Dar de comer a la gallina`) para gastar `1` de `"wheat"`, `"bread"` o `"carrot"` de tu mochila y hacerlo avanzar (`fed_day = today()`, `age_days += 2`, `power + 1`). Cuando es `"adult"`, pulsas `[E]` para `Esquilar la oveja` (`+1 "wool"`) o `Recoger huevos` (`+1 "egg"`), como máximo una vez cada **2 días** por animal (`last_product_day`). Ya no entra `"cooked_meat"` sola en el paso diario ni se alimentan por diálogo con el ganadero.
- **Alimentación Real (`cd18e1c`):** En el corral del jugador, cada animal registra qué día comió (`fed_day`). Sólo crece si comió en los últimos **2 días**, y muere de hambre (desapareciendo del mapa) si pasa **5 días** sin comer.
- **Renovación Autónoma del Rancho (`Bloque PR`):** El **Rancho del Sur** vende o sacrifica un animal adulto cuando el rebaño llega al tope de 4 cabezas (ingresando **14 de oro** en la caja del rancho y repartiendo carne), dejando hueco continuo para que nazcan nuevas crías.
- **Apuestas de Feria (`PH.2`):** Carreras de caballos y peleas de gallos/perros con probabilidades según la vitalidad del animal y riesgo de intervención del comisario si hay ley seca o apuestas ilegales.

## Notas de diseño
-
