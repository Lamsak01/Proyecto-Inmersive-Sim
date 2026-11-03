# Aportes creativos provisionales

Todo lo de este documento es **provisional** (placeholder). Lo inventó la IA porque el usuario delegó la parte creativa
mientras se construyen los sistemas. Ninguna de estas piezas es definitiva: el usuario las revisará y las rehará en
persona cuando el desarrollo esté más avanzado.

Cómo leerlo: cada tema dice **qué hay**, **dónde está** (por si hay que cambiarlo) y **qué depende de ello**. Cambiar un
nombre o un texto es fácil. Cambiar una idea (por ejemplo, la religión) puede tocar mecánicas: está indicado en cada caso.

Regla para el futuro: cada vez que se añada lore, nombres, historias o misiones, se apuntan aquí.

---

## 1. El mundo y su historia

**Qué hay:** un valle fronterizo y pobre, alejado de una capital con nobles y una Corona que manda desde lejos. Hay
restos de una tecnología antigua bajo tierra (bobinas, conductos) y ruinas tomadas por bandidos. El tono es de pueblo
pequeño, con gente que huyó de algo.

| Nombre | Qué es |
|---|---|
| La Corona / la capital | El poder lejano. Paga los sueldos de las autoridades y manda al inquisidor. |
| Tierras Reales (al norte) | Las tierras de la Corona. Allí cazar está prohibido sin permiso. |
| Salvoconducto Real | El permiso de los mercaderes para cruzar la frontera. |
| Liga Minera del Norte | El gremio para el que trabaja el mercader Casimir. |
| Vaelgard, Fundición Imperial | El pasado de Thoran. |
| Cima Quebrada | El motín donde Vane perdió un ojo y donde coincidió con Thoran. |
| Paso del Aullido | La expedición de tramperos de la que solo sobrevivió Garrick. |
| Peñanegra | La cantera de Darío. |
| Colegio Botánico de Ámbar | La antigua cátedra de Elena. |
| El Gran Teatro (capital) | El derrumbe que mandó a Bram al exilio. |
| «La Estrella Hundida» | El barco contrabandista de Marlo. |
| Río Grande, Puerto Real | El pasado de Sora como tahúr. |
| Estepas de sal, Llanura Oeste | De donde vienen Lina y Rodric. |
| Tecnología antigua bajo el valle | La obsesión de Kael. Encaja con la idea de tecnología anacrónica de VISION. |

**Dónde:** casi todo está en los textos de lore de cada vecino, en `scripts/data/NPCData.gd` (`NPC_LORE_PROFILES`).
**Depende:** nada mecánico. Solo cambian los textos.

## 2. El pueblo y sus lugares

| Lugar | Nombre provisional |
|---|---|
| Posada, taberna y casino | «El Jabalí Dorado» |
| Herrería y armería | «Yunque Gris» |
| Carnicería y peletería | «El Colmillo» |
| Carpintería y aserradero | «Roble Viejo» |
| Pescadería y molino | «Aguas Claras» |
| Botica y casa-jardín | «Raíz Verde» |
| Capilla y cementerio | Capilla del Alba y Cementerio Parroquial del Alba |
| Otros | Hospital y Morgue Forense, Comisaría y Cárcel del Valle, Plaza con pozo y tablón |
| Afueras | Llanura Salvaje del Oeste, Ciénaga de las Ranas, Bosque Profundo, Ruinas de los Bandidos |
| Panadería (V5) | «La Espiga»; la familia que la lleve, «Casa de la Espiga» |
| Sastrería (V5) | «El Dedal»; «Casa del Dedal». Objeto nuevo: «Ropa de Lana» |
| Ayuntamiento (V5b) | «Ayuntamiento del Valle», con la urna y el cofre «Arcas del Pueblo» |
| Albergue (V5b) | «Albergue del Alba», de la capilla |
| Segunda posada (V5b) | «El Candil», posada humilde; la familia, «Casa del Candil» |
| Solares nuevos (V4) | Calle norte, camino del este, campos del sur, ladera del noroeste y las lomas del este y del norte (sitios para mansiones). Carteles «📜 Solar libre» y «🚧 En obra». Las casas nuevas se llaman de momento «🏠 Casa nueva» |

Las familias toman el nombre de su negocio: Yunque Gris, Colmillo, Roble Viejo, Aguas Claras.

**Dónde:** `scripts/systems/VillageWorldBuilder.gd` (carteles), `scripts/ui/ValleyMapUI.gd` (mapa) y
`scripts/systems/VillageManager.gd` (textos de interacción).
**Depende:** solo textos. Los apellidos de las familias se usan en los bandos (son solo el nombre).

## 3. Los personajes

Cada vecino tiene nombre, edad, tres rasgos, gustos, un pasado (una frase) y un texto largo que cuenta si le preguntas.

| Personaje | Oficio | Pasado en una línea |
|---|---|---|
| Thoran (52) | Herrero | Maestro armero que desertó por no forjar grilletes. |
| Kael (22) | Aprendiz de forja | Obsesionado con la tecnología antigua de las ruinas. |
| Garrick (38) | Carnicero y cazador | Único superviviente del Paso del Aullido. |
| Lina (34) | Curtidora | Cartógrafa de caravanas, hermana de Garrick. |
| Bram (41) | Carpintero | Arquitecto exiliado tras el derrumbe del Gran Teatro. |
| Mila (33) | Ebanista y cerrajera | Vendió sus herramientas para pagar la fianza de Bram. |
| Marlo (54) | Pescador y molinero | Antiguo timonel contrabandista. |
| Nora (23) | Redera | Lleva un registro secreto del pueblo en nudos de cuerda. |
| Elena (36) | Botánica | Huyó cuando quisieron convertir sus remedios en venenos. Pareja de Valen. |
| Tomás (39) | Agricultor | Hizo fértil la tierra ácida del valle. |
| Marta (44) | Posadera | Ganó la posada en una partida de póker. |
| Dr. Valen (40) | Médico | Expulsado de la capital por hacer autopsias prohibidas. |
| Hermano Anselmo (61) | Sacerdote del Alba | Llegó con un carro de libros y se quedó a cuidar de los muertos. |
| Comisario Vane (55) | Comisario | Veterano tuerto, aplica la ley con pragmatismo. |
| Guardia Rodric (24) | Guardia | Los bandidos arrasaron su granja. |
| Aldric (35) | Sin oficio, buscavidas | Ex batidor militar y buscador de reliquias. Manipulador: posible fundador de una secta (pedido por el usuario). |
| Sora (28) | Sin oficio, tahúr | Desplumó a un magistrado y se escondió aquí. |
| Darío (42) | Sin oficio | Capataz despedido por salvar a sus mineros. |
| Maese Casimir (48) | Mercader de visita semanal | Intendente de la Liga Minera. |
| Valeria la Tratante (37) | Mercader de visita semanal | Compra pieles y carne para las Tierras Reales. |
| Inquisidor Real Alistair (51) | Juez de la Corona | Solo aparece si matas a un mercader real. |

**Relaciones iniciales:** 29 parejas de amistades y rivalidades con su motivo (por ejemplo, «Garrick y Marlo: rivalidad
entre carnicería y pescadería»).

**Dónde:** `scripts/data/NPCData.gd`: perfiles (`INITIAL_PERSON_PROFILES`), lore (`NPC_LORE_PROFILES`), relaciones
(`INITIAL_NPC_RELATIONS`) y nombres antiguos (`NPC_NAME_ALIASES`).
**Depende:** los rasgos y las relaciones iniciales sí cambian cómo se comporta el pueblo. Los textos y los nombres, no.
Los oficios están atados a los edificios.

**Nombres para vecinos nuevos:** 200 nombres de mujer, 200 de hombre y 200 apellidos de estilo variado (latino,
europeo y americano), en `scripts/data/NPCNames.gd`. Hay un test que comprueba que no se repiten (`names_check`).

## 4. La religión: la Fe del Alba

**Qué hay:**
- Un dios creador, **el Hacedor**, que encendió el primer Alba y puso una chispa de luz en cada criatura.
- El **Libro del Alba** pide tres cosas: compartir el pan, perdonar a quien se arrepiente y no derramar sangre inocente.
- Su símbolo es el **círculo del sol naciente** (☀️).
- Su rito es el **Oficio del Alba**, el domingo por la mañana en la capilla.
- Grados de fe: fervoroso, creyente, tibio y escéptico.
- Frases de los vecinos sobre si van al Oficio, y las del sacerdote al donar o al burlarte.

**Dónde:** `scripts/systems/VillageFaith.gd` (`FAITH_NAME`, `RITE_NAME`, `LORE_TEXT` y frases del diálogo).
**Depende:** el nombre y los textos se cambian sin problema. La mecánica (asistir, sermón, roces entre creyentes y
escépticos) no depende del contenido de la fe. Una religión con otro día de culto exige cambiar
`WorldClock.is_rite_day()`.

## 5. Las sectas: los Hijos del Ocaso y el Círculo de la Luna Velada

**Qué hay:**
- Lo contrario del Alba: creen que antes del Hacedor estaba **la Noche** y que volverá.
- Su símbolo es un **sol negro**, que pintan en la capilla cuando la profanan.
- Se reúnen **los viernes de madrugada en el cementerio**.
- Rangos: Iniciado, Hermano de la Sombra y Mano del Ocaso.
- Lo más oscuro es un **rito de sangre**: muy raro, con una víctima engañada para que acuda a la reunión y una
  «daga ceremonial».
- Frases de invitación, de chantaje y de denuncia.

Hay una segunda clase de secta, para cuando nace entre ricos aburridos: **el Círculo de la Luna Velada**. Promete
«saberes antiguos» y «placeres que el Libro prohíbe», solo admite gente de su posición y se reúne de noche en casa del
líder.

**Dónde:** `scripts/systems/VillageSect.gd` (`NAMES`, `NAMES_CAP`, `SECT_SIGN`, `RANK_NAMES`, `LORE` y frases del diálogo).
**Depende:** nombre, símbolo, rangos y textos se cambian sin tocar nada más. El lugar y la hora de la reunión están en
`meeting_base` y `meeting_hours`; el día lo elige el líder. La idea de que sea «lo contrario del Alba» solo está en los textos. VISION apunta la
secta como posible gancho de la historia principal.

## 6. Instituciones

**Qué hay:**
- Un **alcalde** elegido cada 28 días e impuestos los sábados.
- La **Corona** paga a la policía, al médico y al sacerdote.
- Un **inquisidor real** con juicio público si matas a un mercader.
- Frases del alcalde, del comisario corrupto y de los sobornos.

**Dónde:** `scripts/systems/VillageTown.gd`, `scripts/systems/VillageJustice.gd`.
**Depende:** que los sueldos vengan de la Corona es una decisión de economía, no solo de lore. Cambiarlo afecta al dinero
del pueblo. Los **nobles** se dejaron para el paso 9.

## 7. Enfermedades, vicios y oficios inventados

- **Enfermedades:** el **Resfriado** y la **Fiebre gris**, que solo mata muy rara vez sin médico. Ya existía la
  **fiebre de la ciénaga**, por el miasma. Están en `scripts/systems/VillageIllness.gd`.
- **Vicios y frases:** bebida y juego en la taberna, limosna, rondas de bebida y frases de mendigos y ladrones. Están
  en `scripts/systems/VillageNeeds.gd` y `scripts/systems/VillageCrime.gd`.
- **Oficios y talleres:** las recetas de cada oficio («🪚 Aserrando», «Bobina Cobre»...) están en
  `scripts/enemies/VillageNPC.gd`. Hay objetos de nombre inventado, como la «ración real». Están en el catálogo de
  `scripts/systems/SimpleInventory.gd`.

## 8. Misiones

Hay 5 tipos de misión secundaria, que nacen de lo que pasa en el pueblo. Sus títulos y textos son provisionales:

| Misión | De qué va |
|---|---|
| Haz las paces por mí | Mediar entre dos vecinos enemistados. |
| Ensúciale el nombre | Hablar mal del rival de alguien. |
| Averigua qué piensa de mí | Saber si alguien gusta de quien te lo pide. |
| Encuentra a quien lo mató | Resolver un asesinato. |
| ¿Quién va contando eso de mí? | Seguir un rumor hasta su origen. |

También hay un objetivo de prueba, «Eliminate Frogs» (ranas de la ciénaga).

La **historia principal** no existe: el panel L tiene la pestaña preparada y vacía.

**Dónde:** `scripts/systems/quests/types/` (un archivo por misión) y `docs/MISIONES.md` (la regla del usuario: no
inventar tipos nuevos sin su aprobación).

## 9. Personalidad: los 140 rasgos

**Qué hay:**
- 140 rasgos (118 en 51 pares o grupos de opuestos, 22 sueltos y 17 raros) con nombre, descripción corta y opuestos (Honrado/Mentiroso, Fanático/Escéptico...).
- Frases con las que los vecinos los comentan («rumores de rasgos»).

**Dónde:** `scripts/data/TraitCatalog.gd` y `docs/RASGOS_BORRADOR.md`.
**Depende:** a diferencia del lore, **los rasgos son mecánica**. Cada uno mueve tendencias (honradez, fe, malicia...)
que usan casi todos los sistemas. Se pueden renombrar o reescribir las descripciones sin riesgo. Cambiar lo que hace
cada uno cambia el comportamiento del pueblo.

## 10. Textos de la vida social

- Las frases de las charlas entre vecinos: piropos, bromas, roces, disculpas, coqueteos...
- Los textos flotantes («💬», «🕯️ No te olvido...»).
- La forma en que la crónica cuenta los sucesos.

**Dónde:** `scripts/data/SocialDialogueData.gd`, `scripts/enemies/VillageNPC.gd` y
`scripts/systems/VillageChronicle.gd`.
**Depende:** solo textos.

## 11. Nombre del juego

**«La Placa de Petri»**: pueblo como experimento donde todo se cultiva solo. No consta si el nombre lo eligió el usuario
o vino ya dado. Conviene confirmarlo.
