# Siguiente encargo (cola)

> Claude Code, 2026-11-07. Lanzar cuando Antigravity termine la tanda de arreglos de la segunda ronda del usuario
> (los pendientes de hoy en `docs/FALLOS_VISIBLES.md`). Luego pasa a `docs/ENCARGO_ANTIGRAVITY.md`.

## 1. Modo pruebas del jugador (APROBADO por el usuario, 2026-11-07)
El usuario prueba el juego matando con sigilo y recorriendo todo; quiere no morir ni quedarse sin recursos.
- Una tecla libre (dila en el informe) lo activa y desactiva. Empieza **desactivado** y **no se guarda** en la partida.
- Activo: no pierde vida; energía infinita; hambre y sueño no bajan; el oro no baja al gastar (empieza con 9999).
- Aviso visible fijo «MODO PRUEBAS» en pantalla mientras esté activo.
- Los vecinos reaccionan igual que siempre (testigos, denuncias, persecuciones): no los toca.
- Aviso del supervisor: el oro infinito rompe la suma cero de la economía; es solo para pruebas.
- Una prueba corta que lo compruebe (activar, recibir daño, gastar, desactivar). Arranque sin errores; súbelo.

## 2. Interfaz nueva en partida (APROBADA por el usuario, 2026-11-07: «me gusta todo»)
**Referencia obligatoria:** `docs/bocetos/interfaz_juego.html` (ábrelo en el navegador y cópialo lo más fiel posible:
colores, tipografías parecidas, papel y tinta como el examen forense). Resumen: barras de vida/energía arriba a la
izquierda (hambre y sueño solo cuando bajan); reloj pequeño en placa arriba al centro (velocidad solo si no es 1x);
mapa redondo de papel arriba a la derecha; avisos breves a la izquierda (máx. 3, se desvanecen, borde rojo los graves);
tarjeta de papel abajo al centro con nombre, estado y acciones (rueda o G); objetos en mano abajo a la izquierda; oro
abajo a la derecha; la barra de teclas actual pasa a una ayuda con [H]; aviso «MODO PRUEBAS» bajo el reloj.
- Hoy la barra superior está corrida a la derecha: empieza a mitad de pantalla, se mete debajo del minimapa y corta
  texto («[▶ ×1]», «2D», la lista de teclas). En la nueva, nada se corta ni se solapa en 1280×720, 1920×1080 y 2560×1440.
Además, lo de abajo:
Fallo en `FALLOS_VISIBLES.md` (captura de la plaza con 4 cadáveres: 10+ líneas apiladas e ilegibles).
- Solo la cosa que miras/tienes más cerca muestra letrero, y corto («Garrick · muerto»). El resto, solo un icono.
- Las acciones (saquear, reportar, examinar, precios) solo abajo, en el aviso de [E] con «1/6 · Mayús+rueda o G».
- Barras de trabajo y bocadillos: que nunca se monten; si hay varios cerca, se apartan o se ocultan los lejanos.
- Capturas antes y después en 2D y 3D de la plaza con varios vecinos y cadáveres.

## 3. Relieve del terreno (APROBADO por el usuario, 2026-11-07: antes de los edificios)
El terreno es perfectamente plano. Hacerlo **antes** de los edificios de los bocetos, en este orden y con parada para
capturas entre fases:
- **Fase A (fuera del pueblo):** lomas en la llanura, desniveles en el bosque, orillas del lago y de la ciénaga más bajas
  que el terreno. **Corregido por el usuario (2026-11-07): el relieve fuerte NO vale; lomas bajas y anchas, pendientes
  suaves (≤ ~15°), caminos y edificios en llano.**
- **⚠️ Antes de la Fase B:** rehaz la Fase A según «PRIORIDAD — el relieve de la Fase A no vale así» y arregla la
  taberna («atraviesan el suelo y nadie se sienta»), ambas en `FALLOS_VISIBLES.md`, y para para que el usuario lo vea.
  Luego arregla, sin rehacer nada más, la entrada «Partida del usuario tras la interfaz nueva» de
  `FALLOS_VISIBLES.md` (mapa grande, aviso [E] doble, ayuda sobre el reloj, puerta de la taberna comprobada viendo a
  varios vecinos entrar y salir, tira roja, pescador fuera del lago).
- **Fase B (pueblo):** solo desniveles suaves (calles que suben un poco, una plaza algo más alta, escalones o rampas
  donde haga falta). Los edificios se asientan en llano (plataforma o zócalo), nunca inclinados ni flotando.
- Vecinos, animales, carros, caravanas y el jugador deben andar por las cuestas sin atascarse; nada flota ni se hunde
  (árboles, muebles, cadáveres, objetos tirados). El 2D se ignora (decisión del usuario: solo 3D).
- Tras cada fase: unas pocas capturas 3D (1.ª persona) de los sitios con relieve, mirarlas; comprobar que el juego arranca y pasar
  verify_all con timeout 900. Si algo se atasca, arreglarlo antes de seguir.

## 4. Edificios de los bocetos (`docs/BOCETOS_EDIFICIOS.md`)
Esperan las correcciones del usuario. Después, construirlos todos seguidos con capturas de cada uno.
