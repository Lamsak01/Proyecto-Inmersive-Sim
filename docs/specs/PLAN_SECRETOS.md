# Plan: secretos — infidelidad y chantaje (bloques S)

Estado: **hecho** (ver HANDOFF, sección Secretos). **Aprobado por el usuario para hacerlo entero** (2026-11-02: «crea el plan para implementar el paso 2 y ejecútalo
por completo»; el paso 2 de la propuesta era Secretos, el 3 del orden de `docs/VISION_Y_FUTURO.md`).
Se apoya en: relaciones de un solo sentido (U), crónica (C) y recuerdos que se degradan (R).

## Principios

- **Raro y orgánico**, como las peleas: una partida sin infidelidades es válida. Nada de misiones (decisión del usuario).
- Solo adultos (18+; hoy todos los vecinos tienen 19 o más).
- Fuera de cámara: «se ven a escondidas», nunca nada explícito.

## Bloques

- **S1 – Aventuras.** Cada día, alguien con pareja puede empezar una aventura con otra persona si hay chispa en los dos
  sentidos (él ≥ 35, la otra persona ≥ 20), se han visto hace poco y no son familia. La probabilidad depende de la
  fidelidad: **Fiel nunca**, alguien normal muy poco, **Infiel** bastante más. Se guarda en `VillageManager.secrets`
  (con la partida), con quién lo sabe. Cuando quedan juntos, es un encuentro a escondidas.
  La aventura se acaba si se pierde la chispa o si la pareja se entera.
- **S2 – Descubrirlo.** En cada encuentro, los vecinos que estén cerca (y tú) pueden pillarlos. Quien lo descubre lo
  convierte en chisme («X engaña a Y con Z») que corre de boca en boca con la memoria y las deformaciones de R:
  **un rumor deformado puede señalar a un inocente**. Los amantes nunca lo cuentan.
- **S3 – Consecuencias.** Quien oye el chisme piensa peor de quien cree culpable (según su versión, aunque sea falsa).
  Si llega a la pareja engañada: se enfada mucho con los dos (con los que cree culpables), la relación se tensa y lo más
  probable es que rompa. Todo queda en la crónica.
- **S4 – Chantaje entre vecinos.** Alguien malicioso que sabe el secreto puede chantajear al infiel: paga (se pasa oro)
  o se niega, y entonces el chantajista se lo cuenta a la pareja. Una vez por chantajista y secreto. El chantajeado le
  coge mucha manía.
- **S5 – El jugador.** Si conoces el secreto (lo viste, te lo contaron), al hablar con el infiel aparece
  «🤫 Sé lo tuyo con Z»: pedirle dinero (chantaje: paga o te odia) o prometer callar (te lo agradece). Al hablar con la
  pareja engañada: «Tengo algo que contarte sobre X» (se lo cuentas tú; te lo agradece, aunque duela).
  En modo pruebas, la crónica enseña todas las aventuras con 🔒.
- **S6 – Medición y tests.** Un test por comportamiento (test #55). La sonda cuenta aventuras, descubrimientos,
  rupturas por infidelidad y chantajes.

## Qué no se hace ahora

- Hijos fuera de la pareja, venganzas elaboradas, celos que acaben en violencia: más adelante (banco de ideas).
- Otros secretos (deudas, crímenes del pasado, vicios): la estructura `secrets` queda preparada para ellos.

## Riesgos

- Que salgan demasiadas aventuras o ninguna: ajustar con la sonda (diales al principio de `VillageSecrets.gd`).
- Rupturas en cadena: una aventura por persona a la vez y un descanso tras cada ruptura.
