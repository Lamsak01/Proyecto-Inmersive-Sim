# Plan de la primera beta: «El misterio del valle» (borrador para retocar)

> Claude Code, 2026-11-06. Decidido por el usuario: hilo de misterio, con final y resumen, 1–2 horas, Windows.
> El usuario quiere retocar la forma de partida más adelante: **esto es una base, no está cerrado.**

## 1. Cómo es una partida (propuesta)

1. **Llegada (minutos 0–10):** llegas al campamento del oeste. Una ayuda breve presenta 8 teclas y te propone hablar
   con dos o tres vecinos. Esa noche (o al día siguiente) **aparece un vecino muerto**.
2. **El caso (minutos 10–90):** el culpable se elige **al azar cada partida** entre los vecinos con un motivo real
   (deseos de venganza, celos, deudas, secretos). Investigas: examinar el cuerpo y la escena, leer la autopsia en la
   morgue, preguntar a testigos, escuchar chismes (que se deforman al pasar de boca en boca), registrar casas o cofres.
   El culpable **miente** y puede intentar callar a quien sabe demasiado. El inquisidor real también investiga, y
   **puede sospechar de ti**.
3. **La acusación:** acusas ante el inquisidor o en el juicio público de la plaza. Si aciertas, el culpable cae. Si te
   equivocas, condenan a un inocente y el culpable sigue suelto (y quizá vuelve a matar).
4. **Final:** pantalla de resumen: qué descubriste y cómo, a quién acusaste, si era el culpable, a quién ayudaste o
   perjudicaste, y lo más llamativo de la crónica del pueblo.

## 2. Lo que ya existe y sirve

| Pieza | Dónde |
|---|---|
| Asesinatos de vecinos con móvil (planes de venganza, celos, ambición) | `VillageDesires`, `VillageForensics.on_npc_murder_committed` |
| Escena del crimen: cuerpo, sangre, huellas, limpiar con lejía | `VillageForensics` |
| Testigos que ven y denuncian, en 3 fases | `VillageNPC` (aviso de cadáver) |
| Morgue y autopsia | `VillageManager` (morgue), `VillageJustice` |
| Investigación del comisario y del inquisidor real (entrevistas, cruce de datos, sospechosos) | `VillageJustice` |
| Interrogatorio del jugador y juicio público en la plaza | `VillageJustice.resolve_player_interrogation_outcome`, `resolve_public_trial_intervention` |
| Chismes que se deforman y secretos con «quién lo sabe» | `GossipMemory`, `VillageSecrets` |
| Registro de misiones (tecla J) y crónica del pueblo (tecla O) | `QuestManager`, `VillageChronicle` |

## 3. Lo que falta (de más a menos importante)

1. **Arranque de partida «beta»:** que la partida nueva prepare el caso: elegir víctima y culpable con motivo creíble
   y provocar el asesinato a una hora razonable, siempre una vez y de forma que el jugador pueda llegar a tiempo.
2. **Hilo de objetivos visibles:** usar el registro de misiones como cuaderno del detective: pistas encontradas,
   sospechosos, siguiente paso sugerido. Que un amigo sepa qué hacer sin que se lo expliques.
3. **Pistas que se puedan encontrar en el mundo** (no solo en diálogos): objeto perdido del culpable, carta, arma,
   huellas que llevan a una casa… con [E] y letrero.
4. **Acusación clara:** una forma explícita de acusar (al inquisidor o en el juicio) con confirmación, y el resultado.
5. **Pantalla de final con resumen** (lo dice la decisión del usuario) y opción de volver a empezar con otro culpable.
6. **Ayuda de controles** con las 8 teclas básicas al empezar.
7. **Pulido para jugar fuera de casa:** quitar el arranque provisional de 40 vecinos (o decidir cuántos), comprobar
   rendimiento en un ordenador modesto, guardar/cargar a mitad del caso.
8. **Exportar para Windows** y un «Léeme» con controles y qué se espera del jugador.

## 4. Preguntas para retocar más adelante (no bloquean)

- ¿El jugador llega siendo forastero (sospechoso natural) o con un papel (ayudante del comisario, periodista…)?
- ¿Cuánto debe ayudar el juego a encontrar pistas (más guiado o más libre)?
- ¿Puede haber un segundo asesinato si tardas mucho?
- ¿Se puede ganar también mintiendo y culpando a otro a propósito (final «turbio»)?
- ¿Cuántos vecinos en la beta? (más vecinos = más sospechosos, pero más lento en ordenadores modestos)
