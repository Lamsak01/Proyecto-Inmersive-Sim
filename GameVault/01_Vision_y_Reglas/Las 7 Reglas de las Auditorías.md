---
tipo: "vision"
area: "reglas"
estado: "definido"
tags:
  - "auditoria"
  - "leccion-auditoria"
  - "reglas"
fuente: "Biblia §14"
---
# Las 7 Reglas de las Auditorías

A lo largo del proyecto se realizaron tres grandes auditorías técnicas y de diseño (`AUDIT_LOG.md`, `AUDITORIA_P1_P7.md` y `AUDITORIA_PF_PQ.md` + `AUDITORIA_PROYECTO_COMPLETA.md`). Estas son las **7 leyes aprendidas** que deben respetarse en cualquier desarrollo futuro:

> [!tip] Las 7 Reglas de Oro de las Auditorías
> 1. **Prohibido el oro mágico («Suma Cero»):** Ninguna acción (apostar, vender en el bazar, cobrar protección, heredar, cobrar un seguro, dar un golpe o encontrar un alijo) puede crear oro de la nada. Siempre debe descontarse del bolsillo de un vecino, de la caja de un taller (`vault_gold`) o de las [[Arcas Municipales]] (`treasury`).
> 2. **Ningún menú puede destripar un secreto:** Las opciones del diálogo sólo pueden mostrar nombres o acusaciones si el jugador ya figura en `known_by` de ese secreto. Y si existe un objeto o contrato que pueda servir de móvil criminal (como las **pólizas de seguro de vida** en `P2.13`), también deben existir casos inocentes para que ver el objeto no revele automáticamente al asesino.
> 3. **Todo reto se puede perder y tiene espera (cooldown):** Dar un mitin, pedir una deuda de honor, falsificar escrituras, forzar una confesión, fingir un milagro o mandar carteristas nunca puede tener éxito automático. Debe usar una tirada basada en habilidades/rasgos, tener consecuencias reales si sale mal y exigir esperar al día siguiente o una semana antes de reintentarlo.
> 4. **Las acciones de riesgo ocurren en el mundo físico y con testigos, no desde un menú:** Robar una carta de amantes, colocar veneno, sabotear la red eléctrica o ejecutar un golpe exige estar físicamente cerca (`<= 110 px`) y comprueba si hay testigos conscientes con línea de visión en la misma planta. Tampoco se permite disparar ni robar desde una opción de diálogo.
> 5. **Las capas verticales no son un manto de invisibilidad:** Cambiar al piso `+1` o al sótano `-1` sólo se permite dentro de casa (`<= 90 px` de tu solar) y vuelve automáticamente al nivel `0` al alejarte `70 px` de la escalera.
> 6. **El pueblo debe hacer uso autónomo de las mecánicas sin esperar al jugador:** De nada sirve programar maestros artesanos, escuela, rancho o tecnologías si ningún vecino compra obras maestras, ningún niño va a clase o las arcas acumulan mil monedas sin gastarlas. Toda mecánica nueva debe probarse con la **sonda autónoma (`feature_probe.gd`)** dejando correr el pueblo solo durante 15–30 días.
> 7. **Los tests deben probar el flujo real (con testigos, esperas y fallos), no sólo datos forzados:** Un test que inyecta diccionarios a mano y fuerza la semilla ganadora oculta los errores de jugabilidad real.
