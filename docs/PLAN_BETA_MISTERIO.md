# Plan de la primera beta: «El misterio del valle» (borrador para retocar)

> Claude Code, 2026-11-06. Decidido por el usuario: hilo de misterio, con final y resumen, 1–2 horas, Windows.
> El usuario quiere retocar la forma de partida más adelante: **esto es una base, no está cerrado.**

## 1. Cómo es una partida (propuesta)

1. **Llegada (minutos 0–10):** llegas al campamento del oeste. Una ayuda breve presenta 8 teclas y te propone hablar
   con dos o tres vecinos. Esa noche (o al día siguiente) **aparece un vecino muerto**.
2. **El caso (minutos 10–90):** el culpable se elige **al azar cada partida** entre los vecinos con un motivo real
   (deseos de venganza, celos, deudas, secretos). Investigas: examinar el cuerpo y la escena, leer la autopsia en la
   morgue, preguntar a testigos, escuchar chismes (que se deforman al pasar de boca en boca), registrar casas o cofres.
   El culpable **miente** y puede intentar callar a quien sabe demasiado. El inquisidor real también investiga, y
   **puede sospechar de ti**.
3. **La acusación:** acusas ante el inquisidor o en el juicio público de la plaza. Si aciertas, el culpable cae. Si te
   equivocas, condenan a un inocente y el culpable sigue suelto (y quizá vuelve a matar).
4. **Final:** pantalla de resumen: qué descubriste y cómo, a quién acusaste, si era el culpable, a quién ayudaste o
   perjudicaste, y lo más llamativo de la crónica del pueblo.

## 2. Lo que ya existe y sirve

| Pieza | Dónde |
|---|---|
| Asesinatos de vecinos con móvil (planes de venganza, celos, ambición) | `VillageDesires`, `VillageForensics.on_npc_murder_committed` |
| Escena del crimen: cuerpo, sangre, huellas, limpiar con lejía | `VillageForensics` |
| Testigos que ven y denuncian, en 3 fases | `VillageNPC` (aviso de cadáver) |
| Morgue y autopsia | `VillageManager` (morgue), `VillageJustice` |
| Investigación del comisario y del inquisidor real (entrevistas, cruce de datos, sospechosos) | `VillageJustice` |
| Interrogatorio del jugador y juicio público en la plaza | `VillageJustice.resolve_player_interrogation_outcome`, `resolve_public_trial_intervention` |
| Chismes que se deforman y secretos con «quién lo sabe» | `GossipMemory`, `VillageSecrets` |
| Registro de misiones (tecla J) y crónica del pueblo (tecla O) | `QuestManager`, `VillageChronicle` |

## 3. Lo que falta (de más a menos importante)

1. **Arranque de partida «beta»:** que la partida nueva prepare el caso: elegir víctima y culpable con motivo creíble
   y provocar el asesinato a una hora razonable, siempre una vez y de forma que el jugador pueda llegar a tiempo.
2. **Hilo de objetivos visibles:** usar el registro de misiones como cuaderno del detective: pistas encontradas,
   sospechosos, siguiente paso sugerido. Que un amigo sepa qué hacer sin que se lo expliques.
3. **Pistas que se puedan encontrar en el mundo** (no solo en diálogos): objeto perdido del culpable, carta, arma,
   huellas que llevan a una casa… con [E] y letrero.
4. **Acusación clara:** una forma explícita de acusar (al inquisidor o en el juicio) con confirmación, y el resultado.
5. **Pantalla de final con resumen** (lo dice la decisión del usuario) y opción de volver a empezar con otro culpable.
6. **Ayuda de controles** con las 8 teclas básicas al empezar.
7. **Pulido para jugar fuera de casa:** quitar el arranque provisional de 40 vecinos (o decidir cuántos), comprobar
   rendimiento en un ordenador modesto, guardar/cargar a mitad del caso.
8. **Exportar para Windows** y un «Léeme» con controles y qué se espera del jugador.

## 4. Preguntas para retocar más adelante (no bloquean)

- ¿El jugador llega siendo forastero (sospechoso natural) o con un papel (ayudante del comisario, periodista…)?
- ¿Cuánto debe ayudar el juego a encontrar pistas (más guiado o más libre)?
- ¿Puede haber un segundo asesinato si tardas mucho?
- ¿Se puede ganar también mintiendo y culpando a otro a propósito (final «turbio»)?
- ¿Cuántos vecinos en la beta? (más vecinos = más sospechosos, pero más lento en ordenadores modestos)

## 5. Idea del usuario (2026-11-06): «crimen ya hecho, con estructura fija y reparto procedural»

> Texto creativo del usuario, provisional (nombres por decidir). Lo fijo es **la cadena de pistas**; lo procedural es
> **quién hace cada papel y dónde**, elegido entre vecinos reales que encajen.

**La cadena (fija):**
1. Aparece una mujer muerta en el bosque: estrangulada; el cuerpo huele a una hierba rara.
2. El **alquimista** identifica la hierba: se usaba para embalsamar, pero el cura del pueblo no la usa.
3. Hay que buscar quién sabe prepararla y tiene acceso a la planta. No crece por aquí: huerto privado o caravana.
   La poción es **muy inestable** (usuario, 2026-11-08): plena hasta la hora 12, se degrada desde la hora 13 y a la
   hora 48 no vale nada → se usó recién hecha → fue **premeditado y caro** → apunta a gente pudiente.
4. Investigas a los **nobles**: esconden algo, pero no fueron ellos (presagio de la secta: la poción era suya y se la
   robaron; no pueden decirlo sin meterse en líos). Una **criada** identifica la sustancia (reconoce el frasco).
   **Cómo se descubre el robo (decidido por el usuario, 2026-11-08):** la criada reconoce el frasco y menciona el gabinete
   de los señores; registrando el gabinete (con permiso o a escondidas) se ve la cerradura forzada. Sin marca de polvo.
   **Casa abandonada (usuario, 2026-11-08):** un **molino viejo junto al arroyo, río arriba del claro** del cuerpo; se
   llega siguiendo el agua. Allí el barro es **rojo**, la misma arcilla de los ladrillos de algunas casas del pueblo
   (pista doble: lleva al molino… o hace sospechar de quien vive en casas de ladrillo rojo). **Requisito del mapa:** el
   usuario quiere **un río que cruce el pueblo** (no solo lagos); el arroyo del caso nace de él / es su tramo alto.
5. El «culpable» aparente es un **familiar o pareja** de la víctima que quería salvarla de un **culto que la tenía
   secuestrada** en una casa abandonada: mezcló la poción con otras de un libro antiguo de la biblioteca para fingir su
   muerte. La dosis salió mal (libro antiguo): la paralizó y duró poco.
6. Los secuestradores, al creerla muerta e invendible, profanaron el cuerpo (no se describe). Al ver que se movía, el
   **más joven** la estranguló por miedo a que los delatara.
7. Lo del familiar lo sabes hablando con él; lo de los secuestradores, **interrogando a uno si lo capturas vivo**.
8. Deja abierta la investigación de la secta y la corrupción del pueblo.
   **Gancho de la secta (usuario, 2026-11-08):** (a) en el molino aparece una **lista de nombres de personas desaparecidas**;
   (b) por la regla de las 48 horas, el jugador debe **averiguar quién más sabe preparar el sueño de cera**. Lo que hay
   detrás es lore del usuario: no se explica en el Caso I.
   **Regla:** si sobrevive un secuestrador se le puede interrogar, pero **no tiene por qué sobrevivir**: el caso debe poder
   resolverse sin capturarlo (lo que contaría él tiene que poder deducirse por otras pistas).

**La nota «V.» (decidido por el usuario, 2026-11-08, noche):** la nota del bolsillo («…después del toque de queda en el
puente viejo — V.») **fue un cebo para secuestrarla**: el culto la citó en el **puente viejo** y allí se la llevaron. La
firma **imita la inicial del familiar** (sabían a quién quería ella), por eso acudió sola de noche. Consecuencias:
(a) el familiar parece culpable desde el principio (su papel de culpable aparente) y carga con la culpa de que usaran su
nombre; (b) el puente viejo es el **lugar del secuestro** (posibles testigos o rastros); (c) **comparando la letra** de la
nota con la del familiar (carta, recibo) se ve que es una **falsificación**, lo que empieza a limpiarle; (d) el **frasco
vacío** del mismo bolsillo es otra historia (el plan del familiar): el jugador debe separar los dos objetos. El parecido
de «V.» con el Dr. **Valen** queda como sospecha falsa. *Pendiente:* pasar esto a los textos del caso en el juego y al
documento de Word de `Documentos/`.

**El carro (decidido por el usuario, 2026-11-08, noche):** tras dejar el cuerpo en el claro, los secuestradores dieron
**un rodeo a propósito hacia el sur** (los almacenes) para no llevar a nadie hacia el molino. El leñador dice la verdad
(lo oyó bajar hacia el sur), pero es un **despiste**. En el claro, las **marcas de rueda** muestran que el carro **llegó
desde el norte** (río abajo desde el molino) y **dio la vuelta**: un jugador atento ve las dos direcciones y entiende el
engaño. *Pendiente:* ajustar los textos de la pista de las ruedas y del leñador en el juego.

**La capa parda y la lana azul (decidido por el usuario, 2026-11-09):** son **dos secuestradores distintos**. El
**joven de la capa parda** es el que estranguló a la víctima y el que vio huir la pastora. La **lana azul oscuro** bajo
las uñas es de **otro secuestrador que la sujetaba** mientras el joven apretaba: ella le arañó el brazo. Así el jugador
descubre que **eran varios**, lo que separa el final bueno (acusar al grupo) del perfecto (acusar al joven). La lana
azul es una pista para encontrar al segundo: alguien con una **prenda azul rota** o **arañazos en el brazo**.
*Pendiente:* reflejarlo en los textos del caso en el juego.

**Cómo llegó el frasco a la víctima (decidido por el usuario, 2026-11-09):** el familiar **pidió ayuda a la guardia**,
pero no encontraron nada / no les importó / no tenían interés (los nobles mandan). **Pista:** en la comisaría hay una
**denuncia de desaparición archivada** sin investigar. Luego la buscó por su cuenta siguiendo el río hasta el molino. La
tienen **en el sótano del molino**, que da al **canal de la rueda**. Desde el agua llegó a una **reja de hierro** que no
pudo arrancar (fuera había varios secuestradores armados), pero **entre los barrotes cabía el frasco**: se lo pasó y le
susurró el plan. **Pistas en el molino:** reja con **marcas de haber intentado forzarla** y un **trozo de tela del
familiar** enganchado. **El familiar tiene barro rojo en las botas** (estuvo en el molino): le hace aún más sospechoso.
*Pendiente para el juego:* el molino necesita **sótano con reja al canal de la rueda**; la denuncia archivada en la comisaría.

**La víctima (decidido por el usuario, 2026-11-09):** el papel lo hace una vecina al azar, con tres rasgos fijos:
(1) **alguien sin peso en el pueblo** (criada, lavandera, jornalera o viuda pobre): por eso la guardia archivó la
denuncia; si la lista de desaparecidos del molino es de gente así, el jugador ve un **patrón** sin que se explique;
(2) **un hueco visible en su vida**: cama sin deshacer, una tarea a medias (ropa tendida que nadie recoge) y un vecino
que pregunta por ella; (3) **su zapato izquierdo** (el que falta en el cuerpo) **aparece en el puente viejo**, donde la
secuestraron: la pista lleva al lugar del secuestro. **Por qué el culto la eligió: abierto a propósito** (lore del
usuario); se sabrá después de la demo. No inventarlo.

**Los secuestradores (decidido por el usuario, 2026-11-09):** son **tres**. (1) **El joven de la capa parda**
(forastero; la estranguló; la pastora lo vio huir). (2) **El de la lana azul** (**vecino del pueblo con doble vida**; la
sujetaba y ella le arañó): el jugador debe encontrarlo entre los vecinos por la **prenda azul rota** o los **arañazos en
el brazo**. (3) **El del carro**, forastero, que **conduce y manda** en el grupo. Cuando llega el jugador, los forasteros
están **escondidos en el molino unos días esperando órdenes**; **si el jugador tarda demasiado, se van**. Se puede pelear
o escabullirse; que uno sobreviva para el interrogatorio es opcional.

**El libro y la sala oculta de la biblioteca (decidido por el usuario, 2026-11-09):** el libro antiguo de la receta es
**secreto y vetado por la Iglesia y la ley**; solo el **bibliotecario** sabe que existe. Está en una **habitación oculta
dentro de la biblioteca** con libros de **ocultismo, venenos y la antigua fe** que el nuevo gobierno intentó erradicar
para imponer la suya (lore del usuario: no ampliar sin preguntar). El familiar llegó al libro **gracias al
bibliotecario**. Cadena de pistas: (1) en la sala oculta hay un **cuaderno secreto** donde firma quien consulta los
libros prohibidos: la **firma del familiar** es la muestra de letra para ver que la nota «V.» es falsa; (2) al libro le
falta **una página arrancada** (en el índice se lee el capítulo, p. ej. «Del sueño que imita la muerte»); (3) la página
está **en casa del familiar** con **dosis tachadas y corregidas** de su puño y letra (por eso salió mal). **Cómo se
encuentra la sala:** las dos vías: **por observación** (corriente de aire, marcas de arrastre junto a una estantería, un
libro que no sale porque es la palanca) o **presionando al bibliotecario** cuando ya hay pruebas contra el familiar.
**Por qué le ayudó el bibliotecario (decidido por el usuario, 2026-11-09):** es **viejo** y **recuerda cómo era todo
antes del reinado actual**; **está en contra**, pero **sabe que no puede hacer nada**. Guardar la sala y ayudar en
silencio es lo único que le queda. (Su secreto puede costarle la cárcel: el jugador podría delatarle o protegerle.)

**Nombres:** la hierba es la **belladama gris** (elegido por el usuario, 2026-11-08: recuerda a la belladona y el «dama» apunta a los ricos). La poción es el **sueño de cera** (elegido por el usuario, 2026-11-08: deja el cuerpo quieto y pálido como de cera).

## 5b. Acusación y final de la demo (decidido por el usuario, 2026-11-08)

**Acusación por niveles:** acusar al familiar = final malo (condenan a quien quería salvarla); acusar al grupo de
secuestradores = final bueno; acusar al secuestrador joven en concreto = final perfecto.

**Final común de la demo (pase lo que pase en la acusación):**
1. A **cualquiera que encarceles** lo encuentran **«muerto» en prisión** pasados unos días. El médico firma el acta de
   defunción **sin pasarlo por la morgue** y lo **entierran el mismo día**.
2. Si el jugador va a la tumba y **decide excavarla**, la encuentra **vacía**, con una **nota que dice su verdadero nombre**.
3. Mientras la lee, **alguien le habla por detrás**; antes de que pueda verle la cara, **le golpea en la cabeza** y pierde el
   conocimiento. **Fin de la demo.**

**Trasfondo del protagonista (usuario, 2026-11-08):** el jugador es un **impostor**: tomó la identidad del verdadero
investigador que iba a llegar al pueblo. No lo mató: lo encontró **«suicidado»** en algún lugar, aunque con señales de
haber luchado. La **secta** mandó matar al verdadero detective y lo disfrazó de suicidio; por eso **saben desde el
principio** que el jugador no es quien dice. Callaron porque creyeron que sería un incompetente en el cargo (les
convenía), pero resultó tener talento para resolver crímenes y se volvió una molestia.

**Decidido por el usuario (2026-11-08, noche):**
- **Muerte del preso:** aparece «muerto» **un día después de que llegue el mercader** al pueblo. En la demo el mercader
  **llega un día fijo después de la acusación** (no se espera a la caravana normal).
- **Calendario del final (corregido por el usuario, 2026-11-08):** día A, acusación → día A+1, **los nobles organizan una
  fiesta para el pueblo** y por eso llega el mercader un día no previsto (trae lo de la fiesta); esa noche la gente está
  **ebria y distraída** → día A+2, el preso amanece «muerto», Valen firma y lo entierran ese día → el jugador puede
  excavar la tumba (sin la cobertura de la fiesta: cuidado con los testigos).
- **La fiesta es la tapadera (usuario, 2026-11-08):** mientras el pueblo bebe esa noche, **sacan al preso del calabozo**
  sin que nadie lo vea; a la mañana siguiente lo dan por «muerto». Un jugador atento puede sospechar de una fiesta
  sorpresa justo esa noche (p. ej. el carcelero borracho, la puerta del calabozo sin vigilancia un rato, alguien que vio
  un carro salir de madrugada), pero nada lo confirma antes de la tumba vacía.
- **El médico es el Dr. Valen:** no es cómplice directo, solo **sigue órdenes**; es un peón más. **Los nobles deciden todo
  lo que pasa en el pueblo.**
- **Nombres:** el detective suplantado es **Jean Porterre**; el nombre real del protagonista es **Dean Hollow**.
- **Pasado de Dean:** **desertor** de la guerra que existe en el mundo; huyó tras **matar a un superior en una discusión**.
  Está en **territorio enemigo** y no puede volver a casa.
- **Excavar la tumba:** con la **pala** que ya existe en el juego. Si alguien te ve, **llama a la guardia**: multa y
  **noche en el calabozo**.
- **Inicio de la partida:** llegas a las **afueras del pueblo** mientras se lee tu carta de contratación (**solo texto en pantalla**, sin voz grabada),
  escrita como si fueras el verdadero detective (Jean Porterre). **El giro (eres un impostor) se guarda para el final de
  la demo**: nada antes debe delatarlo.

## 6. Herramientas del detective (decidido por el usuario, 2026-11-07)
Eje central del bucle jugable; tiene que quedar «perfecto». Boceto aprobado por el usuario («me encanta»):
`docs/bocetos/examen_cuerpo.html` (ábrelo en el navegador; también publicado en claude.ai/artifact/NMDw1NPEkcWCQrkGAttkFk).
1. **Examen del cuerpo en la escena:** silueta plana (sin líneas interiores ni cara), **dos modelos, mujer y hombre**,
   según la víctima. Zonas (cabeza, cuello, torso, brazos, manos, piernas, bolsillos) con acciones mirar / palpar /
   oler / lupa / registrar que gastan minutos; solo lo superficial; las marcas aparecen dibujadas en la silueta.
2. **Autopsia en la morgue con el forense:** pruebas por pasos donde puedes fallar (muestra de sangre limitada,
   reactivo equivocado gasta muestra, corte rápido estropea el cuello, tirar el contenido del estómago lo pierde),
   consejo del forense a cambio de tiempo; la causa real se va completando.
3. **Escena del crimen:** mapa desde arriba a oscuras; las pistas solo se ven bajo el farol (surcos de arrastre, huellas, ruedas, la hierba, ausencia de sangre, barro en el arroyo); testigos con «preguntar» y «presionar» (puede cerrarse). **Tablero de corcho:** sospechosos arriba, fichas del cuaderno debajo, se arrastran y se unen con hilo rojo.
4. Todo hallazgo se anota en el **cuaderno del caso** (fichas) que luego pasan al tablero.
5. **10 casos principales guionizados** con diálogos y sucesos propios, cada uno en su archivo de datos, usando las
   mismas herramientas; además, el sistema procedural de siempre.
6. **Fondo real del lugar (idea del usuario, 2026-11-07):** al examinar un cuerpo o una escena, el fondo es una «foto»
   desde arriba del sitio real donde está (bosque, calle, interior, alcantarilla), tomada en ese momento con la vista 3D
   sin vecinos ni jugador, y pasada a **esquema**: oscura, casi sin color, bordes marcados como un plano a tinta. La
   silueta del cuerpo y las pistas van encima. El efecto se ajusta a ojo con el usuario.
