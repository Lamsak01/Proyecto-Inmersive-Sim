# Objetivos del Caso I que nacen de las pistas (hecho el 2026-11-13)

> Claude Code, 2026-11-13. Idea del usuario: los objetivos los abren las pistas que encuentras (verdaderas o falsas),
> son preguntas del detective y **nada apunta directamente al molino**. Todo sale de lo que ya dice el caso
> (`DetectiveCaseData.gd`); no se inventa historia. Texto provisional.
> Cada línea: **pregunta que aparece en misiones** · la abre… · se cierra (o avanza) con…
> En el juego: `scripts/systems/Case1Objetivos.gd` (tabla `PREGUNTAS`, pestaña «🔎 Caso» del diario) y
> `scripts/systems/Case1Aviso.gd` (guardia que avisa y custodia). Se añadió la pregunta de la fosa (p15) y el recado
> de Vane (a0).

## Arranque
- **La carta (usuario, 2026-11-13):** es tu contrato de detective del pueblo, solo historia de fondo; **no habla del
  asesinato**. Queda en la mochila para releerla. Su texto actual (lavandera desaparecida, denuncia) hay que cambiarlo.
- **El asesinato ocurre después de que llegues** (usuario): no vienes a resolverlo. Propuesta: el día 1 conoces el
  pueblo; al alba del día 2 un vecino encuentra el cuerpo junto al arroyo y da la voz; la policía pone un guardia en la
  escena y Vane te manda llamar.
- **A1 · «Han encontrado a una mujer muerta junto al arroyo del norte»** · **Vane te manda llamar** (usuario) ·
  examinar el cuerpo.
- **Tumba a medio cavar junto al cuerpo (usuario, 2026-11-13):** como si alguien la fuera a enterrar. Pista que se
  examina con [E]. Qué significa lo decide el autor.
- **Más lejos del molino (usuario):** si el claro está a ~60 m, el jugador va al molino lo primero. Se aleja río abajo
  (siguiendo el arroyo, para que las rodadas «desde el norte» y el barro rojo sigan teniendo sentido).
- **Escena custodiada (usuario, 2026-11-13):** un guardia de la comisaría vigila el claro junto al cuerpo («no tiene
  sentido que la policía deje el cuerpo a la intemperie»). Te deja pasar porque eres el detective; se queda hasta
  que el cuerpo se lleva a la morgue, y luego vuelve a su ronda.

## Cómo murió
- **1 · «Labios azules y puntitos rojos en los ojos: ¿murió asfixiada?»** · mirar cabeza o cuello · autopsia del
  cuello en la morgue.
- **2 · «Olía a almendra amarga: ¿qué bebió antes de morir?»** · oler la boca o el frasco del bolsillo · autopsia del
  estómago → abre la 3.
- **3 · «Un líquido verdoso en el estómago: ¿quién sabe de hierbas así?»** · autopsia del estómago · enseñárselo al
  boticario → abre la 4.
- **4 · «Una poción cara, inestable y recién hecha: ¿quién pudo tenerla?»** · lo que dice el boticario · la criada
  reconoce el frasco → abre la 5.
- **5 · «Alguien forzó el gabinete de los señores: ¿quién?»** · la criada · ver el gabinete forzado.

## Dónde estuvo
- **6 · «Barro rojo en los talones, ceniza en las rodillas, paja en el pelo: ¿dónde estuvo antes?»** · pies, rodillas
  o pelo · examinar la orilla de barro rojo (se llega siguiendo el arroyo; el barro rojo de los ladrillos de algunas
  casas despista).
- **7 · «La ataron con cordel de cáñamo encerado: ¿de dónde sale ese cordel?»** · las muñecas · el cordel del molino.
- **8 · «La movieron ya muerta: ¿quién trajo un carro de madrugada?»** · lividez del costado, surcos o rodadas ·
  hablar con el leñador.

## Quién
- **9 · «¿Quién es «V.»? La citó en el puente viejo tras el toque de queda»** · la nota del bolsillo · el zapato del
  Puente Viejo. *(Quién es «V.» lo decide el autor.)*
- **10 · «Se defendió: hay lana azul bajo sus uñas»** · bajo las uñas · ver a alguien con el jubón azul rasgado.
- **11 · «Un muchacho de capa parda corría junto al arroyo»** · la pastora · encontrar al muchacho.
- **12 · «La hoja arrancada viene de un libro: ¿de cuál?»** · la hoja de casa del familiar · el libro de la
  biblioteca → abre la 13.
- **13 · «Un libro viejo con dosis corregidas: ¿quién lo usó?»** · el libro · hablar con el familiar.
- **14 · «Su desaparición se denunció y nadie la buscó: ¿por qué?»** · Vane o el pueblo · la denuncia archivada.

## Pistas falsas (abren objetivos que no llevan al culpable)
- **F1 · «El boticario guarda hierbas de embalsamar bajo llave: ¿fue él?»** · tablero de sospechosos · se queda
  abierta hasta que otras pistas lo descarten.
- **F2 · «El molinero tiene carro y cordel encerado: ¿fue él?»** · tablero de sospechosos · ídem.
- **F3 · «Algunas casas del pueblo tienen ladrillos de esa misma arcilla roja: ¿estuvo en una?»** · la 6 · se cierra
  al encontrar la orilla de barro rojo.

## Final
- **Z · «Entrega tu informe del caso en la comisaría»** · cuando tengas varias pruebas · firmar el informe.

## Reglas
- Un objetivo se cierra solo cuando lo resuelve una pista; si nunca la encuentras, se queda abierto (no se falla).
- Ningún texto nombra el molino; el mapa no marca sitios que el jugador aún no conoce.
