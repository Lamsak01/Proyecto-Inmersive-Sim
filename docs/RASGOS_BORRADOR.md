# Borrador: 100 rasgos de personalidad (para revisar)

Este borrador es para que lo revises antes de programar nada (bloque T2). Puedes tachar, renombrar, mover o añadir rasgos.
★ = rasgo que ya existe hoy (se conserva con el mismo nombre). **R** = raro (aparece poco).

## Reglas propuestas

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

## Ejes de opuestos (87 rasgos en 36 ejes)

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
| 12 | Envidia | Conforme · Envidioso | Mal; el Envidioso calumnia a quien prospera |
| 13 | Celos (pareja) | Seguro de sí · Celoso★ | Celos en pareja (ya existe el efecto) |
| 14 | Perdón | Indulgente · Rencoroso★ · Vengativo **R** | Ren; el Vengativo podría pedir misiones de venganza |
| 15 | Dinero | Generoso · Ahorrador · Codicioso★ | Gen, Hon; el Codicioso acepta sobornos y pide encargos de oro |
| 16 | Calidez | Cariñoso · Frío★ | Soc, *Rom* |
| 17 | Horario | Madrugador · Noctámbulo★ | *Horario*: cambia su rutina |
| 18 | Discreción | Discreto · Chismoso★ | Chi, Mal; el Discreto no cuenta lo que sabe, ni siquiera a ti |
| 19 | Trato | Amigable · Tímido · Huraño | Soc; el Tímido tarda más en abrirse (ver «Descubrimiento») |
| 20 | Respeto | Respetuoso · Insolente | Mal (el Respetuoso no habla a espaldas de nadie); el Insolente provoca roces |
| 21 | Tolerancia | Permisivo · Estricto · Intolerante | Ren; el Permisivo perdona antes y el Intolerante choca con los distintos |
| 22 | Orden | Ordenado · Desordenado | Lab; efectos menores en casa y en su oficio |
| 23 | Ambición | Ambicioso · Conformista | Lab; el Ambicioso pide encargos para prosperar |
| 24 | Fe | Devoto · Escéptico | *Fe*; el Devoto va a la iglesia y cree más en la Inquisición |
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

## Rasgos sueltos, sin opuesto (13)

| Rasgo | Efecto |
|---|---|
| Tahúr★ | Juega y apuesta en la taberna; Hon ↓ |
| Supersticioso | Evita el cementerio de noche; se cree los rumores raros |
| Protector | Defiende a familia y amigos: interviene en peleas y denuncia ataques |
| Nostálgico | Habla del pasado; visita tumbas a menudo |
| Aventurero | Más probable que se marche del pueblo o que llegue de lejos |
| Artista | Charlas con más chispa; se ofende si le critican |
| Estudioso | Mejor testigo: recuerda detalles en las investigaciones |
| Amante de los animales | Cuida mascotas; se enfada si las maltratas |
| Hipocondríaco | Va mucho al médico; se queja aunque no tenga nada |
| Coleccionista | Pide objetos raros en encargos |
| Sanguinario **R** | Ya se usa como rasgo sospechoso en investigaciones; Agr ↑↑ |
| Cleptómano **R** | Roba pequeñas cosas; puede ser sospechoso de robos |
| Insomne | Duerme poco: deambula de noche y es testigo de lo que pasa a esas horas |

Total: 87 + 13 = **100 rasgos**.

## Dudas para ti

1. **Nombres en masculino o según el género del vecino:** por ejemplo, «Celoso» o «Celosa».
2. **Rasgos oscuros raros (Cruel, Violento, Sanguinario, Delincuente, Manipulador…):** ¿los quieres, o el pueblo debe ser más amable?
3. **Opiniones de otros sobre los rasgos:** ¿un vecino que odia a otro puede contarte rasgos falsos de él, o los vecinos siempre dicen la verdad sobre los demás?
4. **El rasgo Celoso:** hoy su descripción dice «le corroe lo que tienen los demás» (eso es envidia). Propongo que Celoso sea solo celos de pareja y añadir Envidioso aparte.
