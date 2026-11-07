---
tipo: "sistema"
area: "social"
estado: "implementado"
codigo: "P1"
tags:
  - "social"
  - "crimen"
  - "clanes"
  - "linaje"
fuente: "Biblia §7.1"
---
# Clanes Familiares

> Sección original: *Clanes Familiares y Feudos de Sangre (`P1 Clans`)*

Cada apellido con varios miembros vivos conforma un **Clan Familiar** con memoria colectiva:
- **Herencia de Odios y Feudos de Sangre (`P1.1–P1.2`):** Si matan, encarcelan o arruinan a un miembro del clan, todos sus parientes heredan rencor hacia el agresor y su familia. Dos clanes enfrentados entran en **Feudo de Sangre**.
- **Boicot Comercial (`P1.3`):** Durante un feudo activo, las tiendas de un clan se niegan a vender o cobran recargo a los miembros del clan rival.
- **Romances Prohibidos — «Romeo y Julieta» (`P1.4`):** Dos jóvenes de clanes enemigos que se enamoran se citan a escondidas de noche en el **Mirador del Lago**; si los descubren, estalla el escándalo o el jugador puede ayudarles a reconciliar a sus familias.
- **Huérfanos Vengadores (`P1.5`):** Un niño cuyo padre o madre fue asesinado guarda el nombre del culpable y, al cumplir **16 años**, despierta con el deseo de vengar su sangre.
- **Cenas de Paz, Ovejas Negras y Deudas de Honor (`P1.6–P1.8`):** El jugador o el patriarca pueden organizar una **cena de reconciliación** (con riesgo de que fracase si la tensión es excesiva), **desheredar a la oveja negra** que deshonra el apellido o contraer una **deuda de honor vitalicia** con quien salvó la vida de un pariente.
- **Testamentos Disputados, Tumbas Profanadas y Sabotajes (`P1.9–P1.12`):** Disputas entre parientes por el testamento de un rico fallecido, profanación nocturna de panteones rivales en el cementerio, audiencias con el **Patriarca / Matriarca del Clan** (que exige respeto y afinidad reales) y sabotajes nocturnos entre talleres de clanes enemigos.

## Notas de diseño
- 2026-11-06 (Antigravity, Bloque P4): la **cena de paz entre dos familias** (`"peace"`) pasa a celebrarse en persona en la mesa de la posada (`vm._tavern_social_pos`) al día siguiente a las 20:00 (cuesta 25 de oro a la posadera con doble `[E]` o Carisma >= 2). Acuden andando el cabeza (`patriarch_of`) y hasta 2 adultos libres más de cada familia en feudo (hasta 6 en total) y se sientan durante 2 h. Si falta toda una familia, sale en la crónica «La familia X no se presentó»; si asisten ambas y estás a `< 90 px` al acabar, se tira probabilidad de bronca (`0.10 + 0.25 * agresividad_media + min(0.20, 0.02 * días_feudo)`): si sale bien se sella la paz (`mediate_clan_peace`), y si sale mal acaba a gritos (`-5` de relación entre ambas familias, sin pelea física ni paz).
- 2026-11-07 (Antigravity, Bloque B5): cuando dos vecinos que se odian (`<= -50`) o cuyas familias están en **Feudo de Sangre** se cruzan a menos de `80 px` en la calle (`_try_street_contempt_encounter`), sueltan un **bocadillo corto de 1,5 s** de desprecio sin pausar el juego y se apartan unos pasos el uno del otro.
