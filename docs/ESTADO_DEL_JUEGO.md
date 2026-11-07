# Estado del juego — resumen para Antigravity (Claude Code, 2026-11-07)

> Léelo antes de cualquier encargo nuevo. Si esto y `git` no coinciden, manda `git`. Detalle técnico en `docs/HANDOFF.md` §7–8.

## 1. Qué es el juego (decidido)
- Immersive sim 2D en pixel art con vista 3D opcional (Godot 4.7.2). Un forastero llega a un pueblo de ~40 vecinos que
  viven solos: oficios, casas, amistades, rencores, secretos, chismes, crimen y justicia.
- **Bucle principal decidido por el usuario (2026-11-07): DETECTIVE.** Llega un caso → investigas (cuerpo, escena,
  pistas en el mundo, testigos, chismes) → acusas → el pueblo cambia según aciertes o falles → otro caso.
  La Familia (crimen) y echar raíces (casa, negocio) son caminos **secundarios** que alimentan los casos.
- **Problema reconocido por el usuario:** «demasiados sistemas y ningún loop jugable». Regla nueva: lo que no sirva a
  los casos, espera. Nada de sistemas aislados ni de menús.
- Primer caso (beta): **«La mujer del bosque»**, trama del usuario en `docs/PLAN_BETA_MISTERIO.md` §5 (cadena fija de
  pistas, reparto procedural de papeles entre vecinos reales). Huecos sin cerrar en ese documento: no los inventes sin
  preguntar al usuario.

## 2. Lo hecho recientemente (todo en `main`)
- **Combate C7 completo:** peso por arma, sonidos, rivales con las mismas reglas, cadena de espada, golpe cargado,
  guardia alta (Q), empujón (X), zonas heridas por dirección, armas melladas (el herrero arregla), desarmar, ruido y
  testigos (B1). Espacio solo rueda. **Al usuario el combate le sigue sin gustar** → prueba de primera persona.
- **Primera persona (B7, prototipo):** P o F6 (F9 = 3D/2D; F5 guardar, F12 cargar). Pendiente de que el usuario opine.
- **Trattoria «Il Corvo» (R1–R1b):** restaurante de 6 salas con terraza; vecinos comen y cenan; cocinero y cámara fría.
- **La Familia (R2–R4):** Don Vittorio Corvo manda desde el día 0 (orden del usuario); recluta, reuniones nocturnas en
  el reservado, protección, préstamos, sobornos; el jugador escucha, avisa, trabaja para ellos o los delata (B2: el
  jefe acaba en el calabozo).
- **Cohesión física (B2–B6):** calabozo real con fianza y fuga; mudar a Toby y animales al solar propio; niebla que
  recorta la vista salvo con luz; humo en talleres saboteados; paseos nocturnos; gestos de desprecio entre enemigos;
  merodeo antes de un crimen; bocadillos de hitos; 21 fundadores con rasgos, relaciones y secretos (notas en
  `GameVault/04_Censo_y_Misiones/Vecinos/`).
- Recién llegados repartidos por barrios, talleres vacantes y jornales; parados pasean por sitios variados.
- Enciclopedia HTML del vault: `tools/export_vault_html.py` (dos versiones en `/home/lamsaktp/`).

## 3. En pausa o descartado
- **Asaltos** de bandidos y jabalíes: en pausa (`RAIDS_ENABLED = false`). El crimen es interno y discreto.
- **Rendimiento** y **compra de arte**: aparcados. **Exportar/compartir** con amigos: no hasta tener el caso largo.
- **Pruebas:** no las pases a mitad de trabajo. Solo al final de un encargo largo, una a una y **siempre con `timeout`**
  (verify_all 900 s, social_sim 900, dialogue_coverage 600, feature_probe 1200). EXIT 124 = colgada por un assert.

## 4. Pendiente (orden sugerido; el usuario decide)
1. **El caso «La mujer del bosque»** jugable de principio a fin: arranque de partida que lo prepara, pistas físicas en
   el mundo, cuaderno del detective en el registro de misiones (J), acusación clara, pantalla de final con resumen.
2. Opinión del usuario sobre la primera persona → decidir si se adopta (si sí: interacción, apuntado, interiores).
3. Delatar a la Familia → juicio público al jefe y reacción de los miembros (parte hecha en B2; revisar).
4. Fachada de la trattoria en 3D (parece de tablas oscuras). Arcabuz usable en combate.

## 5. Reglas que no cambian
- No tocar `scripts/systems/VillageSect.gd`, `GameVault/03_La_Secta/`, el Lore provisional, `GameVault/99_Archivo/`,
  `GameVault/.obsidian/`, `.claude/`. La secta y el trasfondo son del usuario.
- Las 7 Reglas de las Auditorías (suma cero, no destripar en menús, todo puede fallar y tiene espera, cercanía y
  testigos con línea de visión). Nada rígido: sin temporizadores ni sucesos «porque sí».
- Peleas raras y orgánicas: una partida sin peleas es válida.
- Al usuario: español, breve, sin código ni nombres de archivos, una pregunta al final.
- Al cerrar cada bloque: HANDOFF §7, CHANGELOG, REGISTRO_TRABAJO, nota del vault, Tablero, diario, APORTES_CREATIVOS,
  commit y push a `main`, informe en `docs/INFORME_ANTIGRAVITY.md`.
