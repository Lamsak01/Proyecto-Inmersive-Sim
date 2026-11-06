---
tipo: "sistema"
area: "mundo"
estado: "implementado"
codigo: "PM.1-PM.2"
tags:
  - "mecanica"
  - "mundo"
  - "sistema"
fuente: "Biblia §9.5"
---
# Caballos y Expediciones

> Sección original: *Caballos, Carretas y Expediciones Arqueológicas (`PM.1–PM.2`)*

- **Caballo de Silla (`PM.1`, rehecho el 2026-11-05):** Al comprarlo aparece de verdad junto al ganadero del Rancho del Sur (modelo 3D animado; en 2D un dibujo provisional). Con **E** a su lado montas y con **E** otra vez desmontas; se queda donde lo dejas. Solo montado vas un **45 % más rápido** y no puedes ir en sigilo. Bajas solo al entrar en un edificio, acostarte o si te escolta la guardia. Se guarda dónde está y si ibas montado. Sigue dando +15 % en las expediciones.
- **Carreta de Carga (`PM.1`, hecha física en `P2`, 2026-11-06):** Al comprarla al ganadero (`55 de oro`), aparece aparcada en el Rancho del Sur junto al caballo (`Vector2(385, 470)`, modelo 3D `fantasy_town/cart.glb` y dibujo 2D provisional con F10). Con **E** a pie tiras de ella a mano (velocidad `×0,55`, sin correr, sin sigilo y sin rodar) y con **E** montado a caballo la enganchas al caballo (velocidad del caballo `×0,80`, sin sigilo); sigue tu rastro a `22 px` por detrás sin cortar esquinas. Con la carreta parada, un segundo letrero de **E** abre su **caja de carga (hasta 40 unidades**, sin oro). Si pasa la noche aparcada lejos de tus solares construidos (`≥ 90 px`) y fuera del corral del rancho con carga dentro, hay un `12 %` de robo nocturno por el vecino más pobre (se lleva la mitad hacia abajo, máx. 10 objetos a su bolsillo; suma cero y testigo en `160 px`). El bono de `+4 de oro` al enviar una remesa comercial solo se aplica si llevas la carreta a menos de `60 px`.
- **Expediciones Fuera del Valle (`PM.2`):** Viajes organizados con provisiones hacia tres enclaves antiguos: **Ruinas de Cobre**, **Grutas de Cristal** y **Atalaya Hundida**, donde se hallan reliquias tecnológicas, mineral raro o peligros físicos.

## Notas de diseño
- 2026-11-05 (Claude Code): pedido del usuario (Regla «todo es físico»): el caballo deja de ser un aumento de velocidad invisible. El jinete usa la postura de sentado en silla (piernas hacia delante): aceptable desde arriba, no perfecto.
- 2026-11-06 (Antigravity, Bloque P2): la carreta de carga pasa a existir en el mapa (`PlayerCart.gd`, grupo `player_cart`): se arrastra a mano (`×0,55`) o enganchada al caballo (`×0,80`) siguiendo el rastro a 22 px, lleva caja de carga de 40 unidades con ventana de dos listas (`Meter 1`, `Meter todo`, `Sacar 1`), corre riesgo de robo nocturno (`12 %`) si duerme aparcada fuera de lugar seguro (pasando lo robado al bolsillo del vecino más pobre) y solo da el bono de `+4 de oro` en `send_player_shipment` si está a menos de 60 px del jugador.
