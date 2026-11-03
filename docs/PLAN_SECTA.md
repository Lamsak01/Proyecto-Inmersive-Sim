# Plan: la secta secreta (bloques O)

Estado: **hecho** (2026-11-03, ver HANDOFF). El usuario delegó lo creativo y las decisiones de abajo las tomé yo con
lo recomendado: 1) **sí puede matar** en un rito, muy raramente y con señales; 2) **puedes unirte**; 3) **sin droga** por
ahora; 4) **nace en los primeros días** (día 3–6) si hay alguien con perfil; 5) todo de una vez. Nombre, símbolo, lore y
rangos son provisionales (ver `docs/APORTES_CREATIVOS.md`). Los bloques se llaman O (de Ocaso) para no chocar con los
de secretos (S). Paso 8 de `docs/VISION_Y_FUTURO.md`. Usa todo lo anterior: secretos (quién sabe
qué), deseos (poder, venganza), grupos y fe, pobreza y vicios, e instituciones corruptas. Posible gancho de la
historia principal, pero sin misiones por ahora.

## Qué existe hoy

- La Fe del Alba con sacerdote, Oficio los domingos, creyentes, tibios y escépticos, y bandos (familias, pandillas,
  seguidores de un líder).
- Rasgos sin efecto o con poco: Místico («le atrae lo oculto»), Fanático, Manipulador, Cruel.
- Secretos que se guardan y se cuentan (infidelidad, chantaje), planes de asesinato muy raros con señales previas.
- Pobres, mendigos, adictos y gente resentida: el caldo de cultivo de una secta.
- El inquisidor real solo aparece si matas a un mercader.

## Bloques

- **O1 – La secta y su fundador.** Una secta con nombre propio (propuesta: **«los Hijos del Ocaso»**, lo contrario del
  Alba). La funda un vecino con perfil: Místico, Fanático, Manipulador o ambicioso con pocos escrúpulos. Nunca
  autoridades ni el sacerdote. Empieza con el fundador y uno o dos fieles. Ser miembro es un **secreto**: cada miembro
  sabe quiénes son los demás; los de fuera, no.
- **O2 – Reclutamiento.** Cada semana los miembros intentan captar a alguien vulnerable: pobres, mendigos, adictos,
  solitarios, gente con un rencor fuerte, enfermos sin médico y Místicos. Los Devotos del Alba, los Íntegros y las
  autoridades se resisten. Quien rechaza la oferta puede ir contándolo (chisme). Tope de tamaño (unos 5 de 18) para que
  no se trague el pueblo.
- **O3 – Reuniones de noche.** Una vez por semana se reúnen a escondidas en un lugar apartado (propuesta: un claro del
  bosque o el cementerio). Dejan la cama a medianoche: si alguien les ve salir o tú les sigues, es una pista. Las
  reuniones refuerzan sus lazos y les alejan de los creyentes del Alba.
- **O4 – Lo que hace la secta.**
  - **Dinero:** los miembros pagan un diezmo; el fundador lo guarda.
  - **Poder:** votan juntos en las elecciones y empujan a uno de los suyos a alcalde. Intentan comprar o captar al
    comisario.
  - **Protección:** no se denuncian entre ellos y encubren los robos de sus miembros.
  - **Contra el Alba:** calumnias contra el sacerdote, profanaciones en la capilla (un símbolo pintado, velas rotas) y
    menos gente en el Oficio.
  - **Lo oscuro (ver decisión 1):** cuando la secta es grande y vieja, muy raramente prepara un **rito de sangre**.
- **O5 – Descubrirla.** Pistas que se van sumando: salidas de noche, el símbolo, el rumor de quien rechazó entrar,
  diezmos que no cuadran. El sacerdote sospecha y predica contra ella. Si se destapa, los miembros pierden aprecio en
  el pueblo, el comisario detiene al fundador y algunos lo dejan. La secta puede volver a nacer más tarde con otro
  fundador.
- **O6 – Tú.** Notar las pistas y seguirles de noche, preguntar por ellos, denunciarles ante el sacerdote o el
  comisario, chantajear a un miembro, o **unirte** (ver decisión 2): reuniones, diezmo, rangos y encargos sencillos.
  Tu fama con la Fe del Alba baja si se sabe.
- **O7 – Medición y tests.** Un test por comportamiento (al final). La sonda cuenta miembros, reclutados y rechazos,
  reuniones, pistas, si se destapa y lo que hizo.

## Decisiones (tomadas, ver arriba)

1. **Lo oscuro:** ¿la secta puede llegar a matar en un rito (muy raro, con señales antes y pistas para el comisario,
   como los planes de asesinato), o solo dinero, poder y profanaciones? Recomiendo que pueda, muy raramente.
2. **Tú:** ¿puedes unirte a la secta (infiltrarte o creer de verdad), o solo descubrirla y denunciarla? Recomiendo que
   puedas unirte.
3. **Drogas:** en el paso 6 las dejamos para la secta. ¿La secta reparte una droga («polvo de ocaso») para atraer y
   atar a la gente, o lo dejamos fuera? Recomiendo dejarla para más adelante: este paso ya es grande.
4. **¿Siempre hay secta?** ¿En todas las partidas desde el principio, o nace a mitad de partida y en algunas no llega a
   existir? Recomiendo que nazca en los primeros días casi siempre, para que se pueda jugar con ella.
5. **Cómo hacerlo:** ¿todo de una vez con los tests al final, como en los pasos anteriores?

## Riesgos

- Que la secta lo llene todo: tope de miembros y resistencia de creyentes, Íntegros y autoridades.
- Que nunca se note: cada pieza deja rastro (textos flotantes, crónica, chismes, glosario cuando la conoces).
- Que se descubra al instante: las pistas se suman poco a poco y sus miembros se encubren.
- Que choque con lo ya hecho (Oficio, bandos, elecciones): la secta es un bando oculto más y reutiliza esas piezas.

## Cómo quedó (resumen técnico)

- `scripts/systems/VillageSect.gd`; estado en `vm.sect_state` (se guarda). Test #60.
- Fundador por perfil (Místico, Fanático, Manipulador, Cruel, ambición, malicia; nunca autoridades, sacerdote ni
  forasteros). Tope 5 miembros. Si se destapa o muere el fundador sin heredero, renace a los 30 días con otro.
- La secta es un **bando oculto** en `vm.faith_bands` (kind "sect"): se encubren en los robos, se defienden y se votan;
  el glosario de bandos no lo muestra. En las elecciones empuja a uno de los suyos a candidato.
- Reunión: viernes 0–1 h llamada, 3 h fin, en `_cemetery_burial_pos`. Usa `join_rite(spot, "sect")` del vecino.
- Encargos del jugador como miembro: **no** (evitamos misiones por ahora). Rangos solo por asistencia; desde
  «Hermano de la Sombra» la secta te paga algo de su caja.

## Cambio pedido por el usuario (2026-11-03): que surja sola, sin fechas

«No quiero sistemas rígidos de cosas que tienen que pasar porque sí». Ya no hay día de fundación ni renacer a los 30
días. Ahora:
- **Nace** solo si se juntan un pueblo que lo pasa mal (malestar medio + golpes recientes: muertes, robos, escándalos,
  contagios) **o** ricos aburridos, y alguien con **poder de convencimiento** (mando, trato, Manipulador, Místico,
  Fanático y lo que le aprecia el pueblo; mínimo 0,45) y un **motivo** (lo pasa mal, se aburre, ambiciona o está
  resentido con el Alba). Puede no nacer nunca.
- **Dos clases:** «los Hijos del Ocaso» (desesperados; de madrugada en el cementerio) y «el Círculo de la Luna Velada»
  (ricos aburridos; de noche en casa del líder, solo gente de su posición, diezmo mayor, casi no profanan).
- **Crece despacio:** como mucho un intento de captación al día (12 % + 1,5 % por miembro), y cuanto más grande, más
  cuesta. Techo de 13.
- **Se apaga despacio:** quien ya no lo pasa mal puede irse (0,8 % al día, menos cuanto más veterano); el líder solo
  abandona si se queda solo y sin motivo. Si muere el líder, hereda el miembro con más labia; si no hay nadie capaz, se
  deshace.
- **Sin renacer automático:** el fundador destapado queda desprestigiado (−0,6 de labia) y nadie le vuelve a seguir.
- El líder elige el día de reunión (nunca el domingo).
