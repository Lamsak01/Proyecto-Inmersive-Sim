# Plan C7 — Rehacer el combate

> Claude Code, 2026-11-06. Queja del usuario: «se siente flojo, sin peso y incompleto; no hay feedback».
> El usuario pidió trabajar en autónomo; este plan es el orden propuesto. Cada fase es un bloque con su prueba.

## Diagnóstico (lo que había)
- Todos los golpes cuerpo a cuerpo duraban lo mismo (0,36 s) fuera cual fuera el arma; el golpe daba al instante.
- **Ningún sonido** en todo el juego (había `swipe.wav`, `hit.wav`, `hurt.wav`, `enemy_die.wav`, `evade.wav` sin usar).
- El que recibía el golpe no reaccionaba: ni empujón (el campo `knockback_force` no lo usaba nadie) ni tambaleo.
- Congelado del impacto y temblor de cámara iguales para todas las armas; al recibir tú un golpe, solo «-X HP».

## Fase 1 — Peso y respuesta ✅ (2026-11-06)
`scripts/systems/combat/CombatFeel.gd` (tabla `WEAPON_FEEL` por arma) y `PlayerCombatController.attack`:
- Cada golpe tiene **preparación → golpe → recuperación**; solo puede dar en el «golpe». Martillo lento y pesado,
  hoz y puños rápidos, espada en medio. El daño, sangrado y aturdimiento de cada arma no cambian.
- **Paso adelante** al soltar el golpe; mientras golpeas **andas más despacio** y la **dirección queda fijada**.
- Al dar: **empujón** (choca con muros), **tambaleo corto** que corta su ataque (sin letrero), **chispa**, **sonido**,
  congelado y temblor según el peso del arma.
- Al recibir: quejido, temblor y pequeño empujón; esquivar y parar también suenan.

## Fase 2 — Los rivales con las mismas reglas ✅ (2026-11-06)
Hecho: `CombatFeel.ATTACK_FEEL` (porra, puño, bandido, colmillos: empujón, recuperación al dar y al fallar, tono);
zumbido del golpe al soltarlo; quietos 0,3 s tras dar y 0,55–0,75 s tras fallar (vecinos, guardias, bandidos, jabalíes
de incursión y salvajes); `DamageData.knockback_force` decide cuánto te empujan; `hit_mass` (jabalí 2,5, venado 1,4,
zorro 0,7, conejo y mascotas 0,5, bandido 1,1) divide el empujón y, por su raíz, el tambaleo que les provocas.
- Guardias, bandidos, animales y vecinos: preparación visible (ya hay aviso de 0,4 s), **recuperación castigable**
  tras fallar, y sus golpes te empujan según su arma (porra, horca, cuchillo, colmillos).
- El tambaleo que les provocas depende de su tamaño (un jabalí apenas se mueve con la hoz).

## Fase 3 — Más opciones en tus manos
**3a ✅ (2026-11-06):** cadena de la espada (pulsar en la recuperación; el 3.º ×1,5 de daño, preparación ×1,8) y golpe
cargado de martillo/hacha (mantener el clic 0,65 s: hasta ×1,7 de daño, empujón y tambaleo largos, +10 de energía;
cargando andas al 55 %). **3b ✅ (2026-11-06):** si mantienes Q tras la parada, guardia alta (pasa el 30 % del golpe,
cuesta 8 + 0,6·daño de energía, 2,5/s; sin energía se rompe; andas al 50 %; no protege de disparos). Empujón con X
(32 px delante, 1 de daño, empuja 26 px/masa y desequilibra 0,6 s, 12 de energía, 0,8 s de espera; cuenta como agresión).
- Espada: **cadena de 3 golpes** si vuelves a pulsar a tiempo (el 3.º más lento y fuerte).
- Martillo y hacha: **golpe cargado** manteniendo el clic (rompe la guardia, tumba).
- **Bloqueo sostenido** con Q gastando energía (la parada perfecta de 0,2 s sigue siendo la mejor).
- **Empujón/patada** para abrir distancia o tirar a alguien por las escaleras.

## Fase 4 — Consecuencias inmersivas ✅ (2026-11-06, salvo testigos)
Hecho: `HealthComponent.hit_region_weights` (animales y jabalíes → piernas ×3, cabeza ×0,15; por la espalda → torso ×1,5,
cabeza ×1,3, brazos ×0,5 y la herida lo dice; por un costado → brazo y pierna de ese lado ×1,8; en el suelo → cabeza ×2,5).
`WeaponWear.gd`: estado 0–100 por arma del jugador (guardado), −0,5 por golpe a seres vivos, −0,25 herramienta en su
trabajo, −1,2 espada contra madera/piedra; por debajo de 60 pega, corta y tala menos (hasta ×0,65); el herrero lo deja
nuevo por 1 de oro cada 8 puntos. Desarmar: un golpe fuerte (3.º de cadena o cargado) que acaba en el brazo de un guardia
o bandido le quita el arma 20 s (guardia: sin pistola y a puñetazos; bandido: la mitad de daño).
Falta: testigos que reaccionan al ruido del combate (se deja para el bloque de crimen interno).
- La zona herida depende de la dirección y la altura del golpe (por detrás, en las piernas…), usando la anatomía que ya existe.
- Armas que se **mellan** con el uso y se arreglan en la herrería; **desarmar** con un golpe fuerte a la mano.
- Testigos que reaccionan al ruido del combate (ya existe el ruido con `AudioManager.emit_noise`).

## Pendiente de arte
- Animación 3D de preparación propia (hoy el muñeco usa la misma curva de golpe, estirada a la nueva duración).
- Sonidos distintos por arma y por material (hoy uno para todos, con el tono cambiado según el peso).
