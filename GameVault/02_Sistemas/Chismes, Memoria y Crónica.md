---
tipo: "sistema"
area: "social"
estado: "implementado"
codigo: "C1-C5, R1-R5"
tags:
  - "social"
  - "rasgos"
  - "sistema"
fuente: "Biblia §6.4"
---
# Chismes, Memoria y Crónica

> Sección original: *Chismes, Memoria que se Deforma y Crónica (`C1–C5`, `R1–R5`, `B6`)*

```mermaid
sequenceDiagram
    participant Suceso as 👀 Suceso en el Mundo
    participant Testigo as Vecino Testigo (Memoria)
    participant Chismoso as Vecino Chismoso (Malicia)
    participant Oyente as Tercer Vecino / Jugador
    Suceso->>Testigo: Lo ve con línea de visión (known_by)
    Note over Testigo: Cada día pierde fuerza según su rasgo Memorioso/Olvidadizo
    Testigo->>Chismoso: Se lo cuenta al charlar en la plaza o taberna
    Note over Chismoso: Si es Chismoso o Mentiroso, exagera o cambia el culpable
    Chismoso->>Oyente: Rumor de segunda mano ("Según X...")
```
- **Degradación de la Memoria (`R1–R3`):** Cada recuerdo tiene una intensidad que baja cada día según la tendencia `memory` del vecino (*Memorioso* lo retiene mucho más; *Olvidadizo* lo pierde rápido).
- **Teléfono Escacharrado (`R4–R5`):** Cuando un suceso pasa de boca en boca (`heard_from`), un vecino malicioso o chismoso puede **exagerar la gravedad** o incluso **atribuir el hecho al rival que peor le cae**.
- **Crónica del Pueblo (`[O]`):** Registra hasta 500 sucesos históricos filtrables por pestañas (*Todo, Amor, Amistad, Chismes, Peleas, Muertes, Fe, Llegadas, Tú*).

## Notas de diseño
-
