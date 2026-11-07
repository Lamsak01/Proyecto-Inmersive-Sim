---
tipo: "sistema"
area: "supervivencia"
estado: "implementado"
codigo: "WorldClock"
tags:
  - "sistema"
  - "supervivencia"
  - "combate"
  - "ecosistema"
fuente: "Biblia §3.1"
---
# Supervivencia y Clima

> Sección original: *Reloj del Mundo, Clima y Supervivencia (`WorldClock` + `SurvivalComponent`)*

- **Ciclo horario:** Día de 24 horas con días de la semana de lunes a domingo. Nunca salta hacia delante de forma artificial (salvo al dormir en cama o al pasar una expedición/turno completo justificado), para no teletransportar ni desincronizar a los vecinos.
- **Clima dinámico y visibilidad nocturna (`B4`):** Alterna entre `☀️ Despejado`, `🌧️ Lluvia` (riega automáticamente los cultivos y apaga fuegos exteriores en talleres saboteados, reduciendo su avería) y `🌫️ Niebla` (reduce el alcance visual de los conos de visión). De madrugada (`0:00–7:00`) y con niebla, la bruma nocturna recorta aún más el alcance de la vista de vecinos y guardias (`get_ambient_vision_multiplier_at`), salvo cerca de **farolas eléctricas/de gas encendidas** o de alguien que porte un **farol encendido** (`is_carrying_lantern`, que el jugador apaga automáticamente al ir en sigilo). Un taller saboteado (`sabotaged_days > 0`) echa humo, chispas y llamas en 2D y 3D hasta que se repara. De noche (`22:00–4:00`), los vecinos con rasgos **Noctámbulo** o **Insomne** pasean por las calles y los **Sonámbulos** caminan dormidos a oscuras.
- **Necesidades del jugador y de los vecinos:**
  - **Salud y Sangrado:** El daño cortante provoca sangrado continuo que deja rastro en el suelo hasta vendarse.
  - **Aturdimiento (*Stun*) y Aguante (*Stamina*):** Correr, esquivar y golpear consume aguante; si el aturdimiento llena la barra, caes derribado (`KO`) sin morir.
  - **Hambre y Sueño:** Afectan la velocidad de movimiento y regeneración. Sentarse en el tronco del campamento o en bancos reduce un `85%` el desgaste metabólico.
  - **Higiene y Enfermedades (`E1–E2`):** La higiene baja cada día (`0..100`). Si cae por debajo de `30`, el vecino huele mal (`−2` de aprecio al charlar) y corre más riesgo de enfermar. Se recupera lavándose en los **pozos** o en el **Lavadero del Lago**. Existen dos enfermedades contagiosas por cercanía: **Resfriado** (leve, 3 días) y **Fiebre gris** (grave, 5 días; obliga a guardar cama o ir al hospital del **Dr. Valen**, y en ancianos o heridos puede ser mortal).

## Notas de diseño
-
