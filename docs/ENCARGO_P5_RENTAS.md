# Encargo P5 — Rentas, «protección», tributo del hampa y desfalcos en su sitio (borrador listo)

> Escrito por Claude Code (supervisor), 2026-11-06. Decisiones de diseño **ya tomadas por el usuario**: no cambies
> ninguna. Si algo no encaja con el código, **no improvises**: apúntalo en el informe y pregunta.
> Fila 9 de `docs/AUDITORIA_REALISMO.md`.

## Reglas de este bloque (orden del usuario)

- Lee solo lo necesario: este encargo, `CLAUDE.md` y las funciones que se nombran aquí.
- **No pases pruebas mientras trabajas.** Al cerrar: arranque sin errores y **una sola** prueba (`verify_all` con
  `timeout 900`). Nada de tipos de clase del juego en las variables del test.
- No toques nada fuera de este encargo. Si ves otra cosa rota, apúntala en el informe.

## Cómo está ahora (los sábados, `get_weekday() == 5`, a medianoche)
- `VillageHousing.daily`: el 15 % de la caja (`shop_businesses[rol]["vault_gold"]`) de cada local tuyo
  (`commercial_deeds`) salta solo a tu mochila (`inv.add_gold(cut)`).
- `VillageUnderworld.daily`: la «protección» (`rackets`, `RACKET_WEEKLY` por local, con `_charge_shop`) y, si eres el
  jefe del hampa, el tributo del perista (`BOSS_TRIBUTE`, de `get_fence_npc(vm).personal_gold`) saltan solos a tu mochila.
- `VillageMayor`: `town_player_embezzle` (desviar `EMBEZZLE_AMOUNT` de las arcas) y `town_cook_books` (maquillar las
  cuentas) se hacen en la charla con cualquiera.

## Idea común: **el dinero se aparta el sábado y tú vas a recogerlo** (decisión del usuario: se acumula con límite)
- El sábado a medianoche **ya no se mueve oro a tu mochila**. En su lugar, cada deuda se **aparta** donde está:
  guarda en el estado una lista `pending_collections` con entradas `{tipo, rol o clave, cantidad, desde_día}`.
  El oro **sigue siendo del que paga** hasta que lo recoges (no lo restes todavía): al recoger, se cobra con la misma
  regla de ahora (`_charge_shop` o la caja del local), y si ya no tiene, cobras lo que haya (puede ser 0).
- **Límite (decisión del usuario):**
  - **Rentas de tus locales:** se acumulan hasta **3 semanas**. La renta de una semana con más de 21 días se borra
    («el artesano lo gastó»); crónica: «%s se gastó la renta que no fuiste a cobrar».
  - **«Protección»:** si **faltas 2 sábados seguidos** sin cobrarla a un local, ese local deja de pagar: se borra de
    `rackets`, el dueño pierde el miedo (`add_thought("El forastero ya no viene a cobrar; ya no le temo (+4)", 4.0)`) y
    lo apunta la crónica.
  - **Tributo del hampa:** se acumula hasta 3 semanas, igual que las rentas.

## 1. Cobrar la renta y la «protección» en el propio local
- Junto al **puesto de trabajo del artesano** (`npc.work_position` del dueño del local, el de `vm.trade_npcs[rol]`)
  pon un `Area2D` del grupo `interactable` (puede ser invisible; el letrero basta) que solo aparece si ese local te debe
  algo. Letreros:
  - Renta: **«Cobrar la renta del local (X de oro)»**.
  - Protección: **«Cobrar la "protección" (X de oro)»**.
- **El dueño tiene que estar en su local** (a menos de 60 px de su `work_position`) y despierto para pagarte. Si no
  está: letrero «El dueño no está; vuelve cuando abra».
- **Protección delante de un guardia:** al cobrarla, si hay un guardia despierto que te vea a menos de 160 px
  (`vm._find_conscious_witness_near(pos, 160, null)` que sea de la guardia), cobras igual pero **sube la búsqueda**
  (`vm.wanted_level = clampi(int(vm.wanted_level) + 1, 1, 5)`) y la crónica lo apunta. La renta es legal: sin riesgo.
- Cobrar no es gastar: **sin doble E**.
- Quita el cobro automático de los sábados de `VillageHousing.daily` y de `VillageUnderworld.daily` (líneas ~876–884 y
  ~810–829). La opción de charla «👊🏪 Exigir 10 de oro cada sábado…» **sigue en la charla** (es una amenaza a una
  persona); su primer cobro en el acto también se queda como está.

## 2. Tributo del hampa: lo recoges del perista
- Si eres el jefe del hampa, el tributo apartado lo recoges **hablando con el perista en su sitio** (detrás de la
  taberna, donde ya está su diálogo): opción «Recoger tu tributo (X de oro)». Es un trato con una persona, por eso va en
  la charla, **pero solo aparece si el perista está a menos de 60 px de su puesto** (no si te lo cruzas por la calle).

## 3. Desfalco y libro de cuentas en el ayuntamiento (decisión del usuario)
- Las arcas ya son un cofre físico: `vm._spawn_house_chest(sp["coffers"], "Arcas del Pueblo", "town_hall")` en
  `VillageCivic` (posición `hall_spots()["coffers"]`). Ese cofre ya se puede **robar** (`VillageCivic.rob_coffers`).
- **Siendo alcalde** (`VillageMayor.is_player_mayor(vm)`), al pulsar [E] en ese cofre sale además **«Desviar %d de oro
  a tu bolsillo»** (`EMBEZZLE_AMOUNT`): hace lo mismo que `town_player_embezzle` (incluido el 45 % de
  `player_embezzle_risk`).
- **Testigo:** si un vecino despierto te ve a menos de 160 px (`_find_conscious_witness_near(pos, 160, null)`), además
  de lo anterior: **escándalo**: `player_embezzle_risk += 2`, la crónica dice «%s vio al alcalde sacar oro de las
  arcas» y ese vecino lo cuenta como chisme (usa el sistema de chismes que ya exista para sucesos vistos; si no sabes
  cuál, dilo en el informe).
- **Libro de cuentas:** nuevo objeto con [E] en la mesa del ayuntamiento (`hall_spots()["desk"]`), visible en 2D y
  3D (un libro abierto sobre la mesa), solo usable siendo alcalde: **«Maquillar el libro de cuentas (−%d oro o Carisma
  2)»** con la misma lógica de `town_cook_books`; si pagas oro, **doble E**. El oro va a quien va ahora
  (`npc.personal_gold`: en el mundo no hay `npc`, así que usa `vm.pay_into` al vecino con más fama de contable o, si
  no lo hay, al escribano/secretario del ayuntamiento; **si no existe ninguno, dilo en el informe** y que vaya a las
  arcas).
- Quita `town_player_embezzle` y `town_cook_books` de la charla (`VillageMayor.add_dialogue_choices`, ~líneas 380–383).

## Prueba (una sola, en `verify_all`): bloque «P5 rentas»
1. Un sábado con un local tuyo: a medianoche **no** sube tu oro; queda una entrada pendiente.
2. Cobrar en el local con el dueño presente: tu oro sube y el del local baja lo mismo (suma cero).
3. Una renta con más de 21 días se borra.
4. Siendo alcalde, desviar oro en el cofre del ayuntamiento con un testigo al lado sube `player_embezzle_risk` en 2 o más.

## Al cerrar el bloque
Lo mismo que en `ENCARGO_ANTIGRAVITY.md` §3 (HANDOFF, CHANGELOG, registro, bóveda y diario), y además:
1. `docs/INFORME_ANTIGRAVITY.md`: **reescríbelo entero**. **Nombra solo funciones que existan**.
2. Commit en español y push a `main`. No subas la carpeta `.claude/`.
