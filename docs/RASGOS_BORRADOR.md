# Borrador: 140 rasgos de personalidad (para revisar)

Este borrador es para que lo revises antes de programar nada (bloque T2). Puedes tachar, renombrar, mover o añadir rasgos.
★ = rasgo que ya existe hoy (se conserva con el mismo nombre). **R** = raro (aparece poco).

## Reglas propuestas

- **Nombres según el género** del vecino (Celoso / Celosa); las formas que no cambian (Líder, Insomne) se quedan igual. *(Decidido.)*
- **Cada rasgo hace algo.** Si el sistema que lo usa aún no existe (fe, vicios, corrupción...), el rasgo ya lleva su tendencia y «despierta» cuando llegue ese sistema.
- **Cada vecino tiene 6 rasgos.** Nunca dos del mismo eje: no se puede ser Trabajador y Holgazán a la vez.
- **Rareza:** como máximo 1 rasgo raro por vecino; cada recién llegado tiene más o menos un 25 % de llevar uno.
- **Equilibrio:** de media, unos 3 rasgos «amables», 2 neutros y 1 «difícil», para que el pueblo no salga ni angelical ni tóxico. Este reparto se podrá ajustar más adelante.
- **Efectos:** cada rasgo sube (↑) o baja (↓) tendencias. Estas son las que ya existen en el código:
  - **Mal** = malicia (calumniar)
  - **Ren** = rencor
  - **Chi** = chismorreo
  - **Agr** = agresividad
  - **Hon** = honestidad
  - **Conf** = confianza
  - **Lab** = laboriosidad
  - **Gen** = generosidad
  - **Soc** = sociabilidad

  Algunos rasgos necesitan además tendencias nuevas, marcadas *en cursiva*: *Rom* (romance), *Valor*, *Ley* (respeto a la ley), *Fe*, *Vicio*, *Salud* y *Horario*.
- **Efecto especial:** algunos rasgos tienen un efecto propio, además de sus tendencias. Por ejemplo, el Noctámbulo trasnocha.

## Ejes de opuestos (118 rasgos en 51 ejes)

| # | Eje | Rasgos, de un extremo al otro | Efecto principal |
|---|---|---|---|
| 1 | Sinceridad | Honrado★ · Mentiroso · Manipulador **R** | Hon ↑/↓; el Mentiroso puede darte coartadas falsas o mentir en interrogatorios; el Manipulador calumnia con más éxito |
| 2 | Lealtad | Leal★ · Traicionero **R** | Conf/Mal; el Traicionero puede delatarte aunque te aprecie |
| 3 | Temple | Pacífico★ · Pendenciero · Violento **R** | Agr; el Violento puede pelear antes de cumplir los días de enemistad |
| 4 | Bondad | Bondadoso★ · Egoísta · Cruel **R** | Gen, Mal |
| 5 | Ánimo | Alegre★ · Melancólico · Amargado | Soc, Ren; el Melancólico pasa peor los duelos |
| 6 | Curiosidad | Curioso★ · Indiferente | Chi; el Curioso se acerca a mirar sucesos (y ve más cosas como testigo) |
| 7 | Laboriosidad | Trabajador★ · Holgazán | Lab; afecta al rendimiento en su oficio y a la rutina |
| 8 | Paciencia | Paciente★ · Impaciente · Irascible | Agr, Ren |
| 9 | Valentía | Temerario **R** · Valiente★ · Prudente · Cobarde | *Valor*; afecta a si huye, si ayuda en peleas o si denuncia |
| 10 | Humildad | Humilde · Orgulloso★ · Arrogante | Ren, Mal; el Arrogante se ofende más |
| 11 | Confianza | Ingenuo **R** · Confiado · Desconfiado★ · Paranoico **R** | Conf; cuánto se cree lo que le cuentas (calumnias, mediación) |
| 12 | Envidia | Conforme · Envidioso | Mal; el Envidioso calumnia a quien prospera *(sustituye al antiguo «le corroe lo que tienen los demás» de Celoso; decidido)* |
| 13 | Celos (pareja) | Seguro de sí · Celoso★ | Solo celos de pareja (ya existe el efecto) *(decidido)* |
| 14 | Perdón | Indulgente · Rencoroso★ · Vengativo **R** | Ren; el Vengativo podría pedir misiones de venganza |
| 15 | Dinero | Generoso · Codicioso★ | Gen, Hon; el Codicioso pide encargos de oro |
| 16 | Calidez | Cariñoso · Frío★ | Soc, *Rom* |
| 17 | Horario | Madrugador · Noctámbulo★ | *Horario*: cambia su rutina |
| 18 | Discreción | Discreto · Chismoso★ | Chi, Mal; el Discreto no cuenta lo que sabe, ni siquiera a ti |
| 19 | Trato | Amigable · Tímido · Huraño | Soc; el Tímido tarda más en abrirse (ver «Descubrimiento») |
| 20 | Respeto | Respetuoso · Insolente | Mal (el Respetuoso no habla a espaldas de nadie); el Insolente provoca roces |
| 21 | Tolerancia | Permisivo · Estricto · Intolerante | Ren; el Permisivo perdona antes y el Intolerante choca con los distintos |
| 22 | Orden | Ordenado · Desordenado | Lab; efectos menores en casa y en su oficio |
| 23 | Ambición | Conformista · Ambicioso · Sediento de poder **R** | Lab; el Ambicioso pide encargos para prosperar; el Sediento de poder busca cargos (alcalde, jefe) y conspira |
| 24 | Fe | Escéptico · Devoto · Fanático **R** | *Fe*; el Devoto va a la iglesia y cree más en la Inquisición; el Fanático es carne de secta |
| 25 | Amor | Romántico · Desapegado | *Rom*: más o menos chispa |
| 26 | Familia | Familiar · Independiente | Soc; el Familiar sufre más las pérdidas de los suyos |
| 27 | Humor | Bromista · Serio | Soc; el Bromista mejora las charlas, pero puede ofender a un Serio |
| 28 | Ingenio | Astuto · Despistado | Ve o no ve tus trucos (robos, pruebas colocadas) |
| 29 | Responsabilidad | Responsable · Irresponsable | Lab, *Ley*; el Irresponsable falta al trabajo |
| 30 | Bebida | Sobrio · Bebedor | *Vicio*: taberna; el Bebedor habla de más cuando bebe |
| 31 | Comida | Frugal · Glotón | El hambre le afecta más o menos |
| 32 | Aseo | Pulcro · Desaliñado | Soc (primeras impresiones) |
| 33 | Ley | Cumplidor · Rebelde · Delincuente **R** | *Ley*, Hon; el Delincuente puede robar o encubrir |
| 34 | Aguante | Duro · Quejica | *Salud*: cómo lleva heridas y enfermedades |
| 35 | Palabra | Hablador · Callado | Chi, Soc |
| 36 | Mando | Líder · Sumiso | El Líder arrastra opiniones; el Sumiso se deja convencer (Conf) |
| 37 | Fidelidad | Fiel · Infiel | *Rom*; el Infiel busca aventuras aunque tenga pareja (infidelidades) |
| 38 | Vanidad | Modesto · Vanidoso | *Fama*; el Vanidoso busca que le admiren y se hace famoso antes (Modesto ≠ Humilde: Humilde reconoce errores, Modesto no busca fama) |
| 39 | Empatía | Empático · Insensible | Gen, Conf; el Empático consuela en los duelos y nota cuando alguien sufre |
| 40 | Nervios | Sereno · Nervioso | En interrogatorios el Nervioso parece culpable aunque sea inocente; el Sereno miente mejor |
| 41 | Memoria | Memorioso · Olvidadizo | Testigos: recuerda o no lo que vio; el Olvidadizo olvida favores y ofensas antes (Ren) |
| 42 | Impulso | Metódico · Impulsivo | Agr, Lab; el Impulsivo actúa sin pensar (pelea, compra, se declara) |
| 43 | Gasto | Ahorrador · Derrochador | *Dinero*; el Derrochador se arruina y pide prestado |
| 44 | Integridad | Íntegro · Sobornable | *Ley*; el Sobornable acepta sobornos; base de la policía y el alcalde corruptos |
| 45 | Tradición | Tradicionalista · Innovador | Rechaza o adopta tecnología nueva; el Innovador puede ser ingeniero |
| 46 | Arraigo | Hogareño · Aventurero | El Aventurero se marcha antes del pueblo o llega de lejos; el Hogareño casi nunca se va |
| 47 | Competencia | Cooperativo · Competitivo | Apuestas, club de la lucha, carreras y negocios rivales |
| 48 | Coqueteo | Recatado · Coqueto | *Rom*; el Coqueto provoca chispas (y celos) con facilidad |
| 49 | Manos | Mañoso · Torpe | Calidad de lo que fabrica; base de los maestros artesanos |
| 50 | Creatividad | Creativo · Convencional | Estilo propio en su oficio; el Creativo puede volverse famoso por su obra |
| 51 | Voluntad | Disciplinado · Débil de voluntad | *Vicio*: riesgo de caer en adicciones (la adicción es un estado que se adquiere, no un rasgo) |

## Rasgos sueltos, sin opuesto (22)

| Rasgo | Efecto |
|---|---|
| Tahúr★ | Juega y apuesta en la taberna; Hon ↓ |
| Supersticioso | Evita el cementerio de noche; se cree los rumores raros |
| Protector | Defiende a familia y amigos: interviene en peleas y denuncia ataques |
| Nostálgico | Habla del pasado; visita tumbas a menudo |
| Artista | Charlas con más chispa; se ofende si le critican |
| Estudioso | Mejor testigo: recuerda detalles en las investigaciones |
| Amante de los animales | Cuida mascotas; se enfada si las maltratas |
| Hipocondríaco | Va mucho al médico; se queja aunque no tenga nada |
| Coleccionista | Pide objetos raros en encargos |
| Sanguinario **R** | Ya se usa como rasgo sospechoso en investigaciones; Agr ↑↑ |
| Cleptómano **R** | Roba pequeñas cosas; puede ser sospechoso de robos |
| Insomne | Duerme poco: deambula de noche y es testigo de lo que pasa a esas horas |
| Obsesivo **R** | Puede idolatrar u obsesionarse con una persona (muy raro) |
| Místico | Atraído por lo oculto; más fácil de captar por la secta |
| Celestino | Intenta emparejar a otros vecinos |
| Negociante | Regatea mejor; prospera con su propio negocio |
| Mentor | Enseña a otros (aprendices, futura escuela) |
| Fanfarrón | Presume y reta a otros; carne de peleas callejeras y apuestas |
| Justiciero | Investiga por su cuenta y puede tomarse la justicia por su mano |
| Sonámbulo **R** | Camina dormido de noche: testigo poco fiable de cosas raras |
| Ermitaño **R** | Vive apartado y apenas se relaciona |
| Chantajista **R** | Usa los secretos que conoce para sacar oro o favores |

Total: 118 + 22 = **140 rasgos** (17 raros). Se pueden añadir más con el tiempo sin romper nada.

## Decisiones del usuario (2026-11-02)

1. Nombres según el género del vecino.
2. Rasgos oscuros: sí, pero raros (como máximo uno raro por vecino).
3. Un vecino malicioso o Mentiroso con mala relación puede contarte rasgos falsos de otro; el glosario los marca «según X» hasta que lo compruebes tú.
4. Celoso = solo celos de pareja; Envidioso aparte.
5. Más de 100 rasgos: la cifra era orientativa; la ciudad final tendrá 100+ vecinos. Añadidos los ejes 37–51 y 10 sueltos.

**Aprobada y cargada en el juego (T2, 2026-11-02).** Los datos viven en `scripts/data/TraitCatalog.gd`; para cambiar un rasgo, edita ahí (no renombres ids ya publicados).
