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
| Terceros espacios (V5c) | «Parque del Roble», los bancos de la plaza y el «Mirador del Lago» |
| Afueras (V5d) | «Granja del Sur» y sus «Campos de la Granja», «Rancho del Sur», «Cantera del Noroeste», «Cabaña del Leñador» y el «Lavadero» del lago; familias «Casa de la Granja / del Rancho / de la Cantera / del Leñador». Objeto nuevo: «Lana» |
| Cultura y oficios (V5e) | «Biblioteca», «Escuela» («Esperando alumnos»), «Mercado del Miércoles», «Taller de Reparaciones» y el oficio de «Arreglador» («Casa del Arreglador») |
| Nobles (V6) | «Señor del Valle», «Señora del Valle», «Heredero del Valle», «Mansión del Señor del Valle» («Casa del Señor»), «Casa Grande de los Rentistas»; renta del 10 % los lunes |
| Hijos (V9) | Historias: niño «Nací aquí, en el valle…», noble «Mi familia lleva generaciones cobrando las rentas…», maestro «Alguien tiene que enseñar…»; «Criatura del valle», «Hijo/Hija del valle», «Joven del valle», «Maestro/Maestra de la Escuela»; un año cada 4 días; dibujos de adulto encogidos |
| Solares (V3+) | «Calleja de atrás» (fila m), «Casa del pueblo», «Casa de <nombre>» |
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

Hay 25 tipos de misión secundaria, que nacen de lo que pasa en el pueblo. Sus títulos y textos son provisionales (los 20 últimos los inventó Claude a petición del usuario, 2026-11-03):

| Misión | De qué va |
|---|---|
| Haz las paces por mí | Mediar entre dos vecinos enemistados. |
| Ensúciale el nombre | Hablar mal del rival de alguien. |
| Averigua qué piensa de mí | Saber si alguien gusta de quien te lo pide. |
| Encuentra a quien lo mató | Resolver un asesinato. |
| ¿Quién va contando eso de mí? | Seguir un rumor hasta su origen. |
| ¿Me engaña X? | Averiguar si la pareja de alguien le es infiel. |
| Que no me quiten la casa | Salvar de un desahucio a quien no paga su préstamo. |
| El jabalí del claro | Cazar un jabalí que asusta al carnicero. |
| Votos para X | Comprar votos para un candidato sin escrúpulos (o destaparlo). |
| Las cuentas de X | Reunir testigos del robo del alcalde. |
| Medicina para X | Pagar el médico a un pobre enfermo. |
| Fe que tambalea | Traer al Oficio a un vecino que ya no va. |
| El aprendiz | Colocar a un joven parado en un taller. |
| Sabotaje por encargo | Romper el puesto de un rival (o denunciarlo). |
| El testigo con miedo | Conseguir protección a quien halló un cadáver. |
| Ollas vacías | Reunir donativos para las gachas del Albergue. |
| ¿Me corresponde? | Llevar una carta de amor (o leerla, o romperla). |
| La herencia de X | Mediar entre un heredero y un pariente sin nada. |
| La última copa | Apartar a alguien de la bebida o los dados. |
| El puesto del miércoles | Ayudar a un artesano a montar puesto en el mercado. |
| Lo que se lee de noche | Descubrir las reuniones nocturnas (la secta). |
| Pelea anunciada | Calmar a dos enemigos antes de que lleguen a las manos. |
| Sin techo | Buscar sitio a un desahuciado. |
| El forastero raro | Conocer a un recién llegado y defenderlo o echarlo. |
| La tumba sin nombre | Reabrir por tu cuenta un asesinato archivado. |

También hay un objetivo de prueba, «Eliminate Frogs» (ranas de la ciénaga).

La **historia principal** no existe: el panel L tiene la pestaña preparada y vacía.

**Dónde:** `scripts/systems/quests/types/` (un archivo por misión) y `docs/MISIONES.md` (desde 2026-11-03 Claude puede
inventar tipos placeholder, por tandas aprobadas).

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

## 12. Textos y nombres provisionales de los Bloques P1–P7

**Qué hay:**
- **Decretos del alcalde (P5):** «Ley seca» (`dry_law`), «Toque de queda» (`curfew`) y «Subvención al mercado» (`market_subsidy`).
- **Sustancia prohibida y herramientas ilegales (P7):** «Polvo de ocaso» (`dusk_dust`), «Veneno lento» (`slow_poison`), «Somnífero» (`sleeping_draught`) y «Papeles falsos» (`false_papers`).
- **Objetivos de robo por encargo del perista (P7):** «el Cáliz de Plata del Señor» (`lord_goblet`), «el Libro Secreto del Ayuntamiento» (`ledger_gold`) y «el Relicario Dorado de la Capilla» (`chapel_relic`).
- **Términos de la Capilla (P4):** «Bula de indulgencia», «Secreto de confesión», «Sermón con indirectas» y «Derecho de santuario».

**Dónde:** `scripts/systems/VillageMayor.gd`, `scripts/systems/VillageUnderworld.gd`, `scripts/systems/VillageConfession.gd`, `scripts/systems/VillageClans.gd`, `scripts/systems/VillageForensics.gd`, `scripts/systems/VillageLineage.gd` y `scripts/systems/VillageHousing.gd`.
**Depende:** solo textos de diálogo y crónicas; los identificadores internos (`dry_law`, `curfew`, `dusk_dust`, etc.) no deben renombrarse sin actualizar las referencias.

## 13. Textos y nombres provisionales de los Bloques PF–PQ

**Qué hay:**
- **Historia principal (PP):** cuatro capítulos «I. Las Raíces del Valle», «II. El Pulso Bajo la Piedra», «III. La Máquina de Cobre» y «IV. La Placa de Petri». Introducen una idea de trasfondo **inventada por el agente, no por el usuario**: que el valle fue concebido como un experimento cerrado y que bajo la plaza hay restos de una red antigua de cobre. Conviene que el usuario la confirme o la cambie.
- **Asentamiento (PP):** «Puesto del Paso», con «Aserradero Fronterizo», «Granero del Paso» y «Atalaya de Guardia».
- **Incursiones (PL):** «Banda del Paso Negro», «Manada de Jabalíes Furiosos» y «Saqueadores del Norte».
- **Alcantarillas (PN):** «Cisterna Vieja bajo la Plaza», «Pasadizo del Contrabandista» y «Bóveda Inundada del Antiguo Gremio».
- **Expediciones (PM):** «Ruinas de Cobre del Oeste», «Grutas de Cristal del Norte» y «Atalaya Hundida del Pantano».
- **Rutas comerciales (PK):** «Paso Alto (Minas del Norte)», «Puerto Fluvial del Este» y «Vega del Sol».
- **Tecnologías (PL):** «Engranajes Hidráulicos», «Cerraduras y Empalizadas de Precisión» y «Condensadores Voltaicos».
- **Maestros artesanos (PF):** tres estilos por oficio («Acero Templado al Alba», «Masa Madre Dorada»…), el bazar «Bazar del Forastero» y la «Obra Maestra con Sello de Autor».

**Dónde:** `scripts/systems/VillageCulture.gd` (historia, asentamiento, incursiones, expediciones, rutas, tecnologías), `scripts/systems/VillageUnderworld.gd` (alcantarillas), `scripts/systems/VillageFame.gd` (estilos) y `scripts/systems/VillageHousing.gd` (bazar).
**Depende:** solo textos; los identificadores internos (`main_ch1`, `high_pass`, `waterwheel_gears`…) no deben renombrarse sin actualizar las referencias.

## Rumores del perista en la taberna (P5b, provisionales)
- «Anoche volvía tarde y olía a pipa detrás de la taberna. ¿Quién fuma ahí a esas horas?»
- «Yo, de noche, no paso por el callejón. Manías mías.»
- «Hay quien paga por lo que no tiene dueño. No me preguntes quién, que no lo sé.»
- «Lo que se pierde en este pueblo no se pierde: cambia de manos antes del alba.»
- «Si oyes una puerta trasera pasada la medianoche, mejor no mires.»

**Dónde:** `scripts/systems/VillageUnderworld.gd` (`FENCE_RUMORS`). Texto «Hablar con la figura encapuchada» en `alley_interact_label`.

## Club de pelea del sótano (P6a, provisionales)
- Ánimos del público: «¡Dale!», «¡Arriba esa guardia!», «¡Al suelo con él!», «¡Eso es, eso es!», «¡No te quedes quieto!», «¡Uuuh!».
- Rendición: «¡Basta, basta! Me rindo.» / «¡Ya vale! Me rindo.»; reto: «¡Vamos allá, forastero!».

**Dónde:** `scripts/systems/VillageClub.gd` (`CHEERS` y textos de `_end_bout` / `start_player_bout`).

## Frases de charla en la mesa durante cenas, fiestas y cenas de paz (P4, provisionales)
- «¡A vuestra salud!»
- «Esta comida huele de maravilla.»
- «Se está bien aquí al calor de la mesa.»
- «Pásame el pan, por favor.»
- «Hacía falta sentarse a charlar un rato.»
- «Brindemos por una noche tranquila en el valle.»

**Dónde:** `scripts/systems/VillageHousing.gd` (`GATHERING_CHAT_PHRASES`).
**Depende:** solo textos flotantes cada 20 minutos de juego durante la reunión.

## Nombres de las dos prótesis (provisional)
- «Prótesis sencilla de madera y correas» (50 %) · «Prótesis articulada de hierro y cuero» (75 %).

**Dónde:** `scripts/systems/VillageIllness.gd` (`PROSTHETIC_QUALITIES`).
**Depende:** solo el nombre que sale en el hospital, la crónica y el pensamiento del vecino.

## Frase del médico al amputar al jugador (A4, provisional)
- «He cortado a tiempo. Perdiste el %s, pero seguirás con vida.»

**Dónde:** `scripts/systems/VillageIllness.gd` (`on_player_action`, rama `"illness_amputate_self"`).
**Depende:** solo texto flotante tras amputar el miembro gangrenado del jugador.

## Texto del «Léeme» de la beta (B6, provisional)
- Presentación del juego («Llegas como forastero a un pueblo de un valle…»), controles y qué esperar.

**Dónde:** `LEEME_BETA.txt` (se copia como `LEEME.txt` junto al .exe).
**Depende:** solo el texto que leen los amigos antes de jugar; nada del juego.

## Frases del herrero y avisos de armas (C7 fase 4, provisional)
- «Afilar y enderezar tus armas», «Listo: filo nuevo y el mango bien prieto», «Son N de oro. La piedra de afilar no gira sola»,
  «Tus armas están bien…»; avisos «Tu espada se ha mellado: pega menos…», «¡Se le cae el arma!», heridas «(por la espalda)».

**Dónde:** `scripts/systems/combat/WeaponWear.gd`, `VillageNPC.disarm`, `HealthComponent` (nombre de la herida).
**Depende:** solo los textos; los números (precio, desgaste) están en `WeaponWear.gd`.

## Trattoria «Il Corvo» (R1, provisional)
- Nombre «🍝 Trattoria 'Il Corvo'», familia «Corvo», oficio «Cocinero»; platos «Tallarines de la Casa» y «Carne Estofada al Vino»;
  frase del cocinero «…la mesa del fondo está reservada: no pregunte para quién.»

**Dónde:** `scripts/systems/VillageRestaurant.gd`, `SimpleInventory.CATALOG`, `NPCDialogue.gd` (rama del cocinero).
**Depende:** solo los textos; la Familia (R2) usará el reservado, no el nombre.

## Pistas del cocinero y rumores de «La Familia» (R2, provisionales)
- Opción de diálogo con el cocinero: «🍷 Preguntar por el reservado del fondo» (`familia_cook_ask`).
- Respuestas del cocinero (`cook_line` / `COOK_LINE_MEETING`, `COOK_LINE_ACTIVE`, `COOK_LINE_QUIET`):
  - En plena reunión nocturna: ««Chist... baje la voz. Esta noche hay gente cenando a puerta cerrada en el reservado del fondo. Yo llevo las fuentes, dejo el vino y miro al suelo. En esta cocina el que no pregunta llega a viejo.»»
  - Cuando «La Familia» ya existe: ««¿La mesa del reservado? Hay clientes que prefieren cenar tarde con la puerta cerrada y sin que nadie apunte sus nombres. Pagan al contado, no arman ruido y yo no pregunto de qué hablan.»»
  - Antes de que nazca «La Familia»: ««El reservado del fondo está tranquilo últimamente. Sólo se abre cuando alguien quiere hablar de negocios lejos de los curiosos.»»
- Rumor de quien rechaza entrar (`familia_rumor`): «%s tanteó en voz baja a %s para meterlo en negocios turbios en el reservado», y pensamientos/notas de relación al aceptar o negarse.
- Frases y rumores de los negocios discretos (R3, provisionales): «🤝 «Así todos trabajamos tranquilos.»», «🪙 «Esta noche haré la ronda por el otro lado.»», «%s cuenta que %s pasó por su negocio pidiendo una comisión por «evitar disgustos»» y «%s cuenta que %s intentó untarle con unas monedas para que mirase a otro lado».
- Personaje inicial del jefe mafioso y textos de intervención del jugador (R4, provisionales): nombre «Don Vittorio Corvo» (`npc_familia_boss`, familia «Corvo», 46 años, rasgos `Sediento de poder`, `Manipulador`, `Líder`, `Codicioso`, `Astuto`, `Rencoroso`), frase de escucha en el reservado («👂 Oyes voces bajas en el reservado…») y líneas de diálogo al avisar a la víctima (`familia_warn_target`), delatar ante el Comisario (`familia_report_confirm` / `familia_report_sheriff`) o trabajar cobrando la comisión (`familia_ask_work`, `familia_player_extort`, `familia_deliver_cut`).

**Dónde:** `scripts/systems/VillageFamilia.gd` (`spawn_initial_boss`, `cook_line`, `try_eavesdrop_meeting`, `add_dialogue_choices`, `on_player_action`, `player_collect_protection`, `try_recruit`, `finish_meeting`, `resolve_protection`, `give_loan`, `collect_loan`, `try_bribe_guard`).
**Depende:** solo los textos de diálogo, pensamientos, rumor y el nombre de «Don Vittorio Corvo»; la lógica usa claves internas (`"familia"`, `"familia_meet"`, `"familia_errand"`, `"familia_rumor"`).

## Bocadillos de reacción al ruido de combate (B1, provisionales)
- Guardia que oye el golpe o disparo: «🛡️👂 ¡¿Qué ha sido ese ruido?!».
- Vecino curioso o valiente que se asoma: «👀 ¿Qué pasa ahí?».
- Vecino pacífico o asustadizo que se aparta: «😨 ¡Socorro, pelea!».

**Dónde:** `scripts/enemies/VillageNPC.gd` (`on_noise_heard`, `get_activity_description`).
**Depende:** solo los textos flotantes; la lógica usa `_noise_react_mode` (`"guard_investigate"`, `"civilian_peek"`, `"civilian_flee"`).

## Frases del calabozo, fianza y fuga entre barrotes (B2, provisionales)
- Aviso de detención: «🚔⛓️ ¡Detenido! Al calabozo por …».
- Charla entre rejas (`jail_talk`): ««Aquí me tienes, contando los barrotes por … (me quedan X h de encierro). Si tienes mano con la guardia o unas ganzúas a mano, no me vendría mal salir de esta humedad.»».
- Fianza en comisaría (`jail_bail_menu` / `pay_npc_bail`): «⚖️ «Fianza pagada (+X Oro a las arcas). Queda en libertad.»» y agradecimiento del preso («🤝 «¡Te debo una! Pensaba que iba a dormir en ese jergón húmedo.»»).
- Fuga forzando la reja (`help_npc_escape`): «🗝️⛓️ ¡Cerradura forzada! Te debo la vida, me largo antes de que miren.» y alerta si mira un guardia («🚨👮 «¡Alto! ¡Está abriendo la celda!»»).

**Dónde:** `scripts/systems/VillageJustice.gd` (`arrest_npc`, `release_npc`, `pay_npc_bail`, `help_npc_escape`, `add_dialogue_choices`).
**Depende:** solo los textos; la lógica usa `town_state["jail_inmates"]` y las acciones `"jail_pay_bail:"` y `"jail_escape_npc"`.

## Opciones de traslado de Toby y del gallinero a tu casa (B3, provisionales)
- En conversación con el carpintero o en la mesa de casa: «🐕🥣 Trasladar a Toby y su comedero al patio de tu casa en el solar X» y «🐔🐑 Trasladar tu gallinero y animales al solar de tu casa (X)».
- En la mesa de obras del campamento: «[5] 🏡🐕 Trasladar a Toby y tus animales/gallinero a tu casa del pueblo».

**Dónde:** `scripts/systems/VillageHousing.gd` (`move_toby_to_lot`, `move_coop_to_lot`, `add_dialogue_choices`, `open_home_table_menu`), `scripts/obstacles/CampSite.gd` (`_setup_upgrade_ui`, `_on_move_to_village_house_pressed`).
**Depende:** solo los textos; la lógica usa `toby_lot` y `coop_lot` en `town_state["housing"]`.

## Textos de actividad de paseos nocturnos y sonambulismo (B4, provisionales)
- Paseos nocturnos (`night_stroll`): «🌙🚶 Paseando de noche por las calles».
- Sonambulismo (`sleepwalk`): «😴🚶 Caminando dormido por la calle (Sonámbulo)» y bocadillo ocasional «😴💤 «Zzz...»».

**Dónde:** `scripts/enemies/VillageNPC.gd` (`get_activity_description`), `scripts/systems/VillageNeeds.gd` (`tick`).
**Depende:** solo los textos flotantes y de estado; la lógica usa `errand_kind` (`"night_stroll"`, `"sleepwalk"`).

## Bocadillos cortos de calle: desprecio, merodeo, pregones y fila escolar (B5, provisionales)
- Cruce de enemigos o feudos de sangre (`CONTEMPT_BUBBLES`, `FEUD_BUBBLES`): «😒 «Ni me mires.»», «💢 «Apártate de mi vista.»», «😠 «Por la otra acera.»», «🩸💢 «Tu apellido apesta aquí.»», «⚔️😠 «Ni agua a los tuyos.»».
- Merodeo nocturno previo a un crimen (`prowl_victim`): «🗡️👀 «Pronto pagará...»».
- Pregones de Maestros, decretos e inauguraciones: «🏅 «¡Maestro del gremio!»», «✨ «¡Obra maestra terminada!»», «📜 «¡Nuevo edicto: X!»» y «🎉 «¡Estrenamos X!»».
- Fila escolar a las 9:00: «📚🛎️ ¡En fila a la escuela!» y «🎒 ¡Ya vamos a clase!».

**Dónde:** `scripts/systems/VillageSocialLife.gd` (`_try_street_contempt_encounter`), `scripts/systems/VillageNeeds.gd` (`tick`), `scripts/systems/VillageFame.gd`, `scripts/systems/VillageMayor.gd`, `scripts/systems/VillageFamily.gd`.
**Depende:** solo los textos cortos de 1,5 s (`spawn_short_bubble`).

## Secretos propios, rasgos 4–6 y variantes de los 21 vecinos fundadores (B6, provisionales)
- **3 secretos por cada uno de los 21 fundadores (+ Valeria)** en `NPCData.FOUNDER_SECRETS_POOL` (p. ej. hojas sin sello de Thoran, veta de plata de Kael, jabalí blanco de Garrick, llave de plomo de Marlo, diario cifrado de Elena, caja bajo el altar de Anselmo, informe lacrado de Vane, etc.), de los cuales se eligen 2 o 3 por partida en `npc.founder_secrets`.
- **Rasgos 4–6 y `trait_variants`** en `NPCData.INITIAL_PERSON_PROFILES` y variaciones de relación en `NPCData.FOUNDER_RELATION_VARIANTS`.

**Dónde:** `scripts/data/NPCData.gd` (`INITIAL_PERSON_PROFILES`, `INITIAL_NPC_RELATIONS`, `FOUNDER_RELATION_VARIANTS`, `FOUNDER_SECRETS_POOL`), `scripts/systems/VillageSecrets.gd` (`seed_founder_history`), `GameVault/04_Censo_y_Misiones/Vecinos/*.md`.
**Depende:** solo los textos de `FOUNDER_SECRETS_POOL` y las listas de rasgos/relaciones en `NPCData.gd`.

## Cintillo y avisos de la prueba de primera persona (B7, provisionales)
- Cintillo superior en `WorldStage3D.fp_mode_badge`: «👁️ 1.ª Persona (Prototipo) · [F6]/[F8] Salir · Ratón/Flechas: mirar · W/A/S/D: andar · [E]: usar».
- Avisos al activar/desactivar (`set_first_person`): «👁️ [F6/F8] Vista en 1.ª Persona ACTIVADA (Ratón: mirar · W/A/S/D: caminar · [E]: usar)» y «🎥 [F6/F8] Vista superior 2.5D restaurada».

**Dónde:** `scripts/visuals/WorldStage3D.gd` (`_setup_fp_hud_layer`, `set_first_person`), `scripts/ui/CharacterShowcase3DUI.gd`.
**Depende:** solo textos de interfaz.





