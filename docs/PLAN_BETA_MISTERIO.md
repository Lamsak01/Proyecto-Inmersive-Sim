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

**Nombres:** la hierba es la **belladama gris** (elegido por el usuario, 2026-11-08: recuerda a la belladona y el «dama» apunta a los ricos). La poción es el **sueño de cera** (elegido por el usuario, 2026-11-08: deja el cuerpo quieto y pálido como de cera).

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
