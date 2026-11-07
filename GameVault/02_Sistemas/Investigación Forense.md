---
tipo: "sistema"
area: "crimen"
estado: "implementado"
codigo: "P2"
tags:
  - "medicina"
  - "crimen"
  - "sistema"
fuente: "Biblia §5.3"
---
# Investigación Forense

> Sección original: *Investigación Forense y Crímenes Complejos (`P2 Forensics`)*

Todas las mecánicas forenses exigen estar cerca o tener acceso real y ninguna opción del diálogo revela quién es el culpable si el jugador no lo ha descubierto antes:

| Código | Mecánica Forense | Cómo Funciona y Contramedidas |
|---|---|---|
| `P2.1` | **Plantar prueba falsa** | Coloca un objeto incriminatorio en casa de un vecino; si alguien te ve, se vuelve en tu contra. |
| `P2.2` | **Comprar coartada falsa** | Un vecino amigo o sobornado declara que estuviste con él a la hora del crimen. |
| `P2.3` | **Intimidar testigo** | Amenaza a quien te vio (tirada de Combate/Agresividad); si falla, te denuncia al instante (`+25` búsqueda). |
| `P2.4` | **Sicario por encargo** | Un vecino con odio extremo y oro contrata a un matón para atacar a su rival de noche. |
| `P2.5` | **Veneno lento y autopsia** | El veneno en comida o bebida actúa al día siguiente; el **Dr. Valen** sólo lo detecta tras examinar el cuerpo en la Morgue. |
| `P2.6` | **Incriminar a un rival** | Desviar las sospechas del expediente policial hacia alguien con móvil creíble. |
| `P2.7` | **Mover/arrastrar cadáver** | Esconder el cuerpo en el río, bosque o alcantarillas antes de que alguien lo vea. |
| `P2.8` | **Confesión ebrio o febril** | Un asesino con culpa alta que bebe en la taberna o delira con fiebre puede soltar una frase incriminatoria **sólo si estás a ≤ 140 px**. |
| `P2.9` | **Chivo expiatorio** | El comisario corrupto o presionado cierra el caso culpando a un forastero o marginado. |
| `P2.10` | **Emboscada nocturna** | Avisar a la guardia para tender una trampa nocturna a un criminal reincidente. |
| `P2.11` | **Fregar sangre con lejía** | Limpiar las manchas de sangre de la escena del crimen (exige **doble confirmación `[E]`** y lejía de la botica). |
| `P2.12` | **Sobornar autopsia** | Pagar al médico (si su honradez lo permite) para que certifique muerte natural. |
| `P2.13` | **Póliza de seguro de vida** | Algunos vecinos firman pólizas (incluidas pólizas inocentes de padres o esposos precavidos, para que ver una póliza nunca destripe un crimen). Si el asegurado muere y el beneficiario la cobra, el pago sale de las [[Arcas Municipales]] y despierta sospechas del Inquisidor. |
| `P2.14` | **Trucar hora de la muerte** | Calentar o enfriar el cuerpo antes de la autopsia para confundir el *rigor mortis* y validar una coartada. |
| `P2.15` | **El «limpiador» nocturno** | Pagar al perista para que haga desaparecer pruebas físicas antes del amanecer. |
| `P2.16` | **Crimen por imitación (*copycat*)** | Un asesino imita el método de otro crimen reciente para que culpen al mismo autor. |
| `P2.17` | **Confesión forzada** | Arrancar una confesión firmada mediante chantaje (con `20%` de riesgo de que se rebele y te delate). |

## Notas de diseño
- **Herramientas del Detective — Bloque D1 (Examen del cuerpo en la escena):** al pulsar `[E]` junto a un cadáver se abre la pantalla de examen (`DetectiveUI`), inspirada en `docs/bocetos/examen_cuerpo.html`. El tiempo del mundo se pausa mientras estás dentro y cada comprobación suma los minutos que cuesta al reloj. Cuenta con fondo cenital 3D en esquema del sitio real donde yace el cuerpo (ocultando vecinos y jugador), silueta anatómica plana de **Mujer** (con pelo tras la cabeza) u **Hombre** según el género de la víctima, 7 zonas (`cabeza`, `cuello`, `torso`, `brazos`, `manos`, `piernas`, `bolsillos`), acciones superficiales (`mirar`, `palpar`, `oler`, `usar lupa` si llevas la Lupa de Latón, `registrar` bolsillos), marcas visuales sobre el cuerpo y tira inferior del **Cuaderno del caso** para fijar las pistas que decidas guardar. Las pruebas internas exigen trasladar el cuerpo a la morgue (`D2`).
- **Herramientas del Detective — Bloque D2 (Autopsia en la morgue):** con el cuerpo en la camilla de la morgue y el médico forense (`Dr. Valen`) disponible, se habilita la pestaña `2 · Autopsia en la morgue` (también accesible desde la camilla del Hospital con `[0]`). Ofrece 4 pruebas por pasos donde una mala decisión deja el resultado `dudoso` o `estropeado`:
  1. **Sangre (`2 / 2` viales de muestra):** elegir de dónde extraerla (`Del corazón` frente a `Del brazo`, que da muestra pobre), elegir reactivo (`Tintura de corteza` frente a `Sal de plata` o `Vinagre de cobre`, que gastan un tubo; si se agotan los dos tubos, la muestra se pierde) y leer la tabla de colores (`verde oscuro`, `pardo`, `morado`, `sin cambio`).
  2. **Cuello (`Garganta y hueso hioides`):** abrir con `Corte lento, por capas` o `Corte rápido` (que rompe el hueso al cortar y arruina la prueba) y examinar el hueso bajo la lámpara.
  3. **Estómago (`Contenido del estómago`):** abrir y vaciar en un cuenco, y elegir entre `Guardarlo en un frasco sellado` para el alquimista o `Tirarlo` (perdiendo la muestra).
  4. **Piel y rigidez (`Lividez y rigor mortis`):** girar el cuerpo para ver si las manchas de lividez indican que fue movido horas después de morir, y doblar codos y rodillas para comprobar la rigidez o si enfriaron el cadáver (`tampered_time`).
  En los pasos con duda se puede pulsar **«Preguntar al Dr. Valen (+5 min)»** a cambio de tiempo, y la **Causa real** se va completando abajo a la izquierda conforme se cierran las pruebas.
- **Herramientas del Detective — Bloque D3 (Escena del crimen):** en la pestaña `3 · Escena del crimen`, el fondo cenital 3D en esquema del lugar queda a oscuras y las pistas del suelo solo son visibles y clicables cuando entran dentro del radio del **farol del jugador** (que sigue al ratón). Las pistas proceden de `VillageForensics` y del estado físico de la escena (surcos de arrastre si movieron el cuerpo, charco de sangre en `blood_puddles` o su ausencia / limpieza con lejía, huellas, barro removido y objetos plantados). A la derecha incluye los **Testigos cercanos** con dos acciones: `Preguntar (10 min)` y `Presionar (puede cerrarse)`, cuyo resultado depende del carácter del testigo (`Orgulloso`/`Agresivo`) y su afinidad contigo.
- **Herramientas del Detective — Bloque D4 (Cuaderno y tablero del caso):** accesible desde la pestaña `4 · Tablero del caso` o en cualquier momento pulsando la tecla **`[N]`** (`[N] Tablero` en la barra superior). Reúne en un tablero de corcho las fichas de los **Sospechosos** (procedentes del expediente policial o del caso guionizado) y todas las pistas que el jugador haya decidido anotar desde `D1`, `D2` y `D3` (nunca se anotan solas). Las fichas se pueden arrastrar libremente por el corcho, unir con **hilo rojo** pulsando una ficha y luego otra, y desconectar haciendo clic sobre un hilo o con el botón «Quitar todos los hilos». Las notas, posiciones de las fichas e hilos rojos se guardan y cargan con la partida en `forensics_state["detective_board"]`.
