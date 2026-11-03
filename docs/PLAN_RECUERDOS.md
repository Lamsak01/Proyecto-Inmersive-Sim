# Plan: recuerdos que se degradan (bloques R)

Estado: **aprobado por el usuario para hacerlo entero** (2026-11-02: «haz la 1, crea el plan y síguelo completamente»).
Contexto: `docs/VISION_Y_FUTURO.md`, paso 1 del orden (última pieza: rasgos → relaciones de un solo sentido → recuerdos).

## Qué existe hoy

- Los chismes son sucesos de `VillageManager.social_event_log` con `known_by` (quién lo sabe) y `heard_from` (de quién lo oyó).
- Todos lo recuerdan perfecto durante `GOSSIP_MAX_AGE_DAYS` = 10 días; luego desaparece de golpe para todos.
- Todos cuentan exactamente lo mismo (el `summary` del suceso).

## Qué se hace

- **R1 – Fuerza del recuerdo.** Cada vecino que sabe un chisme tiene una fuerza (0–100) en `ev["mem"]`.
  Protagonistas 100, testigos 90, quien lo oye 70. Baja cada día (unos 8 puntos; los protagonistas apenas 1,5).
  Los rasgos de memoria (Memorioso, Estudioso, Nostálgico, Olvidadizo) la hacen bajar más lento o más rápido.
  Contarlo lo refresca (+10). Si llega a 0, lo olvida (`ev["forgot"]`): ya no lo cuenta, no lo menciona como novedad
  y, si era testigo de un motivo de asesinato, ya no se lo dice al investigador. Si alguien se lo vuelve a contar, lo recupera.
  El tope de edad sube a 20 días: ahora es la memoria la que decide cuándo muere un chisme.
- **R2 – Deformación al contarlo.** Al pasar el chisme, puede cambiar (`ev["ver"][quien]`, la versión de cada uno):
  exagerar («…y dicen que casi se matan») o cambiar a una persona por otra («Marco y Sora se pelearon», cuando fue Luis).
  Más probable si quien lo cuenta es mentiroso, si lo recuerda mal o si no es protagonista. La versión se hereda: un
  error se va contagiando de boca en boca. Lo que dicen los vecinos (texto flotante y «¿alguna novedad?») es su versión.
- **R3 – El jugador y la crónica.** Si un vecino te cuenta una versión deformada, la crónica apunta «❓ X te contó: …»
  (en modo pruebas con «[deformado]» al lado). Así puedes ver versiones que no cuadran.
- **R4 – Medición.** La sonda cuenta chismes olvidados y deformados. Un test por comportamiento.

## Qué no se hace ahora

- Las versiones deformadas todavía **no cambian relaciones** (creer que fue Marco no hace que le caiga peor).
  Eso pertenece a Secretos (siguiente plan), donde un rumor falso sí podrá arruinar a un inocente.
- Los rasgos que se rumorean (`rumored_traits`) no se olvidan todavía. Queda en el banco de ideas.

## Riesgos

- Los chismes duran algo más (20 días de tope frente a 10), pero cada vecino los olvida antes: medir que no se disparen.
- Partidas viejas: los chismes sin `mem` empiezan con fuerza 70 para quien los sepa.
