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
| A8 | Sonda de crecimiento (30 días) | ⏳ | growth_probe.gd | En segundo plano |

## Bloque B — Cabos sueltos del plan (V3 familias, V9 oficio y juego, escuela)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| B1 | Cartel de la escuela: «Abierta · maestro · N alumnos» / «Esperando alumnos» | 🟡 | VillageCulture.gd (`school_sign` en meta de vm), VillageFamily.update_school | |
| B2 | Llegan familias con 1–2 hijos (2–12 años), casados | 🟡 | VillageMigration (tipo «familia», peso 0,1), VillageFamily.spawn_child / marry | Solo si hay casa con 2 camas; los niños no ocupan cama |
| B3 | Al hacerse mayor, si su madre o padre lleva un negocio sin ayudante, se queda de ayudante (`FAMILY_MEMBER`) y lo heredará | 🟡 | VillageFamily.grow_up | Si no, sigue como antes (sin oficio) |
| B4 | Los nobles ya no aparecen como «llegó al valle» en los sucesos | 🟡 | VillageNobility.spawn_households | |
| B5 | Los niños salen a jugar entre semana de 14 a 20 h (+0,15 de ganas) y se ve «🧒 Jugando en…» | 🟡 | VillagePlaces.is_leisure_hour(hour, n) | |

## Bloque C — Guardado de lo nuevo y equilibrio del crecimiento

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| C1 | **Fallo real**: al cargar partida, nobles (`NPC_Noble_`) y niños (`NPC_Child_`) se perdían porque GameManager solo recupera ciertos prefijos | 🟡 | GameManager.gd (dos listas de prefijos) | Test #74 guarda y carga con un niño y los nobles |
| C2 | Test #73 de los cabos sueltos del bloque B | 🟡 | verify_all.gd | |
| C3 | Sonda: 30 días era demasiado (≈4 min reales por día de juego); relanzada con 12 días | ⏳ | growth_probe.gd | Primeros datos (intento 1): de 18 a 28 vecinos en 3 días, casi todos por tiendas vacantes; escasez de comida desde el día 3 (atractivo −0,4) |
| C4 | **Fallo mío en V3**: el atractivo leía `village_food_shortage_days` (un total que nunca baja) como «hay hambre ahora» → −0,4 para siempre tras la primera comida fallida. Ahora cuenta las comidas fallidas del último día frente a la población (−0,4 si fallan el 15 % o más) | 🟡 | VillageMigration.attractiveness (`food_seen` en migration_state) | La sonda en marcha usa aún la versión vieja |
| C5 | **Fallo de diseño en V9**: los niños tienen 0 de oro y, con la despensa vacía, no podían comer. Ahora reciben cada día 6 de oro (hasta tener 15) del adulto más rico de su familia, o de las arcas si no hay nadie | 🟡 | VillageFamily.give_allowances | |
| C6 | Historia personal propia para niños, nobles y maestro (antes decían «Llegué al valle…») | 🟡 | VillageNPC._resolve_unique_64_visuals_and_lore | Textos provisionales (APORTES) |

### Resultados de la sonda (intento 2, 12 días, semilla 11; versión anterior al arreglo de la comida)
- Población 18 → 29 en 12 días; 27 de esas llegadas cubren tiendas vacantes y 2 son de V3. El freno es la vivienda (1 casa terminada el día 10) y, del día 7 al 12, el falso «hambre» (C4).
- Con todos los solares libres construidos se llega a **45** (faltan solares para 50).
- Rendimiento con 45: plaza 6,35 ms/fotograma de media (lejos 3,67 ms); una hora de juego 2,16 ms. **Un tirón de 270 ms en la plaza** sin explicar todavía.

## Bloque D — Llegar a 50 y el tirón

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| D1 | Dos solares más (n6 en 1070,−420 y m6 en 1070,−580; calle norte y calleja alargadas) | 🟡 | VillageLots.gd, test #69 | 11 solares de casa → 22 camas |
| D2 | La sonda apunta cuándo ocurre el peor fotograma (tiempo real) y cuántos pasan de 33 ms | 🟡 | growth_probe.gd | |
