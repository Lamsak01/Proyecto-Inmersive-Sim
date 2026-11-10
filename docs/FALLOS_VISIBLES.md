# Fallos visibles (lista del usuario)

> El usuario apunta aquí lo que ve mal al jugar, aunque sea una frase. **Todo agente empieza cada encargo mirando esta
> lista**: arregla primero lo que toque su trabajo y marca lo arreglado con ✅ y la fecha (no lo borres).
> Formato: `- [ ] Qué se ve mal · dónde · cuándo (hora del juego, 2D/3D/primera persona)`.

## Pendientes
- [ ] **(PRIORIDAD 1) Rendimiento terrible**, incluso en el PC de escritorio con gráfica de última generación · 1.ª persona (usuario, 2026-11-09). *(Mejorado 2026-11-09: el cuello de botella era el procesador, no la gráfica: la lógica de los vecinos en cada paso de física y el motor encadenando hasta 8 pasos por fotograma. Portátil: 3–4 → 14–21 fps (rejilla de vecinos y terreno quieto juntado por zonas de 256 px: afueras 8.400 → 5.300 llamadas de dibujo, bosque y molino a la mitad). Después, con la simulación simplificada de vecinos lejanos activada por el usuario: afueras 24, plaza 22, río 19, bosque 36, molino 45, mansión 40 fps. Pendiente: sombras del sol (duplican las llamadas de dibujo) y la geometría junto al río. Sondas: `tools/tests/perf_zonas.gd`, `perf_fisica.gd`.)*
- [ ] **Vecinos atascados por todas partes** desde que se añadió el río nuevo: la IA no sabe rodearlo · pueblo (2026-11-09). *(Mejorado 2026-11-09: se congelaban contra el margen de los edificios y la orilla; ahora se deslizan por el borde y las rutas no rozan ese margen. Sonda `tools/tests/atascos_vecinos.gd`: 9 → 2 atascos en 4 h de juego; quedan huecos muy estrechos entre la herboristería y la pescadería y un recodo de la orilla oeste en y≈-411.)*
- [ ] **El molino está a 2 metros del cuerpo de la víctima**, y el bosque tiene árboles metidos unos dentro de otros · 3D (2026-11-09).
- [ ] **Controles que se pisan** (varias acciones en la misma tecla) · (2026-11-09).
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
