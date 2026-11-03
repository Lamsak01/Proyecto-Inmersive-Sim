# Plan: deseos propios (bloques D)

Estado: **hecho** (2026-11-03, ver HANDOFF). Decisiones del usuario: 1) asesinatos entre vecinos **sí**, muy raros;
2) contra el jugador **todo** lo de D4; 3) los deseos **se descubren**: hablando con afinidad suficiente, contados por otros
vecinos o porque el propio vecino los dice abiertamente si no son secreto para él; 4) **todo de una vez**, tests al final. Paso 4 de `docs/VISION_Y_FUTURO.md`.
Se apoya en: rasgos y tendencias (T2), relaciones de un solo sentido (U), crónica (C), recuerdos (R) y secretos (S).

## Idea

Hasta ahora los vecinos **reaccionan** a lo que pasa. Con esto, algunos **quieren algo** y dan pasos para lograrlo, a lo
largo de días. Cada vecino tiene como mucho **un deseo activo**, que sale de sus rasgos y de lo que le ha pasado, y se
revisa cada semana. Raro y orgánico: muchos vecinos no tendrán ninguno, y eso está bien.

## Bloques

- **D1 – Base de deseos.** Estructura común (`VillageDesires.gd`, guardada con la partida): quién desea qué, contra o
  hacia quién, desde cuándo, en qué paso va. Se descubre como los rasgos: hablando con el vecino («¿Qué te ronda la
  cabeza?»; solo lo cuenta si te aprecia) o por chismes. En modo pruebas, todo en la crónica con 🔒.
- **D2 – Venganza.** Nace de un daño fuerte y reciente: le engañaron, le chantajearon, le calumniaron, le dieron una
  paliza o le dejaron. Escala poco a poco, solo si el odio sigue: 1) hablar mal de él, 2) contar sus secretos,
  3) estropearle el negocio (ya existe el sabotaje de puestos), 4) buscar pelea. Se acaba si se reconcilian, si siente
  que ya se ha vengado o si pasa mucho tiempo (el rencor de sus rasgos decide cuánto).
- **D3 – Ambición.** Vecinos ambiciosos o avariciosos quieren más oro o un oficio mejor: ahorran, compiten con quien tiene
  su mismo oficio (hablan mal de él, le quitan clientes) y, si queda libre un puesto o un negocio (alguien se va o
  muere), intentan quedárselo.
- **D4 – Contra el jugador.** Quien te odia de verdad durante tiempo: va diciendo cosas de ti, se niega a venderte,
  te denuncia al comisario (con algo cierto que sepa, o inventado si es mentiroso) o cuenta tus secretos.
- **D5 – Planes de asesinato (muy raros).** Solo tras un odio extremo y largo, con rasgos oscuros (malicia, agresividad,
  poca honestidad) y un detonante (engaño, chantaje, ruina). Prepara el plan unos días: se pueden notar señales
  (lo dice en voz baja, compra veneno, pregunta por las rutinas de la víctima). Si no se descubre, la víctima aparece
  muerta y se abre una investigación normal, donde el asesino tiene móvil y no tiene coartada. Si te enteras a tiempo,
  puedes avisar a la víctima o al comisario. Una partida sin asesinatos es lo normal.
- **D6 – Medición y tests.** Un test por comportamiento y la sonda cuenta deseos, pasos y desenlaces.

## Decisiones que necesito

1. **Asesinatos entre vecinos (D5):** ¿sí (muy raros), no, o más adelante?
2. **Contra el jugador (D4):** ¿todo lo de la lista, o quitas algo (p. ej. las denuncias falsas)?
3. **Ver los deseos:** ¿se descubren hablando, como los rasgos (recomendado), o se ven siempre en el glosario?
4. **Cómo hacerlo:** ¿todo de una vez, como Secretos, con los tests solo al final?

## Riesgos

- Es el sistema más grande hasta ahora. Que las venganzas se encadenen y el pueblo acabe en guerra: cada deseo tiene un
  final, un vecino solo tiene uno a la vez y hay descanso entre deseos.
- D5 toca las investigaciones, que hoy están pensadas para los crímenes del jugador: hará falta que el comisario pueda
  acusar a un vecino de verdad. Es la parte con más riesgo de romper algo.
