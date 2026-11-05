---
tipo: "indice"
tags:
  - "misiones"
  - "historia"
fuente: "Biblia §11.2"
---
# Misiones secundarias

```dataview
TABLE id, recompensa, estado
FROM "04_Censo_y_Misiones/Misiones"
SORT numero ASC
```

## Tabla original
Todas nacen con un icono `❗` sobre un vecino real cuando se cumplen sus condiciones en la simulación (máximo 3 activas a la vez, caducan a los 4 días si las ignoras y tienen múltiples desenlaces morales):

| # | ID | Título | Quién y Cuándo la Pide | Cómo se Resuelve y Opciones Morales | Recompensa Base |
|---|---|---|---|---|---|
| 1 | `peace` | **Haz las paces por mí** | Vecino pacífico con enemistad larga (`>= 5` días) | Mediar con su rival hasta suavizar su opinión (`>= -15` o `+12`). | `30 oro`, `+15 afinidad` |
| 2 | `slander` | **Ensúciale el nombre** | Vecino rencoroso/malicioso que odia a otro (`<= -40`) | Difamar al rival ante 2 vecinos distintos. | `25 oro`, `+12 afinidad` |
| 3 | `opinion` | **Averigua qué piensa de mí** | Soltero con chispa (`>= 14`) hacia otro soltero | Indagar qué opina el otro y volver: decirle la **verdad** o **mentirle por piedad**. | `20 oro`, `+8 afinidad` |
| 4 | `justice` | **Encuentra a quien lo mató** | Amigo o pariente (`>= 40`) de una víctima de asesinato | Lograr que el juicio condene a un culpable (falla si se archiva o te culpan a ti). | `40 oro`, `+20 afinidad` |
| 5 | `rumor` | **¿Quién va contando eso de mí?** | Víctima de una calumnia que le llega de segunda mano | Rastrear la cadena `heard_from` y elegir: delatar al origen, señalar a otro o confesar. | `25 oro`, `+10 afinidad` |
| 6 | `affair_doubt` | **¿Me engaña X?** | Vecino cuya pareja tiene una aventura oculta | Investigar testigos (`🕵️`) y elegir: contar la verdad, taparlo o chantajear al infiel. | `25 oro`, `+12 afinidad` |
| 7 | `loan_trouble` | **Que no me quiten la casa** | Hipotecado con `>= 2` cuotas impagadas | Pagarle tú 3 cuotas (`💰`) o convencer al prestamista de perdonar recargos (`🙏`). | `0 oro`, `+22 afinidad` |
| 8 | `boar_hunt` | **El jabalí del claro** | El carnicero, cuando abundan los jabalíes en el bosque | Abatir un jabalí salvaje sin extinguir la piara. | `30 oro`, `+12 afinidad` |
| 9 | `vote_buying` | **Votos para X** | Candidato corruptible, `2–8` días antes de elecciones | Conseguir 3 promesas de voto o **denunciar la compra de votos** en la plaza. | `35 oro`, `+10 afinidad` |
| 10 | `embezzle_proof` | **Las cuentas de X** | Testigo de un desfalco del alcalde | Reunir 2 testimonios (`🧾`) y elegir: destapar al alcalde o chantajearle por `50 oro`. | `30 oro`, `+15 afinidad` |
| 11 | `poor_medicine` | **Medicina para X** | Vecino pobre enfermo sin dinero para el médico | Pagar el tratamiento al **Dr. Valen** (`8 oro`) o lograr que lo pague la parroquia. | `0 oro`, `+25 afinidad` |
| 12 | `faith_doubt` | **Fe que tambalea** | El **Hermano Anselmo**, sobre un feligrés tibio | Invitarle (`⛪`) y lograr que asista de verdad al Oficio del domingo. | `15 oro`, `+12 afinidad` |
| 13 | `apprentice` | **El aprendiz** | Joven parado (`<= 30` años) habiendo un taller sin ayudante | Recomendarle al maestro artesano (`🧑‍🔧`) para que entre de aprendiz y futuro heredero. | `10 oro`, `+20 afinidad` |
| 14 | `sabotage_job` | **Sabotaje por encargo** | Dueño de taller que odia (`<= -25`) a un competidor | Sabotear el taller rival de noche o **delatar el encargo al comisario** (`🚨`). | `40 oro`, `+10 afinidad` |
| 15 | `scared_witness` | **El testigo con miedo** | Quien descubrió el cadáver de un caso abierto | Conseguirle escolta policial (`🛡️`), añadiendo una pista clave contra el asesino real. | `15 oro`, `+18 afinidad` |
| 16 | `empty_pots` | **Ollas vacías** | El sacerdote, cuando hay `>= 3` pobres y arcas bajas (`< 48`) | Recaudar `20 oro` en donativos de los ricos (`🥣`) o de tu bolsillo para las gachas. | `0 oro`, `+15 afinidad` |
| 17 | `love_letter` | **¿Me corresponde?** | Soltero *Tímido* o *Romántico* con chispa `>= 14` | Entregar su carta (`💌`), o bien **leerla en secreto / romperla** para sabotear el romance. | `15 oro`, `+12 afinidad` |
| 18 | `inheritance` | **La herencia de X** | Pariente de un artesano fallecido hace `<= 5` días | Lograr que el nuevo dueño le compense con `15 oro`, lo contrate o que renuncie al pleito. | `20 oro`, `+15 afinidad` |
| 19 | `last_drink` | **La última copa** | Pareja de un vecino enganchado al alcohol o al juego | Convencerle (`🗣️`) o pedir al tabernero que le vete 6 días (`🚫`) hasta bajar su vicio de `40`. | `20 oro`, `+15 afinidad` |
| 20 | `market_stall` | **El puesto del miércoles** | Artesano sin liquidez `1–3` días antes del mercado | Adelantarle `15 oro` o lograr que un proveedor le fíe para que monte su puesto el miércoles. | `20 oro` (+adelanto), `+12` |
| 21 | `night_reading` | **Lo que se lee de noche** | Lector de la biblioteca cuando [[La Secta]] está activa en secreto | Descubrir la existencia de la secta y elegir: revelárselo o guardar silencio. | `25 oro`, `+12 afinidad` |
| 22 | `announced_fight` | **Pelea anunciada** | Amigo de alguien cuya tensión con un rival roza la pelea | Calmar a ambos (`🕊️`) hasta bajar la tensión a `<= 14` antes de que lleguen a las manos. | `20 oro`, `+12 afinidad` |
| 23 | `homeless` | **Sin techo** | Vecino desahuciado hace `<= 4` días que duerme al raso | Conseguir que un amigo le acoja, que el casero le alquile o darle `18 oro` para la posada. | `0 oro`, `+25 afinidad` |
| 24 | `strange_newcomer` | **El forastero raro** | Vecino desconfiado ante un inmigrante recién llegado (`<= 6` días) | Conocer 2 rasgos del recién llegado (`🔎`) y elegir: avalarlo o hacerle el vacío. | `15 oro`, `+10 afinidad` |
| 25 | `nameless_grave` | **La tumba sin nombre** | Familia de una víctima cuyo caso se archivó sin culpable | Reunir 2 testimonios (`🕯️`) y señalar al asesino real o a un chivo expiatorio (`+15 oro`). | `35 oro`, `+20 afinidad` |
