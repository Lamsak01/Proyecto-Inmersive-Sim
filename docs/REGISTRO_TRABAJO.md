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

## Bloque PK — Sembrar árboles que influyan en el ecosistema y Rutas de comercio con otros lugares (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PK1 | Sembrar pinos jóvenes en el bosque (`plant_sapling`, `count_live_trees`, `plant_forest_tree`, `culture_plant_tree`, `culture_buy_sapling`) que añaden árboles reales, rebrotan hierbas/setas, atraen venados y conejos y enriquecen la fertilidad del suelo (`soil_fertility`) | ✅ | EcosystemManager.gd, VillageCulture.gd, verify_all.gd | Test #88 |
| PK2 | Rutas de comercio con otros asentamientos (`trade_routes_of`, `open_trade_route`, `process_trade_routes`, `send_player_shipment`, `culture_open_route`, `culture_ship_route`) con pago de arancel a las arcas, intercambio diario de mercancías entre gremios y envío de remesas del jugador | ✅ | VillageCulture.gd, verify_all.gd | Test #88 |

## Bloque PL — Árbol de investigación tecnológica e Incursiones organizadas contra el pueblo (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PL1 | Árbol de investigación con el ingeniero (`TECH_TREE`, `start_research`, `advance_research`, `culture_start_tech`, `culture_boost_tech`) con prerrequisitos, consumo de lecturas de la biblioteca o chatarra y bonificaciones permanentes al valle | ✅ | VillageCulture.gd, verify_all.gd | Test #89 |
| PL2 | Incursiones organizadas contra el pueblo (`raids_state`, `start_raid_warning`, `defense_power`, `resolve_raid`, `culture_fund_militia`, `culture_lead_defense`) con financiación de milicia, defensa encabezada por el jugador con recompensa de las arcas y saqueo si cae la defensa | ✅ | VillageCulture.gd, verify_all.gd | Test #89 |

## Bloque PM — Expediciones de exploración y Caballos / Carretas de carga en el rancho (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PM1 | Caballo de silla (`has_horse`, `culture_buy_horse`, 45 de oro al ganadero, +15 % en expediciones) y Carreta de carga (`has_cart`, `culture_buy_cart`, 55 de oro al ganadero, +4 de oro por remesa comercial) | ✅ | VillageCulture.gd, verify_all.gd | Test #90 |
| PM2 | Expediciones de exploración (`EXPLORATION_SITES`, `run_expedition`, `culture_expedition`, 12 de oro en víveres, 1/día, con tirada de riesgo) que aportan reliquias y +2 lecturas a la biblioteca | ✅ | VillageCulture.gd, verify_all.gd | Test #90 |

## Bloque PN — Niveles verticales por capas (`elevation_level`) y Alcantarillas con localizaciones subterráneas (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PN1 | Sistema de niveles verticales por capas (`elevation_level` `-1/0/+1`, `are_on_same_elevation`, `distance_on_same_level`, testigos filtrados por nivel en `_find_conscious_witness_near`, mejora `"upper_floor"` y `housing_change_level:*`) | ✅ | VillageNPC.gd, VillageManager.gd, VillageHousing.gd, verify_all.gd | Test #91 |
| PN2 | Red de alcantarillas bajo el pueblo en el nivel `-1` (`SEWER_LOCATIONS`: Cisterna, Pasadizo del Contrabandista y Bóveda Inundada, `unlock_sewers`, `explore_sewer_location` 1/día con tirada de riesgo y `lost_coins_pool` nutrido de bolsillos reales) | ✅ | VillageUnderworld.gd, verify_all.gd | Test #91 |

## Bloque PO — Armas de fuego de chispa y Terminales lógicas / Hackeo electromecánico (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PO1 | Armas de fuego (`flintlock_pistol`, `powder_charge`, `buy_firearm`, `buy_powder_pack`, `has_loaded_firearm`, `fire_flintlock_shot`, +3 defensa en incursiones y disparo con consumo de pólvora y alerta sonora) | ✅ | SimpleInventory.gd, VillageCulture.gd, verify_all.gd | Test #92 |
| PO2 | Terminales lógicas electromecánicas y hackeo (`terminal_state`, `hack_terminal`, `culture_hack_terminal:*` en `census_ledger`, `warrant_archive` y `grid_controller`, 1/día con tirada de riesgo y alarma voltaica si falla) | ✅ | VillageCulture.gd, verify_all.gd | Test #92 |

## Bloque PP — Crear tu propio asentamiento fronterizo e Historia Principal en 4 capítulos (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PP1 | Crear y gobernar el asentamiento fronterizo «Puesto del Paso» (`found_outpost`, `recruit_outpost_settler`, `upgrade_outpost`, `process_outpost_daily`, `collect_outpost_treasury`) con colonos, aserradero/granero/atalaya y arca propia | ✅ | VillageCulture.gd, verify_all.gd | Test #93 |
| PP2 | Historia Principal en 4 capítulos («I. Las Raíces del Valle» → «IV. La Placa de Petri») conectada a la pestaña «👑 Principal» del panel de misiones `[L]` (`MAIN_STORY_CHAPTERS`, `sync_main_story`) | ✅ | VillageCulture.gd, QuestManager.gd, verify_all.gd | Test #93 |

## Bloque PQ — Escalado de población a 100+ vecinos, solares norte (`u0..u6`), casas de 4 camas con altillo y LOD multi-nivel (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PQ1 | Techo de población `POP_CAP = 100`, 7 nuevos solares residenciales en la ronda norte (`u0..u6`) y ampliación de casas a 4 camas mediante altillo (`expand_house_upper_floor`, `_house_beds(id, true)`) | ✅ | VillageMigration.gd, VillageLots.gd, VillageHousing.gd, verify_all.gd | Test #94 |
| PQ2 | Simulación simplificada multi-nivel (`_lod_far`, `_lod_step_for_npc`) para vecinos en otro piso/subsuelo o a gran distancia | ✅ | VillageNPC.gd, verify_all.gd | Test #94 |

## Revisión PF–PQ — Cuatro fallos graves (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| RV1 | Cambiar de piso solo en casa; volver a la calle al salir; alcantarillas de ida y vuelta | ✅ | VillageManager.gd, VillageHousing.gd, VillageUnderworld.gd | Test #91 |
| RV2 | Arcabuz con daño real; sin disparo desde el diálogo | ✅ | VillageCulture.gd | Test #92 |
| RV3 | Capítulo IV por alcaldía (`is_player_mayor`) | ✅ | VillageCulture.gd | Test #93 |
| RV4 | Espera semanal compartida para borrar la búsqueda | ✅ | VillageHousing.gd, VillageUnderworld.gd, VillageCulture.gd | Tests #91 y #92 |

## Revisión PF–PQ — Atajos de dinero (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| RE1 | Bazar con precios por artículo, sin stock gratis y con robos nocturnos de la caja | ✅ | VillageHousing.gd | Test #84 |
| RE2 | Corral que necesita comida (sin comer no crece, a los 5 días muere) | ✅ | VillageHousing.gd | Test #86 |
| RE3 | Pinos 1/día, tope 12, sin semilla extra y repuestos al cargar | ✅ | VillageCulture.gd, EcosystemManager.gd | Test #88 |
| RE4 | Obra maestra revendida por menos de su precio | ✅ | VillageFame.gd | Test #83 |
| RE5 | Red: no se cobra el sabotaje propio, no hay luz sin generador, testigos | ✅ | VillageCulture.gd | Test #87 |
| RE6 | Milicia con tope, incursiones crecientes y atalaya permanente; terminal solo en el taller | ✅ | VillageCulture.gd | Test #89 |

## Revisión PF–PQ — Textos y veracidad (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| RT1 | El caballo acelera de verdad al jugador (también al cargar) | ✅ | PlayerMovementController.gd, VillageCulture.gd | Test #90 |
| RT2 | Ánimo correcto al perder un miembro y al recibir una prótesis | ✅ | VillageIllness.gd | — |
| RT3 | Cambiar de oficio empieza de cero; ventaja escolar solo en el primero | ✅ | VillageNPC.gd | Test #84 |
| RT4 | Asentamiento documentado como solo de menús; lore apuntado como provisional | ✅ | CHANGELOG.md, VISION_Y_FUTURO.md, APORTES_CREATIVOS.md | — |

## Medición PF–PQ — 30 días sin jugador (`tools/tests/feature_probe.gd -- 30 11`, 2026-11-04, 1770 s reales)

Lo que ocurre solo:
- 4 maestros artesanos, pero con las existencias llenas: nadie les compra. Además el título sale «Maestro Maestro».
- 1 obsesión.
- 4 incursiones en 30 días y las 4 perdidas (−30 de oro cada una). La amenaza solo crece con el paso del tiempo.
- El rebaño del rancho llega a adulto el día 6 y después ya no cambia.
- 9 vecinos con fama.

Lo que no ocurre nunca sin el jugador:
- investigación, rutas, pinos, bazar, alcantarillas, terminal y animales propios;
- graduación (no hubo clases que contar);
- amputaciones.

Otros datos: tesoro final de 1086 y población de 18 a 35.

## Asaltos con motivo (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| RA1 | La amenaza sube por motivos (arcas llenas, rutas, asentamiento) y baja si el pueblo es pobre o está bien defendido | ✅ | VillageCulture.gd | Test #89 |
| RA2 | Aviso con el motivo; reunión de defensores a las 16 h en el camino del este; asalto a las 18 h | ✅ | VillageCulture.gd, VillageNeeds.gd | Test #89 |
| RA3 | Vecinos valientes defienden junto a la guardia; heridas a los defensores si se pierde | ✅ | VillageCulture.gd | Test #89 |
| RA4 | Error de la capilla al comprar una bula (malestar de la secta tratado como lista) | ✅ | VillageConfession.gd | Test P4.bula |

## Bloque PR — Vida autónoma del pueblo, gasto municipal de arcas y Auditoría Completa del Proyecto (2026-11-04)

Informe completo de la auditoría: `docs/AUDITORIA_PROYECTO_COMPLETA.md`.

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| PR1 | Título de Maestro sin duplicar (`«Maestro Maestro»` → `«Maestro Herrero»`) y ventas reales de Obras Maestras a vecinos solventes (antes de fabricar, sin reponer el mismo día) y en el mercado de los miércoles | ✅ | VillageFame.gd, VillageCulture.gd, verify_all.gd | Test #95 y sonda (`stock=[0, 1, 1, 0]`) |
| PR2 | Renovación del rebaño del rancho (`ranch_herd`): al cumplir 9 días (`ADULT_ANIMAL_DAYS + 3`), el ganadero vende el animal maduro al carnicero (`8` de oro reales de su bolsillo + carne y lana) y repone una cría (`"chick"`, crónica `animal_bred`) | ✅ | VillageHousing.gd, verify_all.gd | Test #95 y sonda (`animal_bred=4`, `["adult", "adult", "chick", "chick"]`) |
| PR3 | Escuela activa sin intervención del jugador: `MIN_PUPILS_FOR_TEACHER = 1`, familias recién llegadas pueden alojarse en camas libres de la posada (`free_tavern_beds_count`), prioridad a `"familia"` cuando no hay alumnos, primer hijo con 12–14 años y asistencia guiada entre semana (`10:00–12:00`) sin duplicar a las `14:00` | ✅ | VillageFamily.gd, VillageMigration.gd, verify_all.gd | Tests #84, #95 y sonda (`teacher=1`, `clases_por_alumno={"npc_13_eulalia": 10, "npc_14_beatriz": 11}`) |
| PR4 | Gasto municipal del superávit de las arcas (`process_municipal_spending` cuando `treasury > 350` y subvención parcial de sueldos de autoridades con `treasury >= 250`): invierte en defensa comunal (`militia_trained`), becas tecnológicas del taller (`tech_grant` / `tech_unlocked`) y apertura de rutas comerciales (`trade_route`) | ✅ | VillageCulture.gd, VillageTown.gd, VillageManager.gd, verify_all.gd | Test #95 y sonda (`tesoro=245`, `tech_unlocked=3`, `trade_route=2`, `militia_trained=2`) |
| PR5 | Auditoría completa del proyecto (`docs/AUDITORIA_PROYECTO_COMPLETA.md`): recompensas forenses y del hampa respaldadas por multas/incautaciones del bolsillo del culpable y las arcas municipales, pagos de difamación/cuentas/adopción/deuda transferidos al destinatario, y tirada con posibilidad de fallo en `town_speech` | ✅ | VillageForensics.gd, VillageUnderworld.gd, VillageMayor.gd, VillageLineage.gd, docs/AUDITORIA_PROYECTO_COMPLETA.md | `names_check`, `social_sim`, `dialogue_coverage` y `verify_all` (#95) pasan |

### Medición tras Bloque PR — 16 días sin jugador (`tools/tests/feature_probe.gd -- 16 11`, 2026-11-04, 871 s reales)
- **Maestros Artesanos:** 4 (`«Thoran alcanzó el rango de Maestro Herrero con su propio estilo»`, sin repetir «Maestro»), existencias en movimiento `stock=[0, 1, 1, 0]` (antes `[2, 2, 2, 2]`).
- **Rancho del Sur:** `animal_bred=4`, rebaño en rotación `["adult", "adult", "chick", "chick"]` (antes estancado en 4 adultos desde el día 6).
- **Escuela:** `teacher=1`, `clases_por_alumno={ "npc_13_eulalia": 10, "npc_14_beatriz": 11 }` (antes `{}`).
- **Gasto municipal, tecnología, rutas y defensa:** `tesoro=245` (antes `> 1000`), `tech_grant=3`, `tech_unlocked=3` (`["waterwheel_gears", "reinforced_locks", "voltaic_capacitors"]`), `trade_route=2` (`RUTAS activas=2`), `militia_trained=2` y `0` incursiones sufridas (`amenaza=37`).
- **Población y vida social:** población `18 → 36`, `5` obras construidas, `1` obsesión activa, `30` monedas caídas en alcantarillas, `0` errores.

Para el otro agente: Implementé los 5 puntos de vida autónoma y visibilidad de `docs/NOTA_PARA_OTRO_AGENTE.md` (Bloque PR, test #95 en `verify_all.gd`), verifiqué la mejora con `tools/tests/feature_probe.gd -- 16 11` y completé la auditoría integral del proyecto en `docs/AUDITORIA_PROYECTO_COMPLETA.md` (cerrando además los últimos flecos de oro sin contrapartida en `VillageForensics`, `VillageUnderworld`, `VillageMayor` y `VillageLineage`, y añadiendo tirada con fallo posible a `town_speech`, sin tocar `VillageSect.gd`).

## Transición 3D — Fase 1: Maquetas 3D articuladas de personajes, equipo, prótesis, arcabuz en mano y Visor 3D (2026-11-04)

Copia de seguridad 2D intacta guardada en la rama `backup-2d-original` y etiqueta `v2d-backup-original` (subidas a GitHub).

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| 3D.1 | Muñeco 3D articulado (`CharacterRig3D.gd`) con cabeza, ojos/cejas, cabello/barba, torso, delantal, capa, falda, armaduras por nivel (1–3), extremidades articuladas, prótesis mecánicas de brazo/pierna y catálogo 3D de armas/herramientas/sombreros | ✅ | `scripts/visuals/CharacterRig3D.gd` | Probado en juego por el usuario |
| 3D.2 | Puente de renderizado en vivo (`CharacterAvatar3D.gd`) para `Player` y `VillageNPC` con desactivación fuera de cámara / headless y tecla `[F9]` para alternar en vivo entre 3D y sprites 2D originales sin borrar nada | ✅ | `scripts/visuals/CharacterAvatar3D.gd`, `scripts/Player.gd`, `scripts/enemies/VillageNPC.gd` | Probado en juego por el usuario |
| 3D.3 | Arcabuz de chispa empuñable en combate directo (`[9]`) con consumo de pólvora, proyectil real, fogonazo/humo 3D y alerta sonora a testigos en 260 px | ✅ | `scripts/Player.gd`, `scripts/PlayerCombatController.gd` | Cierra pendiente PO.1; probado en juego |
| 3D.4 | Visor interactivo de Maquetas 3D en primer plano (`[F8]`, `CharacterShowcase3DUI.gd`) con 8 arquetipos del valle, selector de armas/armaduras/prótesis/animaciones y rotación de cámara | ✅ | `scripts/ui/CharacterShowcase3DUI.gd`, `scenes/ui_root.gd` | Probado en juego por el usuario |

## Transición 3D — Fase 2: Escenario 3D del valle, edificios con tejados que se abren al entrar, interiores 3D, alturas `-1/0/+1` y «Puesto del Paso» en el mapa (2026-11-04)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| 3D.5 | Escenario 3D completo del valle (`WorldStage3D.gd`) sincronizado 1:1 con el mapa 2D: caminos de piedra, plaza adoquinada, pozos, bancos, tablón, compostera, Parque del Robledal, Lavadero, Mirador del Lago, Ciénaga del Oeste, Cementerio Parroquial con lápidas dinámicas (`buried_graves`) y solares en obras (`Lots3D`) | ✅ | `scripts/visuals/WorldStage3D.gd`, `scripts/systems/VillageManager.gd`, `scripts/systems/VillageLots.gd` | Tecla `[F9]` alterna en vivo tanto el mundo/edificios 3D como los personajes 3D |
| 3D.6 | Edificios 3D con estilo propio por oficio, puertas 3D abatibles, ventanas con contraventanas y apertura automática de tejados (`RoofCap_*`) al entrar o acercar el ratón, dejando ver el interior 3D (camas, mesas, mostradores, cofres, fragua, camillas de morgue con cuerpos, celda con rejas, capilla, biblioteca y escuela) | ✅ | `scripts/visuals/WorldStage3D.gd`, `scripts/systems/VillageManager.gd` | Conserva todos los muros y suelos 2D originales intactos al desactivar con `[F9]` |
| 3D.7 | Altillos `+1` (`Loft3D_*` con escalera de mano y camas adicionales), cámaras subterráneas `-1` de las alcantarillas (`Sewers3D`: Cisterna, Pasadizo y Bóveda Inundada) y farolas 3D con luz real (`OmniLight3D`) sincronizadas con el reloj y la red eléctrica | ✅ | `scripts/visuals/WorldStage3D.gd` | Cierra el pendiente visual de capas `PN` |
| 3D.8 | Presencia física en el mapa (2D y 3D) para el asentamiento fronterizo «Puesto del Paso» en el lindero este (`Vector2(1615, 50)`) con empalizada, puerta y carta de fundación interactiva (`[E]`), aserradero, granero, atalaya y turnos de trabajo reales (`08:00–17:00`) para los colonos reclutados | ✅ | `scripts/systems/VillageCulture.gd`, `scripts/systems/VillageNeeds.gd`, `scripts/visuals/WorldStage3D.gd` | Cierra el pendiente `PP.1` de presencia física en el mapa |
| 3D.9 | Integración de modelos 3D reales y texturas PBR desde los paquetes descargados por el usuario (`assests/curated_3d/`, con `assests/Assets 3d/` ignorado en `.gdignore` y `.gitignore`): personajes humanos esculpidos y articulados (`Male_Peasant`, `Female_Peasant`, `Male_Ranger`, `Female_Ranger`, cabezas/ojos/cejas esculpidas, peinados y barbas 3D, armas medievales y de fuego 3D en mano) y decoración arquitectónica, mobiliario, árboles, animales, lápidas y farolas 3D reales en `WorldStage3D.gd` | ✅ | `scripts/visuals/AssetLibrary3D.gd`, `scripts/visuals/CharacterRig3D.gd`, `scripts/visuals/WorldStage3D.gd`, `assests/curated_3d/` | 104 modelos y texturas 3D verificados en arranque sin errores |

## Bloque AUD — Auditoría del 2026-11-05 (informe de Antigravity, vía libre del usuario mientras duerme)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| AUD1 | F9 vuelve a cargar partida; 2D/3D pasa a F10 | ✅ | CharacterShowcase3DUI.gd | El informe señalaba ui_root.gd, pero quien se comía F9 era el Visor 3D |
| AUD2 | Farolas saboteadas apagadas de noche (2D, 3D y niebla) | ✅ | WorldStage3D.gd, RetroPostFX.gd, VillageManager.gd | |
| AUD3 | Farol del jugador de 20 a 6 (niebla y mano 3D) | ✅ | Player.gd (`is_carrying_lantern`), CharacterAvatar3D.gd | |
| AUD4 | Arcabuz se guarda y se carga en la mano | ✅ | Player.gd | |
| AUD5 | Sótano propio ≠ alcantarillas | ✅ | VillageUnderworld.gd (`is_player_in_sewers`), VillageHousing.gd, WorldStage3D.gd | Test PN.2f |
| AUD6 | Escritura falsa: aviso de guardias; ya no compra con hipoteca tras pillarte | ✅ | VillageHousing.gd | Precio real en los avisos |
| AUD7 | Puesto del Paso pide doble E | ✅ | VillageCulture.gd | |
| AUD8 | Regla 1 (suma cero): los 22 puntos del informe | ✅ | VillageManager.gd (`pay_into`, `take_from_treasury`, `role_npc`, `_find_paying_customer`, `_take_family_savings`), VillageUnderworld, VillageNeeds, VillageDesires, Player, NPCDialogue, VillageJustice, VillageMayor, VillageClans, VillageHousing, VillageCrime | Test P7 del golpe: el perista sin oro no paga |
| AUD9 | Ingresos de las arcas: alquiler de puestos del mercado y arancel de rutas | ✅ | VillageCulture.gd (`MARKET_STALL_FEE`, `ROUTE_TOWN_TARIFF`, `ROUTE_WEEKLY_REFILL`, `ROUTE_BALANCE_CAP`) | Aprobado por el usuario (ideas 1 y 3). Tests V5e arcas y PK.2b |
| AUD10 | Impuesto sobre la renta semanal por tramos (exento 4/día, 15 % hasta 15/día, 30 % el resto) | ✅ | VillageNPC.gd (`income_week`, `_track_income`, setter de `personal_gold`), VillageTown.gd (`income_tax_for`, `start_income_tracking`) | Pedido por el usuario. 22 días: arcas entre ~385 y ~900. Test I1 renta |
| AUD11 | Caballo físico: aparece, montar/desmontar con E, +45 % solo montado, sin sigilo, bajadas automáticas, guardado | ✅ | PlayerHorse.gd (nuevo), VillageCulture.gd (`sync_player_horse`), Player.gd (`is_mounted`), PlayerMovementController.gd, CharacterAvatar3D.gd, CharacterRig3D.gd (`MOUNTED` → «sit»), AnimalModel3D.gd | Pedido del usuario. Tests PM.1a2–a5. Capturas caballo_esperando/montado |
| AUD12 | Selector de E: letrero, el ratón manda, Mayús+rueda o G cambia de opción | ✅ | scripts/ui/InteractionSelector.gd (nuevo), Player.gd (`interaction_selector`), PlayerHorse.gd (`get_interact_label`) | Pedido del usuario. Test «UX E» |
| AUD13 | Ficha de vecino: una sola (la más cercana al ratón), corta; completa con Alt | ✅ | VillageNPC.gd (`_hover_owner`), InteractionSelector.gd (letrero bajo los pies) | Pedido del usuario |
| AUD14 | Letreros del mapa sin amontonarse (cercanos o bajo el ratón; si se pisan, el más cercano) | ✅ | VillageManager.gd (`_declutter_title_labels`, `_title_text_rect`, grupo `world_title_label`) | Pedido del usuario |

## Bloque FIS — Los 10 sistemas «en papel» hechos físicos (pedido del usuario, 2026-11-05)

Orden acordado: 1 asaltos · 2 terminal, cuadro eléctrico y objetos de los robos · 3 alcantarillas · 4 ganado · 5 el resto.
Ya hechos antes: caballo físico (AUD11). Los 3 robos ya se hacían en persona (falta que se vea el objeto).

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| FIS1 | Asaltos físicos: bandidos o jabalíes reales, pelea con defensores y jugador, resultado por lo que pasa en el mapa | ✅ | Raider.gd, RaidController.gd, BanditModel3D.gd (nuevos), VillageCulture.gd (`spawn_raid_attackers`, `culture_lead_defense` ya no resuelve) | Tests PL.2g/PL.2g2. Captura asalto_bandidos |
| FIS2 | Terminal Lógica física dentro del taller (`(1188, 122)`), cuadro eléctrico en la fachada norte del taller (`(1270, 90)`) y objetos físicos visibles en 2D y 3D para los 3 grandes robos dentro de sus edificios (`sello_noble` en `(1275, -444)`, `caliz_capilla` en `(745, 336)`, `libro_gremial` en `(764, -444)`) | ✅ | WorldInteractableProp.gd (nuevo), VillageCulture.gd, VillageUnderworld.gd, VillageTrades.gd, WorldStage3D.gd, InteractionSelector.gd, screenshot_3d.gd, verify_all.gd | Antigravity. Test #96 (`Block FIS2`). Capturas en `docs/capturas_fis2/` |
| FIS3 | Alcantarillas caminables de verdad: 3 rejillas en la calle (`(518, 26)`, `(398, -118)`, `(248, -90)`), red subterránea de 3 cámaras conectadas con muros `StaticBody2D` en `y = 1520` (`x = 205..635`), 3 escalerillas de salida (permitiendo entrar por una y salir por otra) y 3 cofres de contrabando (1/día por cámara, suma cero de `lost_coins_pool`) | ✅ | WorldInteractableProp.gd, VillageUnderworld.gd, VillageManager.gd, WorldStage3D.gd, InteractionSelector.gd, screenshot_3d.gd, verify_all.gd | Antigravity. Test #97 (`Block FIS3`). Capturas en `docs/capturas_fis3/` |
| FIS3b | Bajar por una rejilla o salir por una escalerilla a la vista de un guardia o del comisario sube +1 la búsqueda (`wanted_level`) con aviso flotante (sin bloquear el paso); si te ve un vecino cualquiera no sube la búsqueda pero queda un chisme (`record_social_event("player_secret", ...)`) y recuerdo (`add_thought`) | ✅ | VillageUnderworld.gd (`_check_sewer_witness`, `_apply_sewer_witness`, `interact_sewer_grate`, `exit_sewer_ladder`), verify_all.gd (`FIS3.8`) | Antigravity. Test `FIS3.8a–FIS3.8f` |
| FIS4 | Ganado vivo en el Rancho del Sur (`ranch_herd` → grupo `"ranch_livestock"`, sin los 4 dibujos fijos) y animales propios de verdad en el corral de `ChickenCoop` (`player_animals` → grupo `"player_livestock"`), alimentación individual con `[E]` (`feed_single_player_animal`) y esquila/recogida en persona cada 2 días (`harvest_player_animal`), modelo `Alpaca.glb` CC0 + gallina 3D procedural (`_build_procedural_chicken`) | ✅ | LivestockAnimal.gd (nuevo), AnimalModel3D.gd, VillageHousing.gd, VillageTrades.gd, VillageManager.gd, ChickenCoop.gd, WorldStage3D.gd, InteractionSelector.gd, Alpaca.glb, screenshot_3d.gd, verify_all.gd | Antigravity. Test #98 (`Block FIS4`). Capturas en `docs/capturas_fis4/` |
| FIS-P1 | Auditoría de realismo (`docs/AUDITORIA_REALISMO.md`, 11 mecánicas ordenadas por prioridad) + Prioridad 1 hecha física: huerto doméstico (`home_garden`), banco de trabajo y alquimia (`home_workbench`), escondite bajo las tablas (`home_stash`) y escalera/trampilla de casa (`home_stairs`) en 2D y 3D con `[E]`, eliminando objetos mágicos a medianoche en `VillageHousing.daily` y atajos de diálogo con carpintero/vecinos/perista | ✅ | docs/AUDITORIA_REALISMO.md (nuevo), WorldInteractableProp.gd, VillageHousing.gd, VillageLots.gd, VillageUnderworld.gd, WorldStage3D.gd, verify_all.gd | Antigravity. Test `Block FIS-P1` |
| COMBATE-1 | Rodar con Espacio (`start_roll`, `50` px en `0,35` s, invulnerable `0,25` s, cuesta energía, bloqueado a caballo), parar con Q (`start_parry`, ventana `0,20` s, enfriamiento `0,50` s, desequilibra al atacante `0,80` s con `apply_parry_stagger`, sin bloquear flechas/disparos y manteniendo prioridad del derribo en sigilo) y aviso de `0,40` s antes de cada golpe cuerpo a cuerpo enemigo en vecinos/guardias, asaltantes, perros hostiles y jabalíes + animaciones 3D `"roll"` (UAL1) y `"block"` (UAL2) | ✅ | PlayerMovementController.gd, PlayerCombatController.gd, Player.gd, DamageData.gd, ArrowProjectile.gd, VillageNPC.gd, Raider.gd, DomesticPet.gd, WildAnimal.gd, CharacterRig3D.gd, CharacterAvatar3D.gd, AnimalModel3D.gd, bake_character_animations.gd, ual_male.res, ual_female.res, ui_root.gd, verify_all.gd | Antigravity. Test `Block COMBATE-1` |
| ANIM-1 | Calibración de velocidad de reproducción de `"walk"` (`28.86` px/ciclo → `21.65` px/s), `"run"` (`52.40` px/ciclo → `56.15` px/s) y `"carry"` (`28.74` px/ciclo → `14.37` px/s) a partir de la velocidad real a escala `STAGE_K = 0.40` en `CharacterRig3D._pick_clip`, y giro de 180° de armas y herramientas en mano (`WeaponHolder` y `l_holder` en `CharacterRig3D._build_real_curated_tools`) para jugador y vecinos | ✅ | CharacterRig3D.gd, CharacterAvatar3D.gd, BanditModel3D.gd, docs/capturas_anim1/ | Antigravity. Capturas `cerca_antes_10h.png` y `cerca_despues_10h.png` |
| P1 | Tienda propia («Bazar del Forastero») hecha física: mostrador y caja 2D/3D (`player_shop_counter`) en `player_shop["lot"]` con `[E]` para reponer mercancía y recoger `till_gold` (quitados del diálogo con vecinos), dependiente que camina tras el mostrador en horario comercial (`player_shop_clerk`, sin dependiente presente no hay ventas) y clientes reales que se acercan andando durante el día (`player_shop_buy`) y pagan de su bolsillo a la caja | ✅ | VillageHousing.gd, WorldInteractableProp.gd, WorldStage3D.gd, VillageNeeds.gd, VillageWork.gd, VillageManager.gd, VillageNPC.gd, verify_all.gd | Antigravity. Test `Block P1` |
| P2 | Carreta de carga física (`PlayerCart.gd`, grupo `player_cart` en `CART_DEFAULT_POS = Vector2(385, 470)` junto al Rancho del Sur, modelo 3D `fantasy_town/cart.glb` y dibujo 2D provisional): arrastre a mano (`×0,55`, sin correr/sigilo/rodar) o enganchada al caballo (`×0,80`, sin sigilo) siguiendo el rastro a 22 px, caja de carga de 40 unidades con ventana de dos columnas, robo nocturno del 12 % fuera de lugar seguro (pasa a `pocket_items` del vecino más pobre, suma cero), bono de +4 en `send_player_shipment` solo con la carreta a < 60 px y arreglo de P1 (`SHOP_STOCK_PER_PRESS = 6`) | ✅ | PlayerCart.gd (nuevo), VillageCulture.gd, VillageHousing.gd, PlayerMovementController.gd, Player.gd, InteractionSelector.gd, verify_all.gd | Antigravity. Test `Block P2` |
| P5b | El perista trasnocha en el callejón de la taberna (22:00–3:00, recado `fence_alley`, `NIGHT_ERRANDS`), con capa y capucha en 3D, letrero «Hablar con la figura encapuchada» y rumores sutiles en la taberna (10 %, 1 al día en el pueblo) | ✅ | VillageUnderworld.gd, VillageNPC.gd, VillageNeeds.gd, VillageManager.gd, InteractionSelector.gd, NPCDialogue.gd, CharacterAvatar3D.gd, verify_all.gd | Claude Code (en paralelo con Antigravity). Test `Block P5b` |
| P5 | Rentas, «protección» y tributo apartados el sábado (`pending_collections`) y recogidos en persona (punto de cobro junto al dueño, tributo de noche con el perista), caducidad de 3 semanas, «protección» perdida tras 2 sábados, desfalco en el cofre de las arcas con testigos y libro de cuentas 2D/3D en la mesa del ayuntamiento | ✅ | VillageCollections.gd (nuevo), WorldInteractableProp.gd, WorldStage3D.gd, VillageHousing.gd, VillageUnderworld.gd, VillageMayor.gd, VillageManager.gd, verify_all.gd | Claude Code (en paralelo con Antigravity). Test `Block P5` |
| P3 | Caravanas comerciales físicas (`VillageCulture.gd`: `CaravanMule`, `CaravanMuleArea`, `spawn_trade_caravan`, `caravans_on_hour`, llegada semanal con 30 % de retraso +1 día, estancia 10:00–16:00 en `CARAVAN_PLAZA_POS = Vector2(465, 48)`, intercambio al llegar y envío de remesa con `[E]` en la mula; embargo de 7 días si matan al caravanero) y campamento nocturno físico de contrabando (`VillageUnderworld.gd`: `SmugglerCampCart`, `SmugglerTradeArea`, `spawn_smuggler_caravan` de 22:00 a 4:00 en `SMUGGLER_CAMP_POS = Vector2(1350, -560)`, compra con doble `E` y venta en el carro, testigo policial a `< 160 px` y redada a pie de 2 guardias con `smuggler_bust`) | ✅ | AnimalModel3D.gd, VillageCulture.gd, VillageUnderworld.gd, VillageManager.gd, VillageJustice.gd, VillageNeeds.gd, VillageNPC.gd, NPCDialogue.gd, verify_all.gd | Antigravity. Test `Block P3` |
| P6a | Club de pelea en un sótano de verdad (trampilla tras la taberna, sala a nivel −1 en 2D/3D, 23–3 noches pares, público de vecinos pendencieros, pelea a puño limpio no letal con rendición al 20 %, pelea de vecinos a medianoche con apuestas, guardia que ve la trampilla) | ✅ | VillageClub.gd (nuevo), WorldInteractableProp.gd, WorldStage3D.gd, VillageNPC.gd, VillageNeeds.gd, VillageManager.gd, VillageUnderworld.gd, verify_all.gd | Claude Code. Test `Block P6a` |
| P6b | Sabotajes, robos por encargo, sabotajes entre clanes y profanaciones hechos por un vecino que camina de verdad a la 1:00 (20 min en el sitio), pillables por guardias o por el jugador, con confesión si lo pagaste tú | ✅ | VillageNightJobs.gd (nuevo), VillageUnderworld.gd, VillageClans.gd, VillageNPC.gd, VillageNeeds.gd, VillageManager.gd, InteractionSelector.gd, verify_all.gd | Claude Code. Test `Block P6b` |
| P4 | Cenas con vecinos (`"dinner"`, 20:00), fiestas en casa (`"party"`, 21:00, convocadas en `home_table` e invitando uno a uno hasta 6 vecinos) y cenas de paz entre familias en la posada (`"peace"`, mañana a las 20:00, con doble `E`, cabeza + hasta 2 adultos por familia y tirada de bronca `prob = 0.10 + 0.25 * avg_agg + min(0.20, 0.02 * feud_days)`) hechas físicas con mesa 2D/3D (`home_table`), 6 asientos a `14 px` (`set_poker_seating`), comida en la mesa (`table_rations` desde la mochila o cáterin de la posadera 1 h antes por `4` oro/invitado con doble `E` y reembolso si no llega), duración de 2 h, charla cada 20 min y requisito de jugador a `< 90 px` | ✅ | VillageHousing.gd, VillageClans.gd, VillageNeeds.gd, VillageNPC.gd, VillageUnderworld.gd, WorldInteractableProp.gd, WorldStage3D.gd, verify_all.gd | Antigravity. Test `Block P4` |
| A1 | Obras Maestras compradas en el mostrador del taller con el maestro presente (doble E), fuera de la charla | ✅ | VillageFame.gd, WorldInteractableProp.gd, VillageManager.gd, verify_all.gd | Claude Code. Test `Block A1` |
| A2-CONTROLES | Pantalla de ayuda de controles al empezar partida nueva (`controls_panel` en `scenes/ui_root.gd`, dos columnas «Lo básico» y «Más» sin emojis, pausa del reloj con `WorldClock.set_activity_pause`, cierre con `Esc`, `Intro` o clic izquierdo, y botón «Controles» en el pie de `inv_panel` al estar `H` ocupada por `medical_panel`) | ✅ | scenes/ui_root.gd, tools/tests/verify_all.gd | Antigravity. Test `Block A2` |





