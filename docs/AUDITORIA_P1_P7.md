# Auditoría de los bloques P1–P7 (commits 72327b1, e6fcd86, d47780e)

Auditoría hecha por Claude Code el 2026-11-04 leyendo el código, no los documentos. Este archivo es **para el agente**
(lleva nombres de archivos y funciones); al usuario se le explica en lenguaje de juego.

## 0. Resumen

- Las 4 pruebas pasan: names_check, dialogue_coverage (18 NPC, 577 acciones, 0 errores), social_sim y verify_all
  (exit 0, `TESTS PASSED`, 0 `SCRIPT ERROR`). Ojo: dialogue_coverage contaba 597 acciones antes del bloque P y ahora
  577. No lo he investigado.
- Todas las funciones que llaman los 7 módulos existen, **salvo `WorldClock.advance_to_morning`** (la buena es
  `sleep_until_morning`). No peta porque va protegida con `has_method`, pero no hace nada.
- **Guardado:** el estado de los 7 bloques vive dentro de `family_state`, `faith_state`, `town_state` y `needs_state`,
  que ya se guardaban y cargaban enteros (VillageManager.gd:4561-4645), así que **se guarda bien**. Por vecino se
  guardan `family_id`, `family_name`, `npc_name`, `trade_role`, `npc_role`, `lodging`, la cama y el oro. Sin
  comprobar: si `trade_npcs[SHERIFF]` se reconstruye tras cargar cuando P5.7 cambia de comisario.
- Balance de las 70 mecánicas (conectada = cambia la simulación, no que esté libre de fallos):
  - Conectadas: unas 45.
  - Parciales: unas 16.
  - Humo o explotables: unas 9.
- El test #82 tiene unas 22 comprobaciones. Mira que se pone una marca, no que el resultado tenga sentido en el juego,
  y no detecta ninguno de los fallos de las secciones 1 y 2.

## Estado de los arreglos

- [x] Puntos 1.1 y 1.2 arreglados (bloque PA, ver `docs/REGISTRO_TRABAJO.md`). También 1.7 (tumbas), P2.5 (autopsia) y
  el contrato de sicario.
- [x] Bloque PB: 1.3 (veneno con retraso y testigos), 1.4 (doble E para confirmar), 1.5 (la cama pasa la noche),
  1.6 (ya en PA) y la sección 2 (moción con firmas y espera de 30 días, nombrar comisario no borra la búsqueda,
  títere solo si conoces el trapo sucio, testamento con el oro real del muerto, recompensas del bolsillo del vecino,
  nadie vive en dos casas, el adoptado se muda y no se readopta, rencor del clan solo si alguien te vio matar).
- [ ] Pendiente (riesgo bajo, sin arreglar): cambiar el nombre a niños puede desincronizar registros por nombre.
- Aviso: el CHANGELOG y REGISTRO_TRABAJO describen varias mecánicas P que no existen en el código.

## 1. Fallos graves (arreglar primero)

1. **El misterio de los asesinatos se rompe en tres sitios.**
   - En el menú forense del comisario o el guardia, las opciones nombran al asesino real:
     - «rastro de arrastre hasta la casa de X»;
     - «coartada falsa de A a favor de X»;
     - «chivo expiatorio… señalar a X»;
     - «X contrató a Y como sicario»;
     - «X confesó ebrio».

     Basta con abrir el menú para saber quién fue (VillageForensics.gd:244-295). Esas opciones solo deberían aparecer
     cuando el jugador ya tenga la pista (una marca `player_knows`), y el texto no debería nombrar al culpable hasta
     después de elegirla.
   - `VillageDesires.try_commit_murder` llama a `VillageClans.on_murder_resolved` **en el mismo instante del
     crimen** (VillageDesires.gd:410). La familia de la víctima odia al asesino (−90), jura venganza y declara un feudo
     antes de que nadie lo sepa. Esa línea hay que quitarla: debe ocurrir solo al cerrar el caso.
   - `on_murder_resolved` adivina al culpable buscando un nombre dentro del texto de cierre (VillageClans.gd:157-161).
     Los textos de cierre llevan «…por el Comisario Vane…», así que puede elegir **al comisario como asesino**, sobre
     todo en «Caso Archivado por el Comisario Vane». Además «Ana» encaja dentro de «Mariana». Hay que pasar la clave del
     culpable de forma explícita, y no llamar a la función en casos archivados ni en muertes naturales.
   - En el chivatazo del borracho, `on_murder_resolved` se ejecuta dos veces (`_mark_morgue_case_resolved` ya la
     llama, y VillageForensics.gd:466 la llama otra vez). Si se suma la llamada del momento del crimen, son tres: tres
     veces −90 y tres deseos de venganza intentados.
2. **Oro infinito o regalado (P7 y P6).**
   - `underworld_fence_goods` da +25 sin quitar nada del inventario y se puede repetir sin límite.
   - `underworld_join_brawl` da +35 al día y siempre se gana.
   - `underworld_steal_heist` roba el encargo desde el diálogo, sin ir al sitio: 55 de oro por tres clics.
   - El polvo de ocaso se cocina a 5 por dosis y se vende a 38. Además el comprador paga aunque no tenga el oro (se
     queda en 0 y el oro se crea).
   - Las extorsiones y el tributo de jefe del hampa crean oro de la nada y no tienen ninguna consecuencia.
   - El cofre de tu propia casa da 18–32 de oro y un objeto cada día (VillageManager.gd:2777-2791). No sirve para
     guardar cosas, como prometía P6.2.
   - La escritura de un local paga como mínimo 6 aunque la caja esté vacía.
   - Los usureros no tienen plazo: `due_day` no se comprueba nunca.
3. **Veneno = asesinato gratis.** `underworld_use_poison` mata a cualquier adulto (que no sea guardia ni comisario)
   desde el diálogo, sin testigos, sin tirada y sin riesgo, por 35 de oro (VillageUnderworld.gd:324). Mi propuesta:
   que actúe en horas o días, que pueda haber testigos, y que el registro de veneno lento lleve el nombre del jugador
   de forma coherente («Jugador», no «player»).
4. **Pulsar E compra o decide sin confirmar.**
   - Cerca del cartel de un solar libre, pulsar E compra la casa al momento por 100 de oro, o con hipoteca si no
     llegas (VillageHousing.gd:154-166).
   - En el escritorio del ayuntamiento, pulsar E te inscribe como candidato o, si mandas, cambia los impuestos en
     bucle.

   Hace falta un diálogo de confirmación.
5. **La cama de tu casa no pasa el tiempo.** Te deja con el sueño, la higiene y el aguante al máximo al instante y
   cuantas veces quieras, porque `advance_to_morning` no existe. Hay que usar `WorldClock.sleep_until_morning` y
   limitarlo a la noche.
6. **La protección se cobra dos veces por semana.** `is_sat = weekday()==5 or day%7==5` es verdad el sábado
   (`day%7==6`) y también el viernes (`day%7==5`) (VillageUnderworld.gd:179). Hay que dejar solo `weekday()==5`.
7. **Tumbas profanadas.** P4.5 excomulga al culpable el mismo día aunque nadie lo sepa (`known` no se usa nunca), y la
   crónica pública lo nombra (VillageConfession.gd:273-278). La opción «Limpiar la lápida y señalar a X» también
   revela al culpable a cualquiera con quien hables (VillageClans.gd:455-457).

## 2. Fallos medios

- **P5.10 moción:** por 20 de oro hay elecciones inmediatas con el jugador como candidato, y se puede repetir hasta
  ganar.
- **P5.7 nombrar comisario:** pone `wanted_level = 0`, así que se borra tu búsqueda por 30 de oro de las arcas.
- **P5.9 títere:** basta con que el alcalde tenga algo turbio. El jugador no necesita saberlo, y la propia opción le
  revela que lo hay.
- **P2.4 contrato de sicario al jugador:** aceptarlo da 45 de oro y no te obliga a nada. Ni el rico ni nadie lo
  comprueba.
- **P2.5:** la opción de autopsia enumera a los envenenados antes de que se encuentre el cuerpo. Eso revela que hubo
  envenenamiento.
- **P1.9 testamento:** el ganador recibe `max(40, oro del muerto)` de oro nuevo, y además ese oro probablemente lo
  hereda también el sistema de herencia que ya existía, así que se duplica. El jugador cobra +25 de la nada.
- **Recompensas que salen de la nada** (en P1, P3 y P7 casi todas):
  - romance +20;
  - favor +25;
  - tumba +15;
  - hermanastros +15;
  - cazafortunas +20.

  En vez de crear oro, deberían salir del bolsillo del vecino.
- **P6.4 mudarse contigo:** basta afinidad ≥65 y estar soltero, sin que haya romance. No se le quita de la lista de
  residentes de su casa anterior, así que vive en dos sitios.
- **P3.7 adopción por el jugador:** solo cambia la familia a `family_player`. El niño no se muda ni cambia nada. Como
  nadie adulto es `family_player`, sigue contando como huérfano y se puede volver a adoptar.
- **Cambiar el nombre a niños (P3.4 y P3.7):** muchos registros van por nombre (`npc_murders`, `vagrant_camp_nodes`,
  `dead_enemies`, casos forenses, textos de misiones). El riesgo de que se desincronicen es bajo, pero existe.
- **P1 boicot por golpe del jugador:** un solo golpe mortal marca a la familia entera como «severe» para siempre;
  disculparse cuesta 20.

## 3. Las 70 mecánicas, una por una

Leyenda: **C** = conectada a la simulación; **P** = parcial o con agujero; **H** = humo o explotable.

### P1 Clanes

| Mecánica | Estado | Comentario |
|---|---|---|
| 1 Heredar el odio | C | |
| 2 Feudo | C | Dos peleas entre familias. |
| 3 Boicot | C | Precio ×2 y se niega a venderte. |
| 4 Amor prohibido | C/P | Ayudar = boda instantánea + 20 de oro. |
| 5 Huérfano | C | Falla por el fallo 1.2. |
| 6 Cena de paz | C | Trivial. |
| 7 Desheredar | C | |
| 8 Deuda de honor | C | |
| 9 Testamento | P | Oro duplicado. |
| 10 Tumba | P | Ver el fallo 1.7. |

### P2 Forense

| Mecánica | Estado | Comentario |
|---|---|---|
| 1 Plantar objeto | C | El menú revela. |
| 2 Coartadas | C | El menú revela. |
| 3 Testigo | C | Mínimo. |
| 4 Sicario | C | El contrato al jugador es H. |
| 5 Veneno lento | P | |
| 6 Incriminar | C | |
| 7 Mover el cadáver | P | Solo lo desplaza 96 px y el menú revela. |
| 8 Confesión borracho | C | Triple venganza. |
| 9 Chivo expiatorio | C | |
| 10 Emboscada | C | |

### P3 Linaje

| Mecánica | Estado | Comentario |
|---|---|---|
| 1 Embarazo | C | |
| 2 Rasgo heredado | C | |
| 3 Chantaje | C | |
| 4 Revelar | C | |
| 5 Manutención | C | |
| 6 Expósito | C | |
| 7 Adopción por el jugador | H | |
| 8 Hermanastros | H | Solo relaciones y oro; no decide el taller. |
| 9 Cazafortunas | P | Si no lo destapas, no pasa nada propio. |
| 10 Pasado | H | Una deuda sin consecuencias. |

### P4 Confesión

| Mecánica | Estado | Comentario |
|---|---|---|
| 1 a 8 | C | Lo más sólido del bloque. |
| 5 Excomunión | C | Con el disparo erróneo del fallo 1.7. |
| 9 Crisis de fe | P | Solo dos botones. |
| 10 Santuario | P | Pagar 15 = búsqueda a 0. |

### P5 Alcaldía

| Mecánica | Estado | Comentario |
|---|---|---|
| 1 a 6 | C | Ley seca, toque de queda y subvención funcionan. |
| 7 Nombrar comisario | P | |
| 8 Desfalco | C | |
| 9 Títere | P | |
| 10 Moción | H | |

### P6 Casa

| Mecánica | Estado | Comentario |
|---|---|---|
| 1 Comprar casa | C | |
| 2 Cama y cofre | P | Fallo 1.5; el cofre da oro. |
| 3 Mejoras | P | La cama de roble no hace nada. |
| 4 Pareja en casa | P | |
| 5 Ser casero | C | |
| 6 Trato con inquilinos | C | |
| 7 Huerto | C | |
| 8 Cenas | C | |
| 9 Escondite | C | Solo se usa hablando con el carpintero. |
| 10 Locales | P | Oro mínimo de la nada. |

### P7 Hampa

| Mecánica | Estado | Comentario |
|---|---|---|
| 1 Perista | C | |
| 2 Catálogo | P | Venta infinita y veneno. |
| 3 Polvo de ocaso | H | |
| 4 Encargo de robo | H | Se hace desde el diálogo. |
| 5 Usura | C/P | Sin plazo. |
| 6 Protección | H | |
| 7 Ladrón a sueldo | C | |
| 8 Club de pelea | H | |
| 9 Soborno a la ronda | C | Solo protege de robos al jugador. |
| 10 Delatar / jefe | P | |

## 4. Orden recomendado de arreglos

1. Que el misterio no se rompa: fallos 1.1, 1.7 y P2.5. Es el corazón del juego.
2. Quitar el oro infinito y el veneno gratis: fallos 1.2 y 1.3.
3. Pedir confirmación al pulsar E, que la cama pase el tiempo y corregir el doble cobro: fallos 1.4, 1.5 y 1.6.
4. Los fallos medios de la sección 2.
5. Un test por cada arreglo, que compruebe la consecuencia y no solo la marca.

Opinión: el bloque P se hizo deprisa y a lo ancho. En vez de 70 mecánicas a medias, convenía rematar 20–30. El
patrón que más se repite es una opción de menú que da oro o efectos al instante, sin coste, sin riesgo y sin que el
mundo reaccione. Eso va contra la regla del proyecto «nada rígido, todo surge de condiciones».
