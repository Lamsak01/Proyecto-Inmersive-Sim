# Fallos visibles (lista del usuario)

> El usuario apunta aquí lo que ve mal al jugar, aunque sea una frase. **Todo agente empieza cada encargo mirando esta
> lista**: arregla primero lo que toque su trabajo y marca lo arreglado con ✅ y la fecha (no lo borres).
> Formato: `- [ ] Qué se ve mal · dónde · cuándo (hora del juego, 2D/3D/primera persona)`.

## Pendientes
- [ ] **(PRIORIDAD 1) Rendimiento terrible**, incluso en el PC de escritorio con gráfica de última generación · 1.ª persona (usuario, 2026-11-09). *(Mejorado 2026-11-09: el cuello de botella era el procesador, no la gráfica: la lógica de los vecinos en cada paso de física y el motor encadenando hasta 8 pasos por fotograma. Portátil: 3–4 → 14–21 fps (rejilla de vecinos y terreno quieto juntado por zonas de 256 px: afueras 8.400 → 5.300 llamadas de dibujo, bosque y molino a la mitad). Después, con la simulación simplificada de vecinos lejanos activada por el usuario: afueras 24, plaza 22, río 19, bosque 36, molino 45, mansión 40 fps. Pendiente: sombras del sol (duplican las llamadas de dibujo) y la geometría junto al río. Sondas: `tools/tests/perf_zonas.gd`, `perf_fisica.gd`.)* *(Mejorado 2026-11-10, portátil: el pueblo 2D seguía dibujándose detrás de la 1.ª persona a resolución de pantalla (~15 ms); vecinos a media distancia piensan 1 de cada 2 pasos; objetos pequeños lejanos no se dibujan. Afueras 27→33, plaza 22→29, río 18→23, bosque 27→38, molino 32→40, mansión 35→43 fps. Sombras, nitidez y suavizado ya se pueden bajar en Ajustes (sin sombras: −4 ms). Sondas nuevas: `perf_ventana.gd`, `perf_alcance.gd`, `perf_proceso.gd`.)*
- [ ] **Vecinos atascados por todas partes** desde que se añadió el río nuevo: la IA no sabe rodearlo · pueblo (2026-11-09). *(Mejorado 2026-11-09: se congelaban contra el margen de los edificios y la orilla; ahora se deslizan por el borde y las rutas no rozan ese margen. Sonda `tools/tests/atascos_vecinos.gd`: 9 → 2 atascos en 4 h de juego; quedan huecos muy estrechos entre la herboristería y la pescadería y un recodo de la orilla oeste en y≈-411.)*
- [ ] **El molino está a 2 metros del cuerpo de la víctima**, y el bosque tiene árboles metidos unos dentro de otros · 3D (2026-11-09).
- [x] ✅ (2026-11-10) **Setas y plantas del bosque sin modelo 3D:** las setas (y hierbas) que se recogen se ven como dibujos 2D planos dentro del mundo 3D; faltan modelos 3D para ellas y para las plantas del bosque · 1.ª persona y 3D (usuario, 2026-11-09). *(Setas de Kenney Nature Kit; hierbas, helechos, hierba, tocones y troncos con musgo del mismo pack Quaternius que los árboles. Créditos en `docs/CREDITOS_RECURSOS.md`.)*
- [x] ✅ (2026-11-09) **Árboles, arbustos, troncos y setas dentro del río** al redibujarlo en el editor del mapa · ya no se colocan en el agua; el tronco caído del bosque del sur es ahora un puente natural por el que se camina.
- [x] ✅ (2026-11-10) **Controles que se pisan** (varias acciones en la misma tecla) · (2026-11-09). *(Plan aprobado por el usuario: los trucos de tiempo y el modo pruebas piden Ctrl (Ctrl+T, Ctrl+F1–F4, Ctrl+F7, Ctrl+º) y no salen en la ayuda; + y − solo hacen zoom; fuera F6, F8 y F10 repetidas. Ver `docs/CONTROLES.md`.)*
- [ ] **El Caso I empieza a la vez que llega el jugador**: no hay tiempo para entender qué pasa ni adónde ir · inicio de la demo (2026-11-09).
- [x] ✅ (2026-11-09) **El día pasaba demasiado deprisa** · ahora un día de juego dura 18 min reales (antes 6).
- [ ] *(No prioritario, más adelante)* **Cuartos de la posada sin puertas ni muebles** y **camas demasiado pequeñas** · 18:54
  (`docs/capturas_usuario/2026-11-08/4_cuartos_sin_puertas.png`).
- [x] ✅ (2026-11-09) **El campamento inicial está en medio del pueblo** (tienda, hoguera y tronco pegados a las casas); las texturas
  se aprietan entre sí · 1.ª persona, de noche. *(Retirado el campamento y huerto del pueblo en modo demo; el jugador empieza en las afueras, en el camino de entrada al valle `Vector2(-920, 50)`, con la pantalla de la carta de contratación al inicio).*
- [ ] **Todo está demasiado comprimido** (petición grande del usuario): pueblo, campamento, lago, bosque y llanura
  están pegados. Quiere **un mapa unas 3 veces más grande**, con todo más separado y más largo (ver `ENCARGO_SIGUIENTE.md`).
- [x] ✅ (2026-11-09) **El bosque parece un parque:** demasiado cerca del pueblo, poca vegetación, y su borde (dónde empieza y acaba)
  es recto y mecánico; saca de la inmersión · 3D, de día. *(Añadido bosque denso y oscuro de pinos, sauces y robles con borde irregular, penumbra bajo las copas y sotobosque espeso de arbustos, zarzas, helechos, musgo y troncos caídos alrededor del arroyo y el claro del cuerpo en `WorldStageTerrain3D.gd`).*
- [ ] **Los animales solo rondan sus nidos/madrigueras** y siempre van todos juntos; no hacen nada más · bosque.
- [ ] **Enemigos todavía en 2D** (los sapos de la Llanura Salvaje) · de día. **Petición:** mantener los sapos, pero con **modelo 3D basado en su
  sprite** (mismo diseño: sapo verde de pie con ropa roja). *(✅ 2026-11-07: ocultados por defecto los conos de visión de depuración en `VisionCone2D.gd` y `DummyEnemy.gd`)*.
- [ ] **Los edificios antiguos son diminutos y feos:** cuartos de una sala, muebles arrinconados, sprites sin sentido
  (p. ej. la comisaría: rejas verdes gigantes, cajón suelto, cepo). **Petición del usuario:** que TODOS los edificios
  tengan el nivel de detalle de la trattoria (varias salas con sentido, muebles 3D colocados, luces). Es un proyecto
  grande: hacerlo edificio a edificio, empezando por los que pisa el detective (comisaría, morgue/hospital, capilla,
  taberna, biblioteca). *(✅ 2026-11-08: rehechos en 3D y 1.ª persona los 6 edificios del Caso I — comisaría y calabozo, morgue/hospital, taberna, biblioteca, botica del alquimista y capilla — con salas separadas coherentes, mobiliario 3D sin solapes ni objetos flotantes, iluminación interior y techos sin Z-fighting; capturas antes/después en `docs/capturas_arreglos/interiores/`)*.
- [ ] **Todas las casas comparten la misma puerta**, que a veces no pega con la fachada · 1.ª persona. *(✅ 2026-11-08: puertas 3D propias en los edificios del Caso I rehechas en madera oscura gastada y hierro oxidado acorde a la época tecnofeudal, con una pequeña cruz pintada desvaída en el hospital y sin carteles ni colores chillones; alfombras gastadas sin franjas amarillas en biblioteca, botica y capilla)*.
- [ ] **Alcantarillas vacías** (2026-11-07): son un pasillo con 3 cofres sueltos; no se ve el sitio de las peleas clandestinas que se supone que está ahí.
- [ ] **(BAJA PRIORIDAD: el usuario lo tolera por ahora) Césped con dibujo repetido** (2026-11-07 21:13, captura, 3D):
  la cuadrícula pasó a ser un dibujo de rombos que se repite por todo el suelo; no es natural y no le gusta. Arreglarlo
  más adelante con una hierba sin patrón visible (manchas irregulares, variación de tono).

> Los arreglados están en `docs/FALLOS_ARREGLADOS.md` (no hace falta leerlos). Al arreglar uno, márcalo con ✅ aquí; el supervisor lo archiva.

## 2026-11-10 — Partida del Caso I: el jugador no llega al claro (detectado por Claude Code)
- `tools/tests/partida_caso1.gd` pasa de 25/25 (2026-11-09) a 7/25. El paseo al claro se queda en (213, -796) y todo lo
  que va detrás falla. Pasa igual sin los cambios del plan de sitios: viene de los cambios del mapa (río redibujado,
  árboles y troncos sólidos del editor 3D). Mirar qué tapa el camino al claro.

## ✅ (2026-11-10, arreglado) Atasco en la plaza cerca de (399, 100) (detectado por Claude Code)
- En `atascos_vecinos.gd`, Dr. Valen, Elena o Aldric se quedan trabados unos segundos en un paso estrecho de la plaza
  cerca de (399, 100), y otros en los cruces del río (Wolfgang, Albrecht en (185, -255) y (44, -448)). Salen o no
  según la velocidad del ordenador, porque la elección de asiento usa el reloj real. Ya pasaba antes del plan de sitios.
  Mirar qué estrecha ese paso (pozo de la plaza, bancos o algo pintado con el editor).
- **Arreglado (2026-11-10):**
  - **Hueco estrecho:** entre la herboristería y la pescadería quedan 18 px, y 20 px entre el albergue y el
    hojalatero. Ahí no cabe un vecino, por el margen de 9,5 px que frena junto a cada muro. Ahora las rutas tratan como
    una sola manzana los edificios separados menos de 24 px (antes, menos de 18 px) y la rodean.
  - **Río:** antes de la pasarela del norte, el río hace una curva. Quien iba hacia la pasarela cortaba en línea recta
    por el agua; ahora sigue la orilla.
  - **Prueba repetible:** el asiento de la taberna y del restaurante se elige con la hora del juego, no con el reloj
    real, así que la misma prueba da el mismo resultado.
  - **Medida** (`atascos_vecinos.gd -- 6`): de 1–5 atascos a 0, sin errores.

