# Fallos visibles (lista del usuario)

> El usuario apunta aquí lo que ve mal al jugar, aunque sea una frase. **Todo agente empieza cada encargo mirando esta
> lista**: arregla primero lo que toque su trabajo y marca lo arreglado con ✅ y la fecha (no lo borres).
> Formato: `- [ ] Qué se ve mal · dónde · cuándo (hora del juego, 2D/3D/primera persona)`.

## Pendientes
- [ ] *(No prioritario, más adelante)* **Cuartos de la posada sin puertas ni muebles** y **camas demasiado pequeñas** · 18:54
  (`docs/capturas_usuario/2026-11-08/4_cuartos_sin_puertas.png`).
- [x] ✅ (2026-11-09) **El campamento inicial está en medio del pueblo** (tienda, hoguera y tronco pegados a las casas); las texturas
  se aprietan entre sí · 1.ª persona, de noche. *(Retirado el campamento y huerto del pueblo en modo demo; el jugador empieza en las afueras, en el camino de entrada al valle `Vector2(-920, 50)`, con la pantalla de la carta de contratación al inicio).*
- [ ] **Todo está demasiado comprimido** (petición grande del usuario): pueblo, campamento, lago, bosque y llanura
  están pegados. Quiere **un mapa unas 3 veces más grande**, con todo más separado y más largo (ver `ENCARGO_SIGUIENTE.md`).
- [ ] **El bosque parece un parque:** demasiado cerca del pueblo, poca vegetación, y su borde (dónde empieza y acaba)
  es recto y mecánico; saca de la inmersión · 3D, de día.
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
