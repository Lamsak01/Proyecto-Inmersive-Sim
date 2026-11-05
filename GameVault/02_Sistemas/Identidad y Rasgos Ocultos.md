---
tipo: "sistema"
area: "social"
estado: "implementado"
codigo: "T1-T5"
tags:
  - "social"
  - "rasgos"
  - "sistema"
fuente: "Biblia §6.1"
---
# Identidad y Rasgos Ocultos

> Sección original: *Identidad Única y Descubrimiento de Rasgos (`PersonProfile`, `T1–T5`)*

- Cada habitante tiene un `person_id` inmutable, nombre y apellido (`NPCNames`: 200 femeninos, 200 masculinos, 200 apellidos), edad, género, orientación, clase social y **6 rasgos de personalidad** sin contradicciones de eje (con un `25%` de probabilidad de tener 1 rasgo raro).
- **Rasgos Ocultos (`❓`):** Al conocer a un vecino no ves su ficha completa. Descubres sus rasgos:
  1. Tratando con él varios días o viéndole actuar (pelear, rezar, emborracharse, donar).
  2. Escuchando conversaciones ajenas a escondidas.
  3. Preguntando a otros vecinos (*«Se dice que es Violento, según Marta»*), teniendo en cuenta que un vecino *Mentiroso* o con alta *Malicia* puede inventarse un rasgo falso para difamar a su enemigo.

## Notas de diseño
-
