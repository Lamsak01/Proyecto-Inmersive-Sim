# Registro de trabajo autónomo

El usuario dio vía libre el 2026-11-03 («implementa todo lo del plan sin parar mientras duermo; pruebas solo al final
de un bloque grande; lleva un registro por si algo falla»). Aquí se apunta cada paso en orden, con su estado, los
archivos tocados y lo que queda sin probar. Si algo falla, este es el sitio para ver qué cambió y cuándo.

Leyenda: ✅ probado y subido · 🟡 escrito, sin probar · 🔴 falló (ver nota) · ⏳ en marcha

## Bloque A — Cerrar «crecer el pueblo» (V3, V6, V9, V7, solares, UI1)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| A1 | V3 llegadas y marchas | ✅ | VillageMigration.gd | Subido en 9914a3c |
| A2 | V6 nobles | ✅ | VillageNobility.gd, VillageTown.gd, VillageNPC.gd | Fallo de carga (PersonProfile) corregido; el juego ya carga |
| A3 | Solares fila m (m1–m5) y calleja | ✅ | VillageLots.gd | |
| A4 | V9 hijos, escuela y maestro | ✅ | VillageFamily.gd + filtros de edad | |
| A5 | V7 sonda de crecimiento | ✅ | tools/tests/growth_probe.gd | |
| A6 | UI1 diálogo ordenado | ✅ | NPCDialogue.gd | |
| A7 | Pruebas del bloque (4 suites) | ✅ | verify_all.gd | Fallo en el test del señor (dependía del oro tras impuestos), corregido |
| A8 | Sonda de crecimiento (30 días) | ✅ | growth_probe.gd | En segundo plano |

## Bloque B — Cabos sueltos del plan (V3 familias, V9 oficio y juego, escuela)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| B1 | Cartel de la escuela: «Abierta · maestro · N alumnos» / «Esperando alumnos» | ✅ | VillageCulture.gd (`school_sign` en meta de vm), VillageFamily.update_school | |
| B2 | Llegan familias con 1–2 hijos (2–12 años), casados | ✅ | VillageMigration (tipo «familia», peso 0,1), VillageFamily.spawn_child / marry | Solo si hay casa con 2 camas; los niños no ocupan cama |
| B3 | Al hacerse mayor, si su madre o padre lleva un negocio sin ayudante, se queda de ayudante (`FAMILY_MEMBER`) y lo heredará | ✅ | VillageFamily.grow_up | Si no, sigue como antes (sin oficio) |
| B4 | Los nobles ya no aparecen como «llegó al valle» en los sucesos | ✅ | VillageNobility.spawn_households | |
| B5 | Los niños salen a jugar entre semana de 14 a 20 h (+0,15 de ganas) y se ve «🧒 Jugando en…» | ✅ | VillagePlaces.is_leisure_hour(hour, n) | |

## Bloque C — Guardado de lo nuevo y equilibrio del crecimiento

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| C1 | **Fallo real**: al cargar partida, nobles (`NPC_Noble_`) y niños (`NPC_Child_`) se perdían porque GameManager solo recupera ciertos prefijos | ✅ | GameManager.gd (dos listas de prefijos) | Test #74 guarda y carga con un niño y los nobles |
| C2 | Test #73 de los cabos sueltos del bloque B | ✅ | verify_all.gd | |
| C3 | Sonda: 30 días era demasiado (≈4 min reales por día de juego); relanzada con 12 días | ✅ | growth_probe.gd | Primeros datos (intento 1): de 18 a 28 vecinos en 3 días, casi todos por tiendas vacantes; escasez de comida desde el día 3 (atractivo −0,4) |
| C4 | **Fallo mío en V3**: el atractivo leía `village_food_shortage_days` (un total que nunca baja) como «hay hambre ahora» → −0,4 para siempre tras la primera comida fallida. Ahora cuenta las comidas fallidas del último día frente a la población (−0,4 si fallan el 15 % o más) | ✅ | VillageMigration.attractiveness (`food_seen` en migration_state) | La sonda en marcha usa aún la versión vieja |
| C5 | **Fallo de diseño en V9**: los niños tienen 0 de oro y, con la despensa vacía, no podían comer. Ahora reciben cada día 6 de oro (hasta tener 15) del adulto más rico de su familia, o de las arcas si no hay nadie | ✅ | VillageFamily.give_allowances | |
| C6 | Historia personal propia para niños, nobles y maestro (antes decían «Llegué al valle…») | ✅ | VillageNPC._resolve_unique_64_visuals_and_lore | Textos provisionales (APORTES) |

### Resultados de la sonda (intento 2, 12 días, semilla 11; versión anterior al arreglo de la comida)
- Población 18 → 29 en 12 días; 27 de esas llegadas cubren tiendas vacantes y 2 son de V3. El freno es la vivienda (1 casa terminada el día 10) y, del día 7 al 12, el falso «hambre» (C4).
- Con todos los solares libres construidos se llega a **45** (faltan solares para 50).
- Rendimiento con 45: plaza 6,35 ms/fotograma de media (lejos 3,67 ms); una hora de juego 2,16 ms. **Un tirón de 270 ms en la plaza** sin explicar todavía.

## Bloque D — Llegar a 50 y el tirón

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| D1 | Dos solares más (n6 en 1070,−420 y m6 en 1070,−580; calle norte y calleja alargadas) | ✅ | VillageLots.gd, test #69 | 11 solares de casa → 22 camas |
| D2 | La sonda apunta cuándo ocurre el peor fotograma (tiempo real) y cuántos pasan de 33 ms | ✅ | growth_probe.gd | |

### Pruebas del bloque B+C+D (todas pasan)
- verify_all completo (incluidos #73 cabos sueltos y #74 guardar/cargar con niños y nobles), names_check, social_sim, dialogue_coverage.
- Sonda (12 días, semilla 11, con los arreglos): 18 → 30 vecinos; la comida ya no pesa siempre (solo algún día, −0,09 a −0,40).
  Con todos los solares construidos se llega a **50**. Rendimiento con 50: plaza 5,71 ms/fotograma de media, peor 22 ms;
  lejos 4,43 ms, peor 24 ms; ningún fotograma por encima de 33 ms; una hora de juego 2,39 ms. El tirón de 270 ms del intento 2
  no se repite (aquel número sumaba los contadores internos de Godot, no el tiempo real de pared).
- **Para equilibrar más adelante:** el crecimiento por V3 es lento (2 llegadas en 12 días). Lo frena la vivienda: la primera casa
  se encarga el día 11, seguramente porque ni las arcas (necesitan 100) ni los recién llegados (80) tienen dinero antes.

## Bloque E — Lo que enseñó la sonda y el último pendiente del plan (U5 «según X»)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| E1 | Cada comida fallida se apunta por motivo (`sin_oro` / `sin_comida`) y oficio; la sonda lo imprime (`MEAL_FAILS`) junto a las arcas | ✅ | VillageMigration.note_meal_failure, VillageManager.consume_village_meal_for_npc, growth_probe.gd | Solo diagnóstico: no cambia el juego |
| E2 | Casas: una pareja sin casa junta sus ahorros (si entre los dos llegan a 80); si alguien duerme al raso, el pueblo paga la casa sin guardarse la reserva de 40 | ✅ | VillageMigration.maybe_order_house, `_partner_of` | Cambio de equilibrio: debería haber casas antes |
| E3 | Camas de la posada: un vecino con oficio que duerme ahí (p. ej. el maestro) ya cuenta como ocupada; el maestro de fuera solo llega si hay cama; quien vuelve del raso coge una cama libre (antes la elegía por su nombre y podía repetirse) | ✅ | VillageMigration.free_tavern_bed, VillageFamily.ensure_teacher, VillageManager (noche) | Cierra el cabo «el maestro puede compartir cama» |
| E4 | U5 «según X»: si preguntas a alguien por un íntimo suyo (≥ 30) y te tiene confianza, te cuenta el sentimiento más fuerte (±40) de ese íntimo por un tercero. En la red social sale «🗣️ Según X: …» (lo que sentía entonces; puede quedarse viejo) hasta que se lo preguntes a él | ✅ | VillageNPC.heard_feelings (se guarda), NPCDialogue._hearsay_feeling, SocialGlossaryUI | No cuenta para «mejores amigos / enemigos» |
| E5 | Test #75 (E2, E3, E4) | ✅ | verify_all.gd | |

### Pruebas del bloque E (todas pasan) y lo que dice la sonda
- verify_all (con #75), names_check, social_sim, dialogue_coverage: pasan. Con 50 vecinos: plaza 6,1 ms, peor 22 ms, ninguno > 33 ms.
- Comidas fallidas en 12 días (`MEAL_FAILS`): **sin oro**: ganadero 13, cantero 10, granjero 7; **sin comida a la venta**:
  parados 20, calderero 4, leñador 2, otros 2. Los que producen materia prima se quedan sin dinero: ese es el problema real.
- Desde el día 8 el atractivo cae a −0,15 (comida −0,40 y una muerte, −0,25), y con el pueblo así no se encargan casas
  (`houses_ordered=0` aunque las arcas llegaron a 102). Es coherente con el diseño, pero la comida lo provoca → bloque F.

## Bloque F — Los dueños de las afueras se arruinaban pagando jornales

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| F1 | **Causa encontrada**: granja, rancho y cantera contrataban jornaleros con todo su dinero (10 de oro por jornalero y día; la granja, hasta 4) aunque el almacén estuviera lleno y lo cosechado se tirara. Ahora el dueño se guarda 20 de oro para comer y solo contrata los que hacen falta para llenar el hueco del producto principal (`workers_needed`) | ✅ | VillageWork.hire | Menos jornales para los parados: cobrarán más de la ayuda a los pobres |
| F2 | Diagnóstico más fino: «sin_comida» se parte en `agotado` (no queda comida a la venta en el pueblo) y `caro_o_cerrado` | ✅ | VillageMigration.note_meal_failure | Solo diagnóstico |
| F3 | Test #76 | ✅ | verify_all.gd | |

### Pruebas del bloque F (todas pasan) y sonda
- Los cuatro tests pasan (con #76). Con 50 vecinos: plaza 4,8 ms, lejos 5,5 ms, peor 28 ms, ninguno > 33 ms.
- Ganaderos, canteros y granjeros **ya no se quedan sin oro** (antes 30 comidas fallidas; ahora 1).
- Siguen fallando: ayudantes de negocio familiar **sin oro** (18) y parados con comida en el pueblo pero cara o cerrada (23).
  Se encargó y terminó 1 casa (día 9–12). Siguiente: ver por qué los ayudantes no tienen dinero.

## Bloque G — Los ayudantes de negocio familiar no cobraban nada

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| G1 | Quien ayuda en el negocio de su familia (`FAMILY_MEMBER`) no tenía ningún ingreso ni podía hacer jornales. Ahora, cada día, si tiene menos de 15 de oro, el dueño del negocio de su familia le da 6 (si al dueño le quedan 20) | ✅ | VillageFamily.pay_helpers | Igual que la paga de los niños |
| G2 | Test #77 | ✅ | verify_all.gd | |
| — | **Sin tocar, para hablarlo:** parados que no comen aunque hay comida (cara o tienda cerrada a esa hora). Hace falta saber a qué hora y a qué precio fallan antes de cambiar nada | — | | |

### Pruebas del bloque G (todas pasan) y sonda
- Los cuatro tests pasan (con #77). Con 50 vecinos: plaza 5,9 ms, lejos 4,0 ms, peor 23 ms, ninguno > 33 ms.
- Comidas fallidas en 12 días: **16** (antes de E–G, 58; tras F, 50). Ayudantes: de 18 a 1; parados: de 23 a 3.
  Lo que queda está repartido entre oficios y horas (6–7 h, 10–11 h, 18 h, 23 h): no hay una causa única.
- Primer embarazo y nacimiento en la sonda (días 4 y 13). Ninguna casa nueva: las arcas acaban en 48 (pagan la paga
  de los niños, al maestro y la ayuda a los pobres) y nadie sin casa tiene 80. Queda para equilibrar con el usuario.

## Bloque H — Casas a plazos con interés (aprobado por el usuario: casa 100 de oro, interés 25 %)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| H1 | La casa cuesta 100 (antes 60). Quien no tiene casa y junta 15 de entrada (con su pareja) pide el resto: a las arcas si les sobra (se guardan 40) o, si no, al noble más rico (se guarda 50), que se queda con los intereses. Devuelve el préstamo +25 % a 3 de oro al día | ✅ | VillageLoans.gd (nuevo), VillageMigration.maybe_order_house, VillageLots (coste) | El préstamo vive en el solar (`loan`), se guarda con los solares |
| H2 | Si no llega a la cuota: +1 de recargo, −6 de humor y el noble prestamista le aprecia −4. A los 5 impagos seguidos, la casa pasa al prestamista y los moradores van a la posada (si hay cama) o a la calle (−15 y −20 con el noble) | ✅ | VillageLoans.daily / evict | |
| H3 | Una casa de otro (p. ej. del noble tras un desahucio) cobra el alquiler de 2 para su dueño | ✅ | VillageMigration.nightly | |
| H4 | Se ve en la ficha («🏦 Debe 94 al pueblo · ⚠️ 2 cuotas sin pagar») y en la crónica (préstamo 🏦, casa pagada 🔑, desahucio 📦) | ✅ | VillageNPC._get_needs_status_line, VillageChronicle | |
| H5 | Test #78 (y #4/#75 ajustados al nuevo precio) | ✅ | verify_all.gd | |

### Pruebas del bloque H (todas pasan) y sonda
- Los cuatro tests pasan (con #78). La sonda: **2 casas encargadas a plazos** (antes 0–1 en 12 días), las dos prestadas por
  un noble (Dagoberto Lagos), que va cobrando sin impagos (debe 90 y 93). Las arcas acaban en 217.
- Rendimiento con 50: plaza 7,4 ms y algún fotograma > 33 ms (peor 42 ms). Peor que antes, pero esta vez la sonda tardó un
  12 % más en tiempo real (588 s frente a 527): el ordenador estaba ocupado (el usuario jugaba a la vez). Repetir en frío.
- Comidas fallidas: los canteros vuelven a quedarse sin oro (12) y los parados (9). A vigilar.

## Bloque I — Mapa grande legible (captura del usuario: nombres pisados)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| I1 | El mapa grande ocupa casi toda la pantalla (antes 900×550 fijos) | 🟡 | ValleyMapUI._fit_full_map | |
| I2 | Nombres de edificios con fondo oscuro; si no caben se acortan; si chocan, van debajo o se omiten | 🟡 | ValleyMapUI._draw_building_labels | |
| I3 | Al pasar el cursor por cualquier edificio sale su nombre completo (antes solo las 5 tiendas originales) | 🟡 | ValleyMapUI._update_census_and_hover | Sin test: es dibujo; el juego carga sin errores |

## Bloque J — Jabalíes, causa de la muerte, arcas y gachas (aprobado por el usuario)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| J1 | Los jabalíes mataban siempre al carnicero: se quedaba quieto disparando mientras le embestían, y si caía al suelo el jabalí lo remataba. Ahora el cazador prefiere ciervos y conejos (jabalí solo si no hay otra presa); si un jabalí le embiste y va por la mitad de la salud, se retira y el jabalí pierde el interés; el jabalí deja en paz a quien ya está en el suelo | ✅ | EcosystemManager.find_sustainable_hunt_prey, VillageNPC.should_flee_boar / flee_from_boar, WildAnimal (embestida) | También vale para quien caza por hambre |
| J2 | Herida con nombre («Embestida de jabalí», «Mordedura de zorro», «Herida de asaltante»). Hambre, animales o enfermedad no abren caso: la crónica dice «Hallaron el cuerpo sin vida de X: lo mató un jabalí / murió de hambre» y el registro de la morgue queda resuelto para el entierro | ✅ | VillageNPC (death_cause_for_source, is_natural_death_cause), VillageJustice.start_sheriff_investigation, VillageManager (registro) | Los asaltantes sí abren caso |
| J3 | Partida nueva: arcas con 1000 de oro | ✅ | VillageTown.STARTING_TREASURY | Las guardadas no cambian |
| J4 | Gachas del Albergue: a las 6 h el cura prepara pobres + 2 raciones (tope 8), 2 de oro cada una de las arcas; último recurso antes del hambre: 1 de oro o gratis | ✅ | VillageCivic.cook_shelter_rations / take_shelter_ration, VillageManager.consume_village_meal_for_npc | Las que sobran no se guardan |
| J5 | Test #79; la sonda apunta muertes y raciones servidas | ✅ | verify_all.gd, growth_probe.gd | |

### Pruebas del bloque J (todas pasan) y sonda
- Los cuatro tests pasan (con #79). Con 50 vecinos: plaza 5,4 ms, lejos 4,5 ms, peor 21 ms, ninguno > 33 ms.
- Sonda de 12 días: **0 comidas fallidas** (antes 16) y **0 muertes**; 5 raciones de gachas servidas. Población 18 → 34
  (6 llegadas por V3), 3 casas encargadas (2 a plazos, prestadas por el pueblo). Las arcas acaban en 962.
- Lo de los jabalíes no se puede ver en la sonda (no hubo caza peligrosa); queda para la prueba manual.

## Bloque K — Canteros a la vista y misión de Varris (avisos del usuario)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| K1 | El cantero trabajaba dentro del edificio y solo le compraba el herrero. Ahora trabaja en la roca y cada obra compra 3 piedras y 3 troncos | ✅ | VillageTrades.yard_pos / fix_quarry_post, VillageLots.buy_materials | Test #80 |
| K2 | Misión sobre Varris: al hablar con el objetivo no salía cómo seguir. Ahora quien la pidió va primero en la lista de opiniones, hay atajo «📜 Encargo», aviso si ya intercediste hoy y pista si te tiene en negativo | ✅ | NPCDialogue | Probado en N2/N7 (test #81) |

## Bloque M — 20 misiones nuevas (tanda 1 de 2, aprobada: «hazlas por tandas de 10»)

| # | Tipo | Estado | Mecánica que toca |
|---|------|--------|-------------------|
| M1 | affair_doubt | ✅ | Secretos (aventuras, reacción de la pareja) — probado en N7 (#81) |
| M2 | loan_trouble | ✅ | Préstamos de casas, nobles — probado en N7 (#81) |
| M3 | boar_hunt | ✅ | Ecosistema (mínimo de jabalíes) — probado en N7 (#81) |
| M4 | vote_buying | ✅ | Elecciones, promesas de voto — probado en N7 (#81) |
| M5 | embezzle_proof | ✅ | Desfalco del alcalde, `expose` — probado en N7 (#81) |
| M6 | poor_medicine | ✅ | Enfermedades, médico, parroquia |
| M7 | faith_doubt | ✅ | Fe, asistencia al Oficio |
| M8 | apprentice | ✅ | Ayudantes de taller, herencia |
| M9 | sabotage_job | ✅ | Sabotaje de puestos, ley — probado en N7 (#81) |
| M10 | scared_witness | ✅ | Expediente del comisario, asesino real — probado en N7 (#81) |

✅ = con test funcional (#81).

### Pruebas de los bloques K y M (todas pasan) y sonda
- Los cuatro tests pasan (con #80 y #81). Con 49 vecinos: plaza 6,0 ms, lejos 3,9 ms, peor 23 ms, ninguno > 33 ms.
- Sonda de 12 días: 0 comidas fallidas, 0 muertes, 14 raciones de gachas. Población 25 → 33, 3 casas encargadas (2 a plazos). Arcas 948.

## Bloque M — tanda 2 de 2 («sigue con la segunda tanda»)

| # | Tipo | Estado | Mecánica que toca |
|---|------|--------|-------------------|
| M11 | empty_pots | ✅ | Gachas del Albergue, clases, generosidad |
| M12 | love_letter | ✅ | Chispa (SocialDirector), rasgos — probado en N7 (#81) |
| M13 | inheritance | ✅ | Sucesión de talleres, ayudantes — probado en N7 (#81) |
| M14 | last_drink | ✅ | Vicios; veto nuevo en `do_vice` |
| M15 | market_stall | ✅ | Mercado del miércoles, stock |
| M16 | night_reading | ✅ | Secta, biblioteca — probado en N7 (#81) |
| M17 | announced_fight | ✅ | Tensión y peleas en vivo — probado en N7 (#81) |
| M18 | homeless | ✅ | Desahucios, casas, posada |
| M19 | strange_newcomer | ✅ | Llegadas, descubrir rasgos, marcharse — probado en N7 (#81) |
| M20 | nameless_grave | ✅ | Archivo de la morgue, asesino real — probado en N7 (#81) |

Cambios de diseño honestos: «¿Quién lo ha dicho?» repetía la misión `rumor` → sustituida por «La última copa»;
«¿Me corresponde?» repetía `opinion` → hecha como carta que sí actúa sobre la chispa (sin forzar parejas).
*(Nota: el guardado de marcas en partida se completó después en N1.)*

### Pruebas de la tanda 2 (todas pasan) y sonda
- Los cuatro tests pasan (#81 ampliado: 25 tipos, veto de taberna, donativos, puesto de mercado, sin techo).
  Con 49 vecinos: plaza 5,5 ms, lejos 4,4 ms, peor 24 ms, ninguno > 33 ms.
- Sonda de 12 días: 0 comidas fallidas, 0 muertes, 4 raciones de gachas. Población 25 → 31, 2 casas (1 a plazos). Arcas 990.

## Traspaso (2026-11-03)
El usuario pasa a Antigravity. Prompt completo para el siguiente agente: `docs/PROMPT_SIGUIENTE_AGENTE.md`
(enlazado desde HANDOFF §0 y CLAUDE.md).

## Bloque N — Guardado de marcas de misión y prueba funcional de las 13 misiones en 🟡

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| N1 | Guardar marcas de misión en cada vecino (`evicted_day/lot`, `inherited_day/from/family`, `read_day`, `arrived_day`, `rite_invited_week`, `new_clothes_day`) | ✅ | VillageNPC.gd (`to_save_dict` / `from_save_dict`) | Test #81 |
| N2 | Atajo «📜 Encargo» (K2): funciona también en `slander` hablando con terceros y no sale por error en misiones ajenas al menú de opiniones | ✅ | NPCDialogue.gd | Test #81 |
| N3 | `affair_doubt`: no se ofrece si `known_by` está vacío (nadie en el pueblo vio nada) | ✅ | QuestAffairDoubt.gd | Test #81 |
| N4 | `loan_trouble`: sin fallo al abrir diálogo el día del desahucio y corregido «a al alcalde» | ✅ | QuestLoanTrouble.gd | Test #81 |
| N5 | `homeless`: dar los 18 de oro para la posada devuelve cama en el acto (antes si cenaba a las 18h bajaba de 18 y no recuperaba cama a medianoche) | ✅ | QuestHomeless.gd | Test #81 |
| N6 | `strange_newcomer`: descubrir rasgos por cualquier vía cuenta para el encargo | ✅ | QuestStrangeNewcomer.gd | Test #81 |
| N7 | Pruebas funcionales de las 13 misiones que estaban en 🟡 (M1–M5, M9–M10, M12–M13, M16–M17, M19–M20) + 4 suites completas | ✅ | verify_all.gd | `names_check`, `social_sim`, `dialogue_coverage` (0 errores) y `verify_all` pasan |
| N8 | Limpieza de los 19 avisos amarillos del editor + 7 divisiones enteras en encargos | ✅ | VillageFaith, VillageNeeds, VillageSecrets, VillageIllness, VillageTown, VillageTrades, VillageWork, VillageMigration, VillageFamily, VillageManager y 7 Quest*.gd | `names_check` pasa; sin cambio de comportamiento |
| N9 | Cuadro de diálogo con barra de desplazamiento (`_choices_scroll`) y tope de altura para que no se corte en los bordes | ✅ | scenes/dialogue_manager.gd | Comprobado en juego por el usuario (captura con Marta) y `dialogue_coverage` |
| N10 | Ocultar `ObjectiveHUD` antiguo en inglés («Eliminate Frogs») encima del minimapa | ✅ | scenes/ui_root.gd, scripts/ui/ObjectiveHUD.gd | Se oculta al iniciar y al avanzar el reloj |
| N11 | Barras de estado compactas (`108×12`, icono sin palabras) y dinámicas (hambre, sueño e higiene solo se muestran por debajo del 75 %) | ✅ | scenes/ui_root.gd | Se aplica también en caliente al avanzar el reloj |

## Bloques P1–P7 — Mecánicas implementadas (revisadas tras auditoría)

| # | Bloque | Estado | Archivos principales | Nota |
|---|--------|--------|----------------------|------|
| P1 | Rencores de familia y clanes (heredar odio, feudos de sangre, boicot comercial, amor prohibido entre clanes, huérfanos vengadores a los 16, cenas de paz, desheredar oveja negra, deuda de honor vitalicia, testamentos disputados y tumbas profanadas) | ✅ | `scripts/systems/VillageClans.gd`, `VillageManager.gd`, `VillageNPC.gd`, `NPCDialogue.gd`, `VillageSocialLife.gd`, `VillageFamily.gd`, `VillageMigration.gd` | Test #82 |
| P2 | Asesinatos, pistas falsas e investigaciones (plantar pista falsa, coartadas de parientes/secta, testigos intimidados, sicarios por encargo, veneno lento y autopsia, incriminar vecinos, cadáver arrastrado, confesiones ebrio/febril, chivo expiatorio y emboscadas nocturnas) | ✅ | `scripts/systems/VillageForensics.gd`, `VillageJustice.gd`, `VillageDesires.gd`, `NPCDialogue.gd` | Test #82 |
| P3 | Hijos secretos, romances prohibidos y vida familiar (embarazo de amante, rasgo heredado y rumor a los 6 años, chantaje, revelar paternidad con cambio de apellido sincronizado, manutención los lunes, expósitos en la capilla, adopciones, disputa de hermanastros a los 16, cazafortunas y deuda del pasado) | ✅ | `scripts/systems/VillageLineage.gd`, `VillageFamily.gd`, `NPCDialogue.gd` | Test #82 |
| P4 | Confesión, secretos de la capilla y fe (confesión martes y jueves, espiar confesionario, cura corrupto que vende secretos, penitencias al día siguiente, excomunión, confesarte tú, bulas para ricos, sermón dominical con indirectas, crisis de fe del cura y derecho de santuario) | ✅ | `scripts/systems/VillageConfession.gd`, `VillageFaith.gd`, `VillageNeeds.gd`, `NPCDialogue.gd` | Test #82 |
| P5 | Presentarte a Alcalde, leyes y política (candidatura del jugador, promesas, discursos y trapos sucios, impuestos bajos/normales/altos, decretos: ley seca, toque de queda y subvención al mercado, obras públicas, nombrar comisario, desfalco/maquillar cuentas, alcalde títere y moción con firmas) | ✅ | `scripts/systems/VillageMayor.gd`, `VillageTown.gd`, `VillageNeeds.gd`, `VillageCrime.gd`, `VillageNPC.gd`, `NPCDialogue.gd` | Test #82 |
| P6 | Casa propia, propiedades y ser terrateniente (comprar solar al contado o con hipoteca, cama propia nocturna y cofre privado, mejoras del carpintero, vivir con tu pareja, ser casero cobrando alquiler, subir/perdonar renta y desahuciar, huerto casero, cenas en casa, escondite bajo las tablas y escrituras de locales) | ✅ | `scripts/systems/VillageHousing.gd`, `VillageLoans.gd`, `VillageMigration.gd`, `VillageCrime.gd`, `VillageManager.gd`, `NPCDialogue.gd` | Test #82 |
| P7 | Mercado negro, contrabando y bajos fondos (perista nocturno, catálogo ilegal: ganzúas, veneno lento, somnífero y papeles falsos, destilar y vender polvo de ocaso, robos por encargo en el sitio, usura, cobro de protección los sábados, matones/ladrones a sueldo, club de pelea clandestino, soborno de patrulla y delatar/destronar al perista) | ✅ | `scripts/systems/VillageUnderworld.gd`, `VillageCrime.gd`, `VillageManager.gd`, `NPCDialogue.gd` | Test #82 |

## Bloque PA — Auditoría de P1–P7 y arreglos de los puntos 1 y 2 (Claude Code, 2026-11-04)

Informe completo: `docs/AUDITORIA_P1_P7.md`.

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PA1 | El rencor de clan solo al cerrar el caso; culpable leído del texto de cierre (`culprit_from_note`), nunca por subcadena (el comisario Vane salía como asesino) | ✅ | VillageDesires.gd, VillageClans.gd | Test #82 |
| PA2 | Menú forense sin nombre del asesino: rastro, chivo, testigo y coartada solo con la persona implicada; sicario solo si el jugador conocía el plan; borracho hay que oírle antes de delatar; autopsia solo de cuerpos hallados; quitado el doble aviso a clanes | ✅ | VillageForensics.gd | Test #82 |
| PA3 | Tumbas: culpable solo se sabe con 50 % al limpiar; excomunión solo si se sabe; propina del bolsillo del vecino | ✅ | VillageClans.gd, VillageConfession.gd | — |
| PA4 | Contrato de sicario: escuchar → aceptar → cobra al morir el objetivo, del oro del rico | ✅ | VillageForensics.gd | — |
| PA5 | Hampa sin oro infinito: perista compra objetos reales con su oro; golpe solo en el sitio con testigos; pelea con riesgo; apuesta al azar; polvo con comprador solvente y destilado 1/día; protección solo sábado y de la caja; tributo del perista; ratero y usura sin crear oro | ✅ | VillageUnderworld.gd | Test #82 |
| PA6 | Cofre propio sin oro gratis; renta de locales solo de la caja | ✅ | VillageManager.gd, VillageHousing.gd | — |

## Bloque PB — Auditoría de P1–P7: puntos 3–7 y fallos medios (Claude Code, 2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PB1 | Veneno lento: testigo puede verlo (búsqueda +1); si no, muere al día siguiente (`pending_poison`), 20 % sobrevive | ✅ | VillageUnderworld.gd | Test #82 |
| PB2 | Doble E para confirmar compra de solar, cambio de impuestos y candidatura (`press_twice`) | ✅ | VillageHousing.gd, VillageMayor.gd | — |
| PB3 | Cama propia: solo de 20:00 a 06:00 y pasa la noche (`sleep_until_morning`) | ✅ | VillageHousing.gd | — |
| PB4 | Moción: espera de 30 días y 6 firmas (afinidad ≥ 20); nombrar comisario ya no borra la búsqueda; títere solo si el jugador conoce el trapo sucio | ✅ | VillageMayor.gd | — |
| PB5 | Testamento con el oro real del muerto; recompensas de P1/P3 con `VillageClans.pay_from_pocket` | ✅ | VillageClans.gd, VillageLineage.gd | — |
| PB6 | `move_into_player_home`: saca al vecino de su casa anterior; el adoptado se muda y no se readopta | ✅ | VillageHousing.gd, VillageLineage.gd | — |
| PB7 | Rencor del clan por un golpe tuyo solo si hubo testigo (si no, al cerrarse el caso contra ti) | ✅ | VillageClans.gd | — |
| PB8 | Sincronizar registros indexados por nombre al cambiar el apellido de un niño (`rename_child`) | ✅ | VillageLineage.gd | Test #82 (`682e1bd`) |

## Bloque PC — Las 29 mecánicas pendientes de P1–P7 implementadas en 6 tandas (2026-11-04)

| # | Tanda | Mecánicas (5 por tanda) | Estado | Archivos | Nota |
|---|-------|-------------------------|--------|----------|------|
| PC1 | Tanda 1 (1–5) | Fregar escena con lejía (`bleach_crime_scene`, doble E), sobornar autopsia (`forensic_bribe_autopsy`), pólizas de seguro (`insurance`), trucar hora de muerte (`tampered_time`) y limpiador nocturno (`forensic_hire_cleaner`) | ✅ | VillageForensics.gd, VillageManager.gd | Test #82 (Tanda 1.1–1.5) |
| PC2 | Tanda 2 (6–10) | Crímenes por imitación (`copycats`), confesión falsa forzada con chantaje (`forensic_force_confession`), patriarca/matriarca del clan (`patriarch_of`), sabotajes nocturnos entre clanes (`_daily_clan_sabotage`) e interceptar cartas de amantes (`love_letters`) + disputa de hermanastros asignando `FAMILY_MEMBER` | ✅ | VillageForensics.gd, VillageClans.gd, VillageLineage.gd | Test #82 (Tanda 2.6–2.10) |
| PC3 | Tanda 3 (11–15) | Bodas concertadas con dote (`arranged_marriages`), padrinos de bautizo (`godparents`), enseñar un oficio a un niño (`mentored_kids`), jóvenes que se escapan al mirador (`send_lovers_to_mirador`) y disfrazarse con el hábito del cura en el confesionario (`faith_impersonate_priest`) | ✅ | VillageLineage.gd, VillageConfession.gd | Test #82 (Tanda 3.11–3.15) |
| PC4 | Tanda 4 (16–20) | Fingir un milagro en el altar (`faith_stage_miracle`), debates públicos entre candidatos (`town_debate`), indultar acusados y repudiados (`town_pardon`), decreto de «Tributo de paz» (`peace_tax`, `apply_peace_tax`) y fiestas en casa (`housing_party`) | ✅ | VillageConfession.gd, VillageMayor.gd, VillageSocialLife.gd, VillageHousing.gd | Test #82 (Tanda 4.16–4.20) |
| PC5 | Tanda 5 (21–25) | Defender tu puerta de intrusos nocturnos (`intruder_attempt`, `housing_repel_intruder`), revender casas según atractivo y mejoras (`house_sale_price`, `housing_sell_house`), sótano secreto (`hidden_cellar`, `housing_hide_cellar`), hogar de leña (`hearth`, `rest_by_hearth`) y caravana de contrabando de medianoche (`caravan_gold`, `underworld_caravan_*`) | ✅ | VillageHousing.gd, VillageUnderworld.gd | Test #82 (Tanda 5.21–5.25) |
| PC6 | Tanda 6 (26–29) | Timbas clandestinas de dados (`play_dice_bet`, `underworld_dice_bet`), red de carteristas (`pickpockets`, `run_pickpocket_network`), falsificar escrituras municipales (`forged_deed`, `underworld_forge_deed`) y retar cara a cara al jefe de la «Red de las Sombras» (`underworld_challenge_boss`) | ✅ | VillageUnderworld.gd, VillageHousing.gd | Test #82 (Tanda 6.26–6.29) |

## Bloque PD — Revisión de PC (Claude Code, 2026-11-04)

| # | Paso | Estado | Archivos |
|---|------|--------|----------|
| PD1 | `copycats` guarda `imitated_victim` (antes faltaba y el desmontaje fallaba); intruso usaba `n.personality`, que no existe (error diario) → `TraitCatalog.npc_tendency` | ✅ | VillageForensics.gd, VillageHousing.gd |
| PD2 | Cartas: se encuentran con `lineage_search_pocket` (ofrecido a todo adulto, 1/día, con testigos). Pólizas: consulta siempre visible, 10 de oro, y pólizas inocentes (`innocent`) como pista falsa | ✅ | VillageLineage.gd, VillageForensics.gd |
| PD3 | Venta de casa salda `loan.owed` con `VillageLoans._credit`, exige casa vacía y muda al comprador; escritura falsa ya no crea 40 en arcas; carteristas con `catch_chance` 15 % y tope 3; sótano 1/semana; quitada la lejía a distancia | ✅ | VillageHousing.gd, VillageUnderworld.gd, VillageForensics.gd |
| PD4 | Debate y reto al jefe con tirada (reto 1/semana, debate por `elections`); patriarca 1/semana; mentor 10 de oro; indulto recupera `family_name` de su clan; intruso solo con él y roba del escondite si no lo enfrentas | ✅ | VillageMayor.gd, VillageUnderworld.gd, VillageClans.gd, VillageLineage.gd, VillageHousing.gd |
| PD5 | Escritura falsa con 30 % de riesgo de ser descubierta (pierdes el papel falso y sube la búsqueda +1); caravana de contrabando acampa solo de noche cada 3 días con lotes limitados (`is_caravan_here`, `caravan_batches_left`) | ✅ | VillageHousing.gd, VillageUnderworld.gd, verify_all.gd |

## Bloque PF — Fama de los vecinos y Maestros Artesanos con estilo propio (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PF1 | Puntuación individual de fama/infamia (`-100..100`, `🌟 Célebre`, `✨ Conocido`, `😠 Mal visto`, `🌑 Infame`) conectada a maestría, peleas, robos descubiertos, infidelidades, asesinatos resueltos, alcaldía y mercado | ✅ | VillageFame.gd, VillageSocialLife.gd, VillageSecrets.gd, VillageCrime.gd, VillageClans.gd, VillageCulture.gd | Test #83 |
| PF2 | Maestros Artesanos con estilo propio por oficio (`STYLE_BY_ROLE`, `promote_to_master`) y tendencias `fame`, `craft` y `trade` activadas en `TraitCatalog.gd`; elaboran Obras Maestras firmadas (`masterwork_piece`) que ricos y nobles compran con oro de su bolsillo | ✅ | VillageFame.gd, TraitCatalog.gd, SimpleInventory.gd, VillageManager.gd | Test #83 |
| PF3 | Opciones del jugador: comprar Obra Maestra en el taller (`fame_buy_masterwork`), patrocinar el taller de un artesano (`fame_patronize`), vender o regalar Obra Maestra a coleccionistas (`fame_sell_masterwork`, `fame_gift_masterwork`) y hablar bien o mal de un vecino con tirada de riesgo y espera de 3 días (`fame_praise`, `fame_tarnish`); visible en glosario `[J]` y opiniones | ✅ | VillageFame.gd, NPCDialogue.gd, SocialGlossaryUI.gd, verify_all.gd | Test #83 |

## Bloque PG — Graduación escolar con ventaja de oficio y Negocio propio del jugador con publicidad (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PG1 | Seguimiento individual de clases recibidas (`pupil_lessons` a las 14:00) y graduación al cumplir 16 años (`grow_up`) con bonificación de dominio de oficio (`school_bonus_days` 1–4 días en `SAVED_INT_METAS`, aplicada en `promote_to_trade`) | ✅ | VillageFamily.gd, VillageNPC.gd | Test #84 |
| PG2 | Fundar tu propio negocio desde cero en un solar construido (`found_player_shop`, `housing_found_shop`, 65 de oro al carpintero), abastecer mostrador con artículos reales de la mochila (`stock_player_shop`), contratar dependiente parado (`housing_hire_clerk`, 4 de oro/día de la caja), publicidad en el pueblo (`advertise_player_shop`, 12 de oro a las arcas) y venta diaria a vecinos con su propio oro | ✅ | VillageHousing.gd, verify_all.gd | Test #84 |

## Bloque PH — Idolatría / obsesión por un personaje y Acompañantes del jugador (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PH1 | Idolatría u obsesión muy rara (`obsessions` en `VillageFame`, `try_spawn_obsession`): seguimiento (`obsession_follow`), regalos anónimos pagados del bolsillo del acosador (`OBSESSION_GIFT_COST`), celos extremos hacia cercanos del ídolo, tanteo diario sin destripes (`fame_probe_obsession`), calmar con Carisma (`fame_calm_obsessed`) o avisar al ídolo con recompensa de su bolsillo (`fame_warn_idol`) | ✅ | VillageFame.gd, verify_all.gd | Test #85 |
| PH2 | Acompañantes del jugador (`companion` en `VillageFame`, `is_companion`, `VillageNPC._process_duties`): invitar por amistad (`>= 55`, `fame_companion_invite`) o contratar como escolta (`15` de oro/día de tu bolsa al suyo, `fame_companion_hire`), respaldo ante otros vecinos con tirada de riesgo (`fame_companion_backup`) y despido (`fame_companion_dismiss`) | ✅ | VillageFame.gd, VillageNPC.gd, verify_all.gd | Test #85 |

## Bloque PI — Animales con etapas de crecimiento y crianza y Carreras / peleas de animales con apuestas (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PI1 | Ciclo de crecimiento de animales (`chick` → `juvenile` → `adult` en `ranch_herd` y `player_animals`), compra de crías (`buy_young_animal`, `housing_buy_chick`), alimentación con grano/pan (`feed_player_animals`, `housing_feed_animals`) y producción de lana/carne al madurar | ✅ | VillageHousing.gd, verify_all.gd | Test #86 |
| PI2 | Carreras de animales (`run_animal_race`, `underworld_animal_race`, 12 de oro contra el bolsillo del vecino, 1/día) y peleas clandestinas de gallos/perros (`run_cockfight`, `underworld_cockfight`, 15 de oro contra el bolsillo del vecino, 1/día, con riesgo de alerta policial), bonificadas por el vigor del animal adulto criado (`best_adult_animal_power`) | ✅ | VillageUnderworld.gd, verify_all.gd | Test #86 |

## Bloque PJ — Amputaciones e implantes / prótesis médicas y Sabotaje lógico de la red eléctrica (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PJ1 | Amputaciones de urgencia por gangrena (`amputate`, `infection >= 65.0`) e implantes de prótesis articuladas (`install_prosthetic`, `illness_prosthetic_self`, `illness_prosthetic_npc`, 25 de oro repartidos entre médico y arreglador + 1 kit de reparación) | ✅ | VillageIllness.gd, verify_all.gd | Test #87 |
| PJ2 | Red eléctrica con circuitos lógicos independientes (`lamps`, `sprinkler`, `all` en `VillageCulture.grid_state`), sabotaje con riesgo de chispazo (`sabotage_grid`, `culture_sabotage_grid`) y reparación por el jugador (`culture_repair_grid`, 1 bobina de cobre, 12 de oro de las arcas) o por el arreglador en su ciclo diario | ✅ | VillageCulture.gd, VillageManager.gd, FarmPlot.gd, NPCDialogue.gd, verify_all.gd | Test #87 |





