---
tipo: "sistema"
area: "crimen"
estado: "implementado"
codigo: "VillageJustice"
tags:
  - "medicina"
  - "crimen"
  - "sistema"
fuente: "Biblia §5.2"
---
# Justicia y Comisaría

> Sección original: *Justicia, Comisaría y el Inquisidor Real Alistair (`VillageJustice`)*

- **Niveles de Alerta del Pueblo:** `🟢 Tranquila` → `🟡 Desconfiada` (los vecinos cierran puertas con llave antes) → `🔴 Alerta Máxima` (patrullas reforzadas, toque de queda y llegada del Inquisidor).
- **Inquisidor Real Alistair:** Cuando ocurre un asesinato o una cadena de crímenes graves, llega al valle desde las Tierras Reales. **No tiene omnisciencia:** interroga uno por uno a los vecinos que estuvieron cerca, cruza sus recuerdos (`sighting_log`), examina las pruebas forenses en la Morgue y convoca un **Juicio Público en la Plaza** donde acusa al sospechoso con más pruebas.
- **Calabozo físico para los vecinos (`B2`):** Cuando un guardia pilla a un vecino en un sabotaje, robo o profanación nocturna (`VillageNightJobs`), separa una pelea grave, ejecuta un veredicto o detiene al jefe de «La Familia» tras una denuncia con pruebas, el vecino camina hasta la celda de la comisaría (`(886, 172)`) y queda encerrado tras la reja entre 24 y 48 horas (sin acudir a su taller ni a reuniones). Mientras cumple condena, el jugador puede hablar con él entre los barrotes, pagar su fianza al Comisario o a un guardia (el oro va a las [[Arcas Municipales]]) o forzar la cerradura con ganzúas/llave para ayudarlo a escapar.

## Notas de diseño
-
